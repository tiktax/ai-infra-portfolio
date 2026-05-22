"""
audit.py — Audit report with ECDSA tamper detection

Handles two log formats:
1. Pre-signing era: approvals.log entries with sha256 hash only (no ECDSA signature)
   -> reported as pre_signing_entries, not flagged as tampered
2. Post-signing era: entries with 'signature' field
   -> ECDSA verified against ai_public_key.pem and human_public_key.pem
"""

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from .signing import verify_signature, identify_operator_type

REPO_ROOT = Path(__file__).parent.parent.parent.parent
APPROVALS_LOG = REPO_ROOT / "tools" / "itil5-ai-governance" / "approvals.log"
KEYS_DIR = Path(__file__).parent.parent / "keys"


def _load_public_key_pem(role: str) -> Optional[bytes]:
    key_path = KEYS_DIR / f"{role}_public_key.pem"
    if key_path.exists():
        return key_path.read_bytes()
    return None


def audit_report(start_date: str, end_date: str) -> dict:
    """
    Generate audit report for the given date range.

    Args:
        start_date: ISO date string, e.g. '2026-01-01'
        end_date:   ISO date string, e.g. '2026-12-31'

    Returns:
        {
            total_operations: int,
            human_ops: int,
            ai_ops: int,
            unknown_ops: int,
            pre_signing_entries: int,     # sha256-only (legacy, not flagged)
            tampering_detected: bool,
            flagged_entries: list[dict],  # entries that failed ECDSA verification
            date_range: {start, end},
        }
    """
    start = datetime.fromisoformat(start_date).replace(tzinfo=timezone.utc)
    end = datetime.fromisoformat(end_date).replace(hour=23, minute=59, second=59, tzinfo=timezone.utc)

    ai_pubkey = _load_public_key_pem("ai")
    human_pubkey = _load_public_key_pem("human")

    total = 0
    human_ops = 0
    ai_ops = 0
    unknown_ops = 0
    pre_signing = 0
    flagged = []

    log_files = [APPROVALS_LOG]

    for log_file in log_files:
        if not log_file.exists():
            continue
        for line in log_file.read_text().splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue

            # Date filter
            ts_str = entry.get("date") or entry.get("timestamp", "")
            try:
                ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
                if not (start <= ts <= end):
                    continue
            except (ValueError, AttributeError):
                pass

            total += 1

            # Pre-signing era: no ECDSA signature
            if "signature" not in entry:
                pre_signing += 1
                op_type = entry.get("operator_type", entry.get("itil5_practice", "UNKNOWN"))
                if op_type == "HUMAN" or "approved_by" in entry:
                    human_ops += 1
                else:
                    unknown_ops += 1
                continue

            # Post-signing era: ECDSA verification
            verified = False
            op_type = "UNKNOWN"

            if ai_pubkey and verify_signature(entry, ai_pubkey):
                verified = True
                op_type = "AI"
                ai_ops += 1
            elif human_pubkey and verify_signature(entry, human_pubkey):
                verified = True
                op_type = "HUMAN"
                human_ops += 1

            if not verified:
                flagged.append({
                    "entry": entry,
                    "reason": "ECDSA verification failed — possible tampering or key mismatch",
                })
                unknown_ops += 1

    return {
        "total_operations": total,
        "human_ops": human_ops,
        "ai_ops": ai_ops,
        "unknown_ops": unknown_ops,
        "pre_signing_entries": pre_signing,
        "tampering_detected": len(flagged) > 0,
        "flagged_entries": flagged,
        "date_range": {"start": start_date, "end": end_date},
        "keys_available": {
            "ai": ai_pubkey is not None,
            "human": human_pubkey is not None,
        },
    }


def print_audit_report(report: dict) -> None:
    """Print formatted audit report to stdout."""
    print("\n" + "=" * 60)
    print(" Trustless Audit Report")
    print(f" Period: {report['date_range']['start']} -> {report['date_range']['end']}")
    print("=" * 60)
    print(f"  Total operations:      {report['total_operations']}")
    print(f"  Human operations:      {report['human_ops']}")
    print(f"  AI operations:         {report['ai_ops']}")
    print(f"  Unknown/unverified:    {report['unknown_ops']}")
    print(f"  Pre-signing entries:   {report['pre_signing_entries']} (legacy, not verified)")
    print()

    if report["tampering_detected"]:
        print(f"  WARNING TAMPERING DETECTED: {len(report['flagged_entries'])} entry(ies) failed verification")
        for f in report["flagged_entries"]:
            print(f"    -> {f['reason']}")
            print(f"       Entry: {json.dumps(f['entry'], separators=(',', ':'))[:120]}...")
    else:
        print("  Integrity check PASSED — all signed entries verified")

    print()
    keys = report["keys_available"]
    print(f"  Keys loaded: AI={'yes' if keys['ai'] else 'no'}, Human={'yes' if keys['human'] else 'no'}")
    print("=" * 60)


if __name__ == "__main__":
    import sys
    start = sys.argv[1] if len(sys.argv) > 1 else "2026-01-01"
    end = sys.argv[2] if len(sys.argv) > 2 else "2026-12-31"
    report = audit_report(start, end)
    print_audit_report(report)
