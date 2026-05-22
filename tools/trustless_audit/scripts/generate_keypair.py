#!/usr/bin/env python3
"""
generate_keypair.py — Generate ECDSA P-256 key pairs for AI/HUMAN operation signing

Usage:
    python generate_keypair.py --role ai
    python generate_keypair.py --role human
    python generate_keypair.py --role ai --test   # test mode (no files written)

Key design:
    - Separate key pairs for AI and HUMAN operations
    - This separation makes operator_type technically verifiable:
      key_fingerprint in log → matches ai_public_key.pem OR human_public_key.pem
    - Private keys: store in 1Password immediately after generation, then delete
    - Public keys: safe to commit to repository (keys/ai_public_key.pem, keys/human_public_key.pem)

Algorithm: NIST P-256 / secp256r1 (NIST FIPS 186-5)
Phase 5 roadmap: migrate to CRYSTALS-Dilithium (NIST FIPS 204) for post-quantum resistance
"""

import argparse
import hashlib
import os
import sys
from pathlib import Path

try:
    from cryptography.hazmat.primitives.asymmetric import ec
    from cryptography.hazmat.primitives import serialization
except ImportError:
    print("ERROR: cryptography library not installed.")
    print("Run: pip install -r tools/trustless_audit/requirements.txt")
    sys.exit(1)

KEYS_DIR = Path(__file__).parent.parent / "keys"


def generate_keypair(role: str) -> tuple[bytes, bytes]:
    """Generate ECDSA P-256 key pair. Returns (private_pem, public_pem)."""
    private_key = ec.generate_private_key(ec.SECP256R1())

    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    )

    public_pem = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )

    return private_pem, public_pem


def fingerprint(public_pem: bytes) -> str:
    """SHA-256 fingerprint of public key PEM."""
    return hashlib.sha256(public_pem).hexdigest()


def main():
    parser = argparse.ArgumentParser(description="Generate ECDSA key pairs for trustless audit signing")
    parser.add_argument("--role", choices=["ai", "human"], required=True,
                        help="Key role: 'ai' for automated operations, 'human' for manual approvals")
    parser.add_argument("--test", action="store_true",
                        help="Test mode: generate keys but do not write files")
    parser.add_argument("--algo", choices=["ecdsa", "pqc"], default="ecdsa",
                        help="Key algorithm: 'ecdsa' (NIST P-256, default) or 'pqc' (ML-DSA-65)")
    args = parser.parse_args()

    if args.algo == "pqc":
        # PQC key generation
        try:
            from tools.trustless_audit.src.pqc_signing import generate_pqc_keypair, _pqc_key_fingerprint
        except ImportError:
            # Try relative import
            import sys, os
            sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
            from src.pqc_signing import generate_pqc_keypair, _pqc_key_fingerprint

        print(f"\nGenerating ML-DSA-65 (CRYSTALS-Dilithium) key pair for role: {args.role}")
        print("Algorithm: ML-DSA-65 / NIST FIPS 204")
        print("Security:  128-bit post-quantum, 192-bit classical")
        print()

        sk, pk = generate_pqc_keypair()
        fp = _pqc_key_fingerprint(pk)
        print(f"  Public key fingerprint (SHA-256): {fp}")
        print(f"  Private key size: {len(sk)} bytes")
        print(f"  Public key size:  {len(pk)} bytes")

        if args.test:
            print("\n[TEST MODE] ML-DSA keys generated successfully (not written to disk)")
            return

        KEYS_DIR.mkdir(parents=True, exist_ok=True)
        private_path = KEYS_DIR / f"{args.role}_pqc_private_key.bin"
        public_path = KEYS_DIR / f"{args.role}_pqc_public_key.bin"

        private_path.write_bytes(sk)
        private_path.chmod(0o600)
        public_path.write_bytes(pk)

        print(f"\nGenerated:")
        print(f"  Private key: {private_path}  ({len(sk)} bytes)")
        print(f"  Public key:  {public_path}   ({len(pk)} bytes)")
        print()
        print("=" * 60)
        print("IMPORTANT: Store private key in 1Password, then delete it:")
        print()
        print(f"  op item create --vault 'AI Portfolio' \\")
        print(f"    --title 'pqc-signing-key-{args.role}' \\")
        print(f"    'private_key[file]={private_path}'")
        print()
        print(f"  rm {private_path}")
        print("=" * 60)
        return

    else:
        # ECDSA key generation (default)
        print(f"\nGenerating ECDSA P-256 key pair for role: {args.role}")
        print("Algorithm: NIST P-256 / secp256r1 (NIST FIPS 186-5)")
        print()

        private_pem, public_pem = generate_keypair(args.role)
        fp = fingerprint(public_pem)

        print(f"  Public key fingerprint (SHA-256): {fp}")

        if args.test:
            print("\n[TEST MODE] Keys generated successfully (not written to disk)")
            print(f"  Would write: keys/{args.role}_private_key.pem  <- store in 1Password")
            print(f"  Would write: keys/{args.role}_public_key.pem   <- safe to commit")
            return

        KEYS_DIR.mkdir(parents=True, exist_ok=True)

        private_path = KEYS_DIR / f"{args.role}_private_key.pem"
        public_path = KEYS_DIR / f"{args.role}_public_key.pem"

        private_path.write_bytes(private_pem)
        private_path.chmod(0o600)  # owner read-only
        public_path.write_bytes(public_pem)

        print(f"\nGenerated:")
        print(f"  Private key: {private_path}")
        print(f"  Public key:  {public_path}")
        print()
        print("=" * 60)
        print("IMPORTANT: Store the private key in 1Password, then delete it:")
        print()
        print(f"  op item create --vault 'AI Portfolio' \\")
        print(f"    --title 'signing-key-{args.role}' \\")
        print(f"    'private_key[file]={private_path}'")
        print()
        print(f"  rm {private_path}")
        print()
        print(f"The public key ({args.role}_public_key.pem) is safe to commit.")
        print("=" * 60)


if __name__ == "__main__":
    main()
