"""
signing.py — ECDSA operation log signing and verification

Design:
    - AI key pair:    ai_private_key.pem / ai_public_key.pem
    - Human key pair: human_private_key.pem / human_public_key.pem

    Separating keys makes operator_type technically verifiable:
    the key_fingerprint field in each log entry identifies which
    public key was used, proving whether the operation was AI or human.

Algorithm: NIST P-256 with SHA-256 (deterministic ECDSA per RFC 6979)
"""

import hashlib
import json
from datetime import datetime, timezone

try:
    from cryptography.hazmat.primitives.asymmetric import ec
    from cryptography.hazmat.primitives.asymmetric.utils import (
        decode_dss_signature, encode_dss_signature
    )
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.exceptions import InvalidSignature
except ImportError as e:
    raise ImportError(
        "cryptography library required. "
        "Run: pip install -r tools/trustless_audit/requirements.txt"
    ) from e


def _load_private_key(private_key_pem: bytes):
    return serialization.load_pem_private_key(private_key_pem, password=None)


def _load_public_key(public_key_pem: bytes):
    return serialization.load_pem_public_key(public_key_pem)


def _key_fingerprint(public_key_pem: bytes) -> str:
    return hashlib.sha256(public_key_pem).hexdigest()


def _canonical_payload(log_entry: dict) -> bytes:
    """Stable JSON serialization for signing (sorted keys, no whitespace)."""
    entry_copy = {k: v for k, v in log_entry.items()
                  if k not in ("signature", "key_fingerprint")}
    return json.dumps(entry_copy, sort_keys=True, separators=(",", ":")).encode()


def sign_operation_log(log_entry: dict, private_key_pem: bytes) -> dict:
    """
    Sign an operation log entry with ECDSA P-256.

    Args:
        log_entry: Dict with at minimum: timestamp, operator_id, operator_type, action
        private_key_pem: PEM-encoded ECDSA private key bytes

    Returns:
        log_entry with 'signature' (hex) and 'key_fingerprint' (sha256 of pubkey) added

    The key_fingerprint allows verifiers to identify which public key was used
    (ai_public_key.pem vs human_public_key.pem), making operator_type verifiable.
    """
    if "timestamp" not in log_entry:
        log_entry = {**log_entry, "timestamp": datetime.now(timezone.utc).isoformat()}

    private_key = _load_private_key(private_key_pem)
    public_key_pem = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )

    payload = _canonical_payload(log_entry)
    signature_der = private_key.sign(payload, ec.ECDSA(hashes.SHA256()))

    return {
        **log_entry,
        "signature": signature_der.hex(),
        "key_fingerprint": _key_fingerprint(public_key_pem),
    }


def verify_signature(signed_log: dict, public_key_pem: bytes) -> bool:
    """
    Verify ECDSA signature on a signed log entry.

    Args:
        signed_log: Dict containing 'signature' and the original log fields
        public_key_pem: PEM-encoded ECDSA public key bytes

    Returns:
        True if signature is valid, False if tampered or wrong key
    """
    if "signature" not in signed_log:
        return False

    try:
        public_key = _load_public_key(public_key_pem)
        payload = _canonical_payload(signed_log)
        signature_der = bytes.fromhex(signed_log["signature"])
        public_key.verify(signature_der, payload, ec.ECDSA(hashes.SHA256()))
        return True
    except (InvalidSignature, ValueError, Exception):
        return False


def identify_operator_type(signed_log: dict, ai_public_key_pem: bytes, human_public_key_pem: bytes) -> str:
    """
    Determine operator type by matching key_fingerprint.

    Returns: 'AI', 'HUMAN', or 'UNKNOWN'

    This is the technical proof that operator_type field is accurate:
    if the declared type doesn't match the fingerprint, it's a discrepancy.
    """
    if "key_fingerprint" not in signed_log:
        return "UNKNOWN"

    fp = signed_log["key_fingerprint"]

    if fp == _key_fingerprint(ai_public_key_pem):
        return "AI"
    elif fp == _key_fingerprint(human_public_key_pem):
        return "HUMAN"
    else:
        return "UNKNOWN"
