# Trustless Audit — ECDSA Operation Signing

Cryptographic signing and tamper detection for AI operation logs.

> Based on the trustless design principle: **don't trust the log entry — verify the signature**.

## Why Two Key Pairs?

Most audit systems use a single signing key. This project uses separate key pairs for AI and HUMAN operations:

- **AI key** (`ai_public_key.pem`): used by automated scripts
- **Human key** (`human_public_key.pem`): used by human operators via `op run`

This makes `operator_type` field **technically verifiable**: the `key_fingerprint` in each log entry identifies which public key was used. A log entry claiming `"operator_type": "HUMAN"` but signed with the AI key is a detectable discrepancy.

## Setup

```bash
pip install -r tools/trustless_audit/requirements.txt

# Generate key pairs (do this once per role)
python tools/trustless_audit/scripts/generate_keypair.py --role ai
python tools/trustless_audit/scripts/generate_keypair.py --role human
```

Store private keys in 1Password immediately after generation, then delete them.
Public keys (`keys/ai_public_key.pem`, `keys/human_public_key.pem`) are safe to commit.

## Usage

### Sign an operation log

```python
from tools.trustless_audit.src.signing import sign_operation_log

log_entry = {
    "operator_id": "human_001",
    "operator_type": "HUMAN",
    "action": "approve_gate",
    "detail": {"activity": "deploy", "jurisdiction": "EU"}
}

# Load private key from 1Password:
# private_key_pem = subprocess.check_output(["op", "read", "op://AI Portfolio/signing-key-human/private_key"])

signed = sign_operation_log(log_entry, private_key_pem)
```

### Verify a signature

```python
from tools.trustless_audit.src.signing import verify_signature

public_key_pem = Path("tools/trustless_audit/keys/human_public_key.pem").read_bytes()
is_valid = verify_signature(signed_log, public_key_pem)
```

### Run audit report

```bash
python tools/trustless_audit/src/audit.py 2026-01-01 2026-12-31
```

## Algorithm

NIST P-256 / secp256r1 — NIST FIPS 186-5 compliant.

**Phase 5 roadmap**: migrate to CRYSTALS-Dilithium (NIST FIPS 204) for post-quantum resistance.

## Known Limitations

| Limitation | Status | Roadmap |
|-----------|--------|---------|
| Single key per role | 1Password dependency | Phase 5: Multi-signature |
| Post-quantum resistance | Not yet | Phase 5: CRYSTALS-Dilithium |
| Timestamp trust | Server clock | Phase 5: RFC 3161 TSP |

---

## 日本語版

### 概要

AIおよび人間の操作ログに対するECDSA署名と改ざん検知。

**2種類の鍵ペアを使う理由**: 単一鍵では `operator_type: "AI"/"HUMAN"` はログ上の自己申告に過ぎない。鍵を分離することで、`key_fingerprint` フィールドがどちらの公開鍵に対応するかを検証でき、操作者種別を技術的に証明できる。

### セットアップ

```bash
pip install -r tools/trustless_audit/requirements.txt
python tools/trustless_audit/scripts/generate_keypair.py --role ai
python tools/trustless_audit/scripts/generate_keypair.py --role human
```

秘密鍵は生成後すぐに1Passwordに格納し、ローカルから削除する。
公開鍵（`keys/ai_public_key.pem`・`keys/human_public_key.pem`）はリポジトリにコミット可能。

### アルゴリズム

NIST P-256 / secp256r1（NIST FIPS 186-5準拠）。Phase 5でCRYSTALS-Dilithium（NIST FIPS 204）への移行を予定。
