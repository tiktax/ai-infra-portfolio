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

NIST P-256 / secp256r1（NIST FIPS 186-5準拠）。Phase 5でML-DSA-65 / CRYSTALS-Dilithium（NIST FIPS 204）への移行を実装済み。

---

## Phase 5: Advanced Trustless Infrastructure

Phase 5 adds four additional layers of trustless security:

### Multi-Signature (M-of-N)

Require M out of N signers to validate a log entry. Single key compromise cannot forge a valid entry.

```python
from tools.trustless_audit.src.multisig import add_signature, verify_multisig

# 2-of-3 signing
entry = {"action": "approve_gate", "activity": "deploy"}
entry = add_signature(entry, "ciso", ciso_private_pem, required_signers=2)
entry = add_signature(entry, "cro",  cro_private_pem)

# Verify: requires 2 valid signatures
assert verify_multisig(entry, {"ciso": ciso_pub, "cro": cro_pub}, threshold=2)
```

### Post-Quantum Cryptography (ML-DSA-65)

Dual-sign with both ECDSA P-256 and ML-DSA-65 (CRYSTALS-Dilithium). Quantum-resistant.

```bash
pip install dilithium-py>=1.4.0
python tools/trustless_audit/scripts/generate_keypair.py --role ai --algo pqc
```

```python
from tools.trustless_audit.src.pqc_signing import sign_dual, verify_pqc_signature

# CRITICAL: PQC signed first, ECDSA second
dual_signed = sign_dual(entry, ecdsa_private_pem, pqc_private_key)
```

Key sizes (ML-DSA-65): public key 1952B, private key 4032B, signature 3309B.

### RFC 3161 Trusted Timestamps

External TSA proves log existed at a specific time — independent of local system clock.

```bash
pip install rfc3161ng>=1.1
python tools/trustless_audit/scripts/timestamp_log.py \
  --log tools/itil5-ai-governance/approvals.log
# → approvals.log.tsr (timestamp token, ~3KB)
```

Default TSA: `freetsa.org` (free, RFC 3161 compliant). Pass `--tsa <url>` for alternatives.

### WORM Storage (AWS S3 Object Lock)

7-year immutability guarantee — logs cannot be deleted even by root.

```bash
pip install boto3>=1.34.0
# Show CloudFormation config (no AWS needed):
python tools/trustless_audit/scripts/worm_upload.py --example-config

# Upload (requires AWS credentials via 1Password):
op run --env-file=tools/trustless_audit/.env.aws.1password -- \
  python tools/trustless_audit/scripts/worm_upload.py \
    --log tools/itil5-ai-governance/approvals.log \
    --bucket my-audit-worm --key 2026/approvals.log
```

## 日本語版

### Phase 5: 高度なTrustlessインフラ

#### マルチシグネータ（M-of-N）
N個の署名者のうちM個が署名した場合のみ有効。1鍵の漏洩ではログを偽造できない。

#### ポスト量子暗号（ML-DSA-65）
ECDSA P-256とML-DSA-65の二重署名。量子コンピューターへの耐性。
**重要な順序**: PQC署名 → ECDSA署名の順で適用すること。

鍵サイズ（ML-DSA-65）: 公開鍵 1952B、秘密鍵 4032B、署名 3309B

#### RFC 3161 タイムスタンプ
外部TSA（freetsa.org）がログの存在時刻を証明。ローカル時刻の偽装に対する耐性。

#### WORMストレージ（AWS S3 Object Lock）
COMPLIANCEモードで7年間削除不可。root権限でも削除できない不変性を保証。
