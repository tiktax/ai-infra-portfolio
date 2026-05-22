"""
multisig.py — M-of-N Multi-Signature for trustless operation logs

Design:
    N registered signers each hold their own ECDSA key pair.
    A log entry requires signatures from at least M of them to be valid.
    Single key compromise cannot forge a valid M-of-N entry.

Key principle: _canonical_payload_multisig() MUST exclude all signature-related
fields before computing the payload, so each signer signs the same base content
regardless of how many signatures have already been added.
"""

import hashlib
import json
from datetime import datetime, timezone
from typing import Optional

from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.exceptions import InvalidSignature


# Fields excluded from canonical payload (any signature metadata)
_EXCLUDED_FIELDS = frozenset({
    "signatures",
    "threshold_met",
    "required_signers",
    "multisig_version",
})


def _canonical_payload_multisig(log_entry: dict) -> bytes:
    """
    Stable JSON serialization excluding all multisig metadata fields.
    Each signer computes the same payload regardless of prior signatures.
    """
    filtered = {k: v for k, v in log_entry.items() if k not in _EXCLUDED_FIELDS}
    return json.dumps(filtered, sort_keys=True, separators=(",", ":")).encode()


def _load_private_key(private_key_pem: bytes):
    return serialization.load_pem_private_key(private_key_pem, password=None)


def _load_public_key(public_key_pem: bytes):
    return serialization.load_pem_public_key(public_key_pem)


def _key_fingerprint(public_key_pem: bytes) -> str:
    return hashlib.sha256(public_key_pem).hexdigest()


def add_signature(
    log_entry: dict,
    signer_id: str,
    private_key_pem: bytes,
    required_signers: Optional[int] = None,
) -> dict:
    """
    Add one signer's ECDSA signature to the log entry.

    Args:
        log_entry:        The log dict to sign (may already have other signatures)
        signer_id:        Human-readable identifier for this signer (e.g. "ciso")
        private_key_pem:  PEM-encoded ECDSA private key
        required_signers: M threshold (only written on first signature call)

    Returns:
        Updated log_entry with this signer's signature appended to 'signatures' list.
    """
    if "timestamp" not in log_entry:
        log_entry = {**log_entry, "timestamp": datetime.now(timezone.utc).isoformat()}

    private_key = _load_private_key(private_key_pem)
    public_key_pem = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )

    payload = _canonical_payload_multisig(log_entry)
    signature_der = private_key.sign(payload, ec.ECDSA(hashes.SHA256()))

    new_sig = {
        "signer_id": signer_id,
        "signature": signature_der.hex(),
        "key_fingerprint": _key_fingerprint(public_key_pem),
    }

    result = dict(log_entry)
    result.setdefault("signatures", [])
    result["signatures"] = list(result["signatures"]) + [new_sig]
    result["multisig_version"] = "1"

    if required_signers is not None and "required_signers" not in result:
        result["required_signers"] = required_signers

    # Update threshold_met based on current count (optimistic; real check via verify_multisig)
    n_sigs = len(result["signatures"])
    req = result.get("required_signers", n_sigs)
    result["threshold_met"] = n_sigs >= req

    return result


def verify_multisig(
    signed_log: dict,
    public_keys: dict[str, bytes],
    threshold: int,
) -> bool:
    """
    Verify that at least `threshold` valid signatures are present.

    Args:
        signed_log:  Log entry with 'signatures' list
        public_keys: Mapping of signer_id -> PEM public key bytes
        threshold:   Minimum number of valid signatures required (M)

    Returns:
        True if valid_signature_count >= threshold
    """
    signatures = signed_log.get("signatures", [])
    if not signatures:
        return False

    payload = _canonical_payload_multisig(signed_log)
    valid_count = 0

    for sig_entry in signatures:
        signer_id = sig_entry.get("signer_id", "")
        if signer_id not in public_keys:
            continue

        pubkey_pem = public_keys[signer_id]
        # Verify fingerprint matches
        if sig_entry.get("key_fingerprint") != _key_fingerprint(pubkey_pem):
            continue

        try:
            public_key = _load_public_key(pubkey_pem)
            sig_bytes = bytes.fromhex(sig_entry["signature"])
            public_key.verify(sig_bytes, payload, ec.ECDSA(hashes.SHA256()))
            valid_count += 1
        except (InvalidSignature, ValueError, KeyError):
            continue

    return valid_count >= threshold


def check_threshold(signed_log: dict) -> tuple[int, int]:
    """
    Return (current_signature_count, required_signers).
    Does not verify signatures — use verify_multisig() for that.
    """
    current = len(signed_log.get("signatures", []))
    required = signed_log.get("required_signers", 0)
    return current, required
