"""
openai-audit-middleware.py — Platform-agnostic audit layer for OpenAI API calls

Wraps openai.OpenAI() to record every chat completion with an ECDSA-signed
audit entry in the same format as the Claude Code audit trail.

This proves the "platform-agnostic governance layer" claim:
the same cryptographic audit trail works regardless of which AI platform is used.

Usage (drop-in replacement):
    from openai_audit_middleware import AuditedOpenAI
    client = AuditedOpenAI()                  # same as openai.OpenAI()
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": "Hello"}]
    )
    # → audit entry signed and appended to approvals.log

Demo (no API key needed):
    python openai-audit-middleware.py --demo

OWASP: Complements ASI02 (Tool Misuse) / ASI05 (Code Execution) for OpenAI workloads.
Platform: OpenAI Python SDK (openai >= 1.0)
"""

import hashlib
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

# ---------------------------------------------------------------------------
# Resolve REPO_ROOT relative to this file's location
# tools/multi-ai-governance/openai-audit-middleware.py → ../../../ = repo root
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).parent.parent.parent

# ---------------------------------------------------------------------------
# Optional: import signing module from trustless_audit
# ---------------------------------------------------------------------------
_signing_available = False
try:
    sys.path.insert(0, str(REPO_ROOT / "tools" / "trustless_audit" / "src"))
    from signing import sign_operation_log  # type: ignore
    _signing_available = True
except ImportError:
    pass

# ---------------------------------------------------------------------------
# Optional: import openai (not required for --demo mode)
# ---------------------------------------------------------------------------
_openai_available = False
try:
    import openai as _openai_module
    _openai_available = True
except ImportError:
    pass


# ---------------------------------------------------------------------------
# Key management helpers
# ---------------------------------------------------------------------------

def _load_or_generate_private_key() -> tuple[bytes, bool]:
    """
    Try to load role_private_key.pem from trustless_audit/keys/.
    Falls back to generating an ephemeral ECDSA P-256 key.

    Returns:
        (private_key_pem_bytes, is_ephemeral)
    """
    key_path = REPO_ROOT / "tools" / "trustless_audit" / "keys" / "role_private_key.pem"
    if key_path.exists():
        return key_path.read_bytes(), False

    # Generate ephemeral key — requires cryptography library
    try:
        from cryptography.hazmat.primitives.asymmetric import ec
        from cryptography.hazmat.primitives import serialization

        private_key = ec.generate_private_key(ec.SECP256R1())
        pem = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.NoEncryption(),
        )
        return pem, True
    except ImportError:
        return b"", True


def _sha256_hex(data: str) -> str:
    return hashlib.sha256(data.encode("utf-8")).hexdigest()


# ---------------------------------------------------------------------------
# Audit entry builder
# ---------------------------------------------------------------------------

def _build_audit_entry(
    operator_id: str,
    model: str,
    messages: list,
    response_content: str,
    token_usage: dict,
    is_ephemeral: bool,
) -> dict:
    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "operator_id": operator_id,
        "operator_type": "HUMAN",
        "action": "openai_chat_completion",
        "platform": "openai",
        "model": model,
        "prompt_sha256": _sha256_hex(json.dumps(messages, sort_keys=True)),
        "response_sha256": _sha256_hex(response_content),
        "token_usage": token_usage,
        "component": "openai_audit_middleware",
    }
    if is_ephemeral:
        entry["signing_note"] = "ephemeral_key"
    return entry


def _sign_entry(entry: dict, private_key_pem: bytes) -> dict:
    """Sign entry if signing module is available; otherwise return as-is."""
    if not _signing_available or not private_key_pem:
        entry["signature"] = "unsigned"
        entry["key_fingerprint"] = "n/a"
        return entry
    try:
        return sign_operation_log(entry, private_key_pem)
    except Exception as exc:
        entry["signature"] = f"signing_error:{exc}"
        entry["key_fingerprint"] = "n/a"
        return entry


def _append_to_log(log_path: Path, entry: dict) -> None:
    """Append a JSON line to the audit log. Errors are printed but not raised."""
    try:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        with log_path.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except Exception as exc:
        print(f"[openai-audit-middleware] WARNING: failed to write audit log: {exc}", file=sys.stderr)


# ---------------------------------------------------------------------------
# Thin proxy objects that mirror openai's chat.completions namespace
# ---------------------------------------------------------------------------

class _CompletionsProxy:
    def __init__(self, real_completions, middleware: "AuditedOpenAI"):
        self._real = real_completions
        self._mw = middleware

    def create(self, model: str, messages: list, **kwargs):
        prompt_sha256 = _sha256_hex(json.dumps(messages, sort_keys=True))

        response = self._real.create(model=model, messages=messages, **kwargs)

        # Extract response content and token usage
        try:
            content = response.choices[0].message.content or ""
        except (AttributeError, IndexError):
            content = ""

        try:
            usage = {
                "prompt_tokens": response.usage.prompt_tokens,
                "completion_tokens": response.usage.completion_tokens,
            }
        except AttributeError:
            usage = {}

        self._mw._record(model=model, messages=messages, response_content=content, token_usage=usage)
        return response


class _ChatProxy:
    def __init__(self, real_chat, middleware: "AuditedOpenAI"):
        self.completions = _CompletionsProxy(real_chat.completions, middleware)


# ---------------------------------------------------------------------------
# Main class
# ---------------------------------------------------------------------------

class AuditedOpenAI:
    """
    Drop-in replacement for openai.OpenAI().

    Every chat.completions.create() call is recorded as an ECDSA-signed
    audit entry appended to approvals.log.
    """

    def __init__(self, operator_id: str = None, log_path: Path = None, **openai_kwargs):
        self.operator_id = operator_id or os.environ.get("USER") or "unknown"
        self.log_path = log_path or (
            REPO_ROOT / "tools" / "itil5-ai-governance" / "approvals.log"
        )

        self._private_key_pem, self._is_ephemeral = _load_or_generate_private_key()

        if _openai_available:
            self._client = _openai_module.OpenAI(**openai_kwargs)
            self.chat = _ChatProxy(self._client.chat, self)
        else:
            self._client = None
            self.chat = None

    def _record(self, model: str, messages: list, response_content: str, token_usage: dict) -> dict:
        entry = _build_audit_entry(
            operator_id=self.operator_id,
            model=model,
            messages=messages,
            response_content=response_content,
            token_usage=token_usage,
            is_ephemeral=self._is_ephemeral,
        )
        signed = _sign_entry(entry, self._private_key_pem)
        _append_to_log(self.log_path, signed)
        return signed


# ---------------------------------------------------------------------------
# CLI — --demo mode
# ---------------------------------------------------------------------------

def _run_demo() -> None:
    print("=== openai-audit-middleware demo (no API key required) ===\n")

    client = AuditedOpenAI(operator_id="demo_user")

    # Synthetic messages and response
    messages = [{"role": "user", "content": "Explain ITIL 5 AI governance in one sentence."}]
    synthetic_response = (
        "ITIL 5 AI Governance provides a structured framework for accountable, "
        "auditable AI lifecycle management aligned with organisational risk appetite."
    )
    token_usage = {"prompt_tokens": 18, "completion_tokens": 32}

    signed = client._record(
        model="gpt-4o",
        messages=messages,
        response_content=synthetic_response,
        token_usage=token_usage,
    )

    print("Audit entry written to:", client.log_path)
    print("\nSigned entry:")
    print(json.dumps(signed, indent=2, ensure_ascii=False))

    # Verification hint
    key_path = REPO_ROOT / "tools" / "trustless_audit" / "keys" / "role_public_key.pem"
    if signed.get("signature") not in ("unsigned", None) and not signed.get("signature", "").startswith("signing_error"):
        print("\nTo verify:")
        print(f"  python tools/trustless_audit/src/verify_log.py \\")
        print(f"    --log {client.log_path} \\")
        print(f"    --pubkey {key_path}")
    elif signed.get("signing_note") == "ephemeral_key":
        print("\nNote: ephemeral key used (role_private_key.pem not found).")
        print("      Signature is valid for this session only — not persistently verifiable.")
    else:
        print("\nNote: cryptography library not installed; entry recorded without signature.")
        print("      Run: pip install cryptography")

    print("\n✓ Demo complete.")


if __name__ == "__main__":
    if "--demo" in sys.argv:
        _run_demo()
    else:
        print("Usage:")
        print("  python openai-audit-middleware.py --demo")
        print()
        print("For library usage, import AuditedOpenAI:")
        print("  from openai_audit_middleware import AuditedOpenAI")
        sys.exit(0)
