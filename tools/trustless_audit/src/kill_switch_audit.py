"""
kill_switch_audit.py — Kill switch and circuit breaker ECDSA audit records

Records kill switch enable/disable and circuit breaker trip/reset events
in the approvals.log audit trail with ECDSA P-256 signatures.

This makes the kill switch history tamper-evident: stop/trip events are
hash-chained identically to any other governance decision. Re-signing
every subsequent entry would require the offline private key.

Usage (CLI, called from kill-switch.sh):
    python kill_switch_audit.py \\
        --action kill_switch_enable \\
        --reason "Security incident INC-015" \\
        --operator "human_approver_001"

    python kill_switch_audit.py \\
        --action circuit_breaker_trip \\
        --reason "5 blocks in 10m window" \\
        --operator "circuit_breaker"

Actions:
    kill_switch_enable        Human or automated kill switch activation
    kill_switch_disable       Human-authorized deactivation
    circuit_breaker_trip      Automatic trip by block count threshold
    circuit_breaker_reset     Manual reset after circuit breaker trip
"""

import argparse
import hashlib
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

# ── Paths ─────────────────────────────────────────────────────────────────────

_SRC_DIR = Path(__file__).parent
KEYS_DIR = _SRC_DIR.parent / "keys"
REPO_ROOT = _SRC_DIR.parent.parent.parent.parent
APPROVALS_LOG = REPO_ROOT / "tools" / "itil5-ai-governance" / "approvals.log"

# ── Signing import (optional — graceful degradation) ─────────────────────────

try:
    from .signing import sign_operation_log

    _SIGNING_AVAILABLE = True
except ImportError:
    try:
        sys.path.insert(0, str(_SRC_DIR))
        from signing import sign_operation_log  # type: ignore

        _SIGNING_AVAILABLE = True
    except ImportError:
        _SIGNING_AVAILABLE = False


# ── Ephemeral key generation (fallback when no persistent key exists) ─────────

def _generate_ephemeral_key_pem() -> bytes:
    """Generate an ephemeral ECDSA P-256 key pair, return private PEM bytes."""
    try:
        from cryptography.hazmat.primitives.asymmetric import ec
        from cryptography.hazmat.primitives import serialization

        private_key = ec.generate_private_key(ec.SECP256R1())
        return private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption(),
        )
    except ImportError:
        return b""


def _load_private_key_pem(role: str = "human") -> bytes:
    """
    Load private key PEM bytes.

    Priority:
    1. {KEYS_DIR}/{role}_private_key.pem  (persistent — preferred)
    2. Ephemeral generated key            (fallback; signature valid but not persistent)

    Ephemeral keys are noted in the log entry so verifiers know the signature
    cannot be verified against a stored public key.
    """
    key_path = KEYS_DIR / f"{role}_private_key.pem"
    if key_path.exists():
        return key_path.read_bytes()
    return _generate_ephemeral_key_pem()


# ── Core record function ──────────────────────────────────────────────────────

def record_kill_switch_event(
    action: str,
    reason: str,
    operator: str,
    *,
    log_path: Path | None = None,
) -> dict:
    """
    Record a kill switch or circuit breaker event in the audit trail.

    The entry is ECDSA-signed if the cryptography library is available.
    If no persistent key exists, an ephemeral key is used and the entry
    notes that the signature is ephemeral (cannot be verified later).

    Args:
        action:   One of: kill_switch_enable, kill_switch_disable,
                  circuit_breaker_trip, circuit_breaker_reset
        reason:   Human-readable explanation
        operator: Who triggered the event (user ID or "circuit_breaker")
        log_path: Override audit log path (default: approvals.log)

    Returns:
        The signed (or unsigned) log entry dict appended to the log.
    """
    valid_actions = {
        "kill_switch_enable",
        "kill_switch_disable",
        "circuit_breaker_trip",
        "circuit_breaker_reset",
    }
    if action not in valid_actions:
        raise ValueError(f"action must be one of {valid_actions}, got {action!r}")

    operator_type = "HUMAN" if action in (
        "kill_switch_enable", "kill_switch_disable", "circuit_breaker_reset"
    ) else "SYSTEM"

    entry: dict = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "operator_id": operator,
        "operator_type": operator_type,
        "action": action,
        "reason": reason,
        "component": "kill_switch",
    }

    # Try ECDSA signing
    if _SIGNING_AVAILABLE:
        # Determine key role: circuit_breaker uses "ai" key; humans use "human" key
        role = "ai" if operator == "circuit_breaker" else "human"
        private_key_pem = _load_private_key_pem(role)

        if private_key_pem:
            ephemeral = not (KEYS_DIR / f"{role}_private_key.pem").exists()
            if ephemeral:
                entry["signing_note"] = "ephemeral_key_no_persistent_keypair"
            entry = sign_operation_log(entry, private_key_pem)
        else:
            entry["signing_note"] = "cryptography_library_unavailable"
    else:
        entry["signing_note"] = "cryptography_library_unavailable"

    # Append to log
    target_log = Path(log_path) if log_path else APPROVALS_LOG
    target_log.parent.mkdir(parents=True, exist_ok=True)
    with open(target_log, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, separators=(",", ":")) + "\n")

    return entry


# ── CLI entry point ───────────────────────────────────────────────────────────

def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Record kill switch / circuit breaker event in audit log"
    )
    p.add_argument(
        "--action",
        required=True,
        choices=[
            "kill_switch_enable",
            "kill_switch_disable",
            "circuit_breaker_trip",
            "circuit_breaker_reset",
        ],
    )
    p.add_argument("--reason", default="unspecified")
    p.add_argument("--operator", default="unknown")
    p.add_argument("--log-path", default=None, help="Override audit log path")
    return p.parse_args()


if __name__ == "__main__":
    args = _parse_args()
    entry = record_kill_switch_event(
        action=args.action,
        reason=args.reason,
        operator=args.operator,
        log_path=args.log_path,
    )
    # Print summary to stderr so kill-switch.sh can capture stdout separately
    signing_status = "signed" if "signature" in entry else "unsigned"
    note = entry.get("signing_note", "")
    print(
        f"[kill_switch_audit] {entry['action']} recorded "
        f"({signing_status}{'; ' + note if note else ''})",
        file=sys.stderr,
    )
