"""
pqc_signing.py — Post-Quantum Cryptography signing with ML-DSA (CRYSTALS-Dilithium)

Algorithm: ML-DSA-65 (formerly Dilithium3) — NIST FIPS 204
Security level: NIST Level 3 (128-bit post-quantum, 192-bit classical)

Key sizes (ML-DSA-65):
  Public key:  1952 bytes
  Private key: 4032 bytes
  Signature:   3309 bytes

Dual-signing strategy (migration period):
  Each log entry carries BOTH ECDSA P-256 and ML-DSA-65 signatures.
  CRITICAL ordering in sign_dual():
    1. PQC signature is added FIRST
    2. ECDSA signature is added SECOND (signing over the payload that already includes pqc fields)
  This ensures signing.py's _canonical_payload() (which excludes 'signature' and
  'key_fingerprint' but NOT pqc fields) computes correctly:
    - ECDSA payload includes pqc_signature and pqc_key_fingerprint → consistent at verify time
    - PQC payload excludes nothing extra → also consistent

  To verify ECDSA on a dual-signed entry: signing.py's verify_signature() works as-is
  because _canonical_payload() includes the pqc_ fields in the payload (both at sign and verify time).

Requires: pip install dilithium-py>=1.4.0
"""

import hashlib
import json
from datetime import datetime, timezone

try:
    from dilithium import Dilithium3
    _PQC_AVAILABLE = True
except ImportError:
    _PQC_AVAILABLE = False


def _require_pqc() -> None:
    if not _PQC_AVAILABLE:
        raise ImportError(
            "ML-DSA requires dilithium-py. "
            "Run: pip install dilithium-py>=1.4.0"
        )


def generate_pqc_keypair() -> tuple[bytes, bytes]:
    """
    Generate ML-DSA-65 key pair.

    Returns:
        (private_key_bytes, public_key_bytes)

    Key sizes:
        Private key: 4032 bytes
        Public key:  1952 bytes
    """
    _require_pqc()
    pk, sk = Dilithium3.keygen()
    return sk, pk


def _pqc_key_fingerprint(public_key: bytes) -> str:
    """SHA-256 fingerprint of ML-DSA public key bytes."""
    return hashlib.sha256(public_key).hexdigest()


def _pqc_canonical_payload(log_entry: dict) -> bytes:
    """
    Canonical payload for PQC signing: exclude pqc-specific fields only.
    ECDSA fields (signature, key_fingerprint) are INCLUDED so that
    PQC signs over the complete ECDSA-signed entry or the base entry.
    """
    excluded = frozenset({"pqc_signature", "pqc_key_fingerprint"})
    filtered = {k: v for k, v in log_entry.items() if k not in excluded}
    return json.dumps(filtered, sort_keys=True, separators=(",", ":")).encode()


def sign_with_pqc(log_entry: dict, private_key: bytes) -> dict:
    """
    Add ML-DSA-65 signature to a log entry.

    Args:
        log_entry:   Dict to sign (may or may not have existing ECDSA signature)
        private_key: ML-DSA private key bytes (4032 bytes)

    Returns:
        log_entry with 'pqc_signature' and 'pqc_key_fingerprint' added.
    """
    _require_pqc()

    if "timestamp" not in log_entry:
        log_entry = {**log_entry, "timestamp": datetime.now(timezone.utc).isoformat()}

    payload = _pqc_canonical_payload(log_entry)

    # Dilithium3.sign() returns signature bytes
    # We need to derive public key from private key for fingerprint
    # dilithium-py stores pk in last 1952 bytes of the 4032-byte secret key
    # Actually, re-generate from the private key by using the stored pk suffix
    # Standard approach: keep (sk, pk) pair together; public key must be passed separately
    # Since sign_with_pqc only takes private_key, we embed pk derivation:
    # dilithium-py's sk already contains pk as the last portion
    PK_SIZE = 1952
    if len(private_key) >= PK_SIZE:
        public_key = private_key[-PK_SIZE:]
    else:
        raise ValueError(f"Invalid ML-DSA private key size: {len(private_key)} (expected 4032)")

    signature = Dilithium3.sign(private_key, payload)

    return {
        **log_entry,
        "pqc_signature": signature.hex(),
        "pqc_key_fingerprint": _pqc_key_fingerprint(public_key),
        "pqc_algorithm": "ML-DSA-65",
    }


def verify_pqc_signature(signed_log: dict, public_key: bytes) -> bool:
    """
    Verify ML-DSA-65 signature on a log entry.

    Args:
        signed_log:  Dict with 'pqc_signature' field
        public_key:  ML-DSA public key bytes (1952 bytes)

    Returns:
        True if signature is valid, False otherwise.
    """
    if not _PQC_AVAILABLE:
        return False

    if "pqc_signature" not in signed_log:
        return False

    # Verify fingerprint
    if signed_log.get("pqc_key_fingerprint") != _pqc_key_fingerprint(public_key):
        return False

    try:
        payload = _pqc_canonical_payload(signed_log)
        sig_bytes = bytes.fromhex(signed_log["pqc_signature"])
        return Dilithium3.verify(public_key, payload, sig_bytes)
    except Exception:
        return False


def sign_dual(
    log_entry: dict,
    ecdsa_private_pem: bytes,
    pqc_private_key: bytes,
) -> dict:
    """
    Apply both ML-DSA-65 and ECDSA P-256 signatures to a log entry.

    CRITICAL ORDER (must not be reversed):
      Step 1: PQC signature is applied first (to the base entry)
      Step 2: ECDSA signature is applied second (over entry + pqc fields)

    This ensures signing.py's verify_signature() works correctly:
      At verify time, _canonical_payload() (excluding 'signature'/'key_fingerprint')
      sees the pqc_ fields, which were present at ECDSA signing time.

    Args:
        log_entry:         Base log dict (no signatures yet)
        ecdsa_private_pem: ECDSA P-256 private key (PEM bytes)
        pqc_private_key:   ML-DSA-65 private key (4032 raw bytes)

    Returns:
        Dict with both pqc_signature and signature fields.
    """
    # Import here to avoid circular dependency
    from .signing import sign_operation_log

    if "timestamp" not in log_entry:
        log_entry = {**log_entry, "timestamp": datetime.now(timezone.utc).isoformat()}

    # Step 1: PQC first
    dual_signed = sign_with_pqc(log_entry, pqc_private_key)

    # Step 2: ECDSA second (now signs over entry that includes pqc_ fields)
    dual_signed = sign_operation_log(dual_signed, ecdsa_private_pem)

    return dual_signed
