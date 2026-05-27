# Annotated Sample Audit Log

This document explains the structure of `audit-log-sample.jsonl` — the append-only audit record
produced by this governance system.

Each line in the `.jsonl` file is one JSON object representing a single governance event.

---

## Entry Type 1: Pre-Signing Era (ITIL 5 Gate Approval)

```json
{
  "date": "2026-03-01T10:00:00Z",
  "activity": "deploy",
  "approved_by": "approver@example.com",
  "jurisdiction": "JP",
  "required_level": "Director",
  "evidence_hash": "sha256:a1b2c3...",
  "itil5_practice": "Change Enablement",
  "notes": "Model bias test passed. DPIA complete."
}
```

| Field | Description |
|-------|-------------|
| `date` | ISO 8601 timestamp of the approval |
| `activity` | ITIL 5 lifecycle activity (discover/design/build/deploy/operate/observe/improve/retire) |
| `approved_by` | Identity of the human approver |
| `jurisdiction` | Regulatory jurisdiction (JP/EU/US) — determines required approval level |
| `required_level` | Minimum authority required per jurisdiction and risk tier |
| `evidence_hash` | SHA-256 of the evidence file at time of approval; detects post-approval alteration |
| `itil5_practice` | ITIL 5 practice this gate belongs to |
| `notes` | Free-text rationale for approval |

**Audit behavior**: Entries without a `signature` field are treated as "pre-signing era" —
counted but not cryptographically verified. This maintains backward compatibility.

---

## Entry Type 2: ECDSA-Signed Entry (Post-Signing Era)

```json
{
  "timestamp": "2026-04-10T08:00:00Z",
  "operator_id": "demo_ai_agent",
  "operator_type": "AI",
  "action": "approve_gate",
  "activity": "build",
  "jurisdiction": "JP",
  "signature": "DEMO_ECDSA_SIGNATURE_HEX_PLACEHOLDER",
  "key_fingerprint": "DEMO_SHA256_OF_PUBLIC_KEY_PEM_PLACEHOLDER"
}
```

| Field | Description |
|-------|-------------|
| `timestamp` | ISO 8601 timestamp (auto-added if absent) |
| `operator_id` | Identifier of the AI agent or human who performed the action |
| `operator_type` | `"AI"` or `"HUMAN"` — declared type; provable via `key_fingerprint` |
| `action` | What was done (`approve_gate`, `block`, `delegate`, `agent_result`, …) |
| `signature` | ECDSA P-256 / SHA-256 signature (DER-encoded, hex) of the canonical payload |
| `key_fingerprint` | SHA-256 of the signer's public key PEM — links declared `operator_type` to a key |

**How tamper detection works**:
The `signature` is computed over the canonical payload (all fields except `signature` and
`key_fingerprint`, JSON-serialized with sorted keys). Any modification to any field produces
a different payload, making the signature invalid. `audit_report()` re-verifies each signature
and flags entries that fail verification as potential tampering.

**Accountability proof**: Because AI and human key pairs are separate, the `key_fingerprint`
field independently proves whether an AI or a human signed each entry — even if `operator_type`
were falsified.

---

## Entry Type 3: Dual-Signed Entry (ECDSA + ML-DSA-65)

```json
{
  "timestamp": "2026-04-12T09:14:22Z",
  "operator_id": "human_approver_001",
  "operator_type": "HUMAN",
  "action": "approve_gate",
  "activity": "deploy",
  "jurisdiction": "EU",
  "signature": "DEMO_ECDSA_SIGNATURE_HEX_PLACEHOLDER",
  "key_fingerprint": "DEMO_SHA256_OF_PUBLIC_KEY_PEM_PLACEHOLDER",
  "pqc_signature": "DEMO_ML_DSA_65_SIGNATURE_3293_BYTES_PLACEHOLDER",
  "pqc_key_fingerprint": "DEMO_SHA256_OF_ML_DSA_PUBLIC_KEY_PLACEHOLDER",
  "pqc_algorithm": "ML-DSA-65"
}
```

Additional fields for post-quantum cryptography:

| Field | Description |
|-------|-------------|
| `pqc_signature` | ML-DSA-65 (CRYSTALS-Dilithium, NIST FIPS 204) signature, hex-encoded |
| `pqc_key_fingerprint` | SHA-256 of the ML-DSA-65 public key |
| `pqc_algorithm` | Always `"ML-DSA-65"` — 128-bit post-quantum security |

**Signing order**: PQC signature is added first; ECDSA is computed second (so ECDSA canonical
payload includes the `pqc_*` fields). This means ECDSA verification alone is sufficient to
detect tampering with any field including the PQC signature.

---

## Hash Chain Structure

Each Entry N includes `prev_hash: sha256(Entry N-1)` (in the full hash-chained log):

```
Entry N:
  prev_hash: sha256(Entry N-1)
  action: "approve_gate"
  timestamp: 2026-04-12T09:14:22Z
  signature: ECDSA(private_key, sha256(action + timestamp + prev_hash))

Entry N+1:
  prev_hash: sha256(Entry N)   ← breaks if Entry N is altered
  ...
```

Rewriting a past entry requires re-signing every subsequent entry with the offline private key —
making retroactive alteration practically infeasible.

---

## Jurisdiction-Level Approval Requirements

| Jurisdiction | Required Approver | Basis |
|---|---|---|
| JP | Director level | 金融庁 AI リスク管理ガイドライン |
| EU | Third-party conformity assessment body | EU AI Act Article 43 |
| US | CRO / independent model risk officer | SR 11-7 Model Risk Management |

---

## Related Files

| File | Description |
|------|-------------|
| `tools/trustless_audit/src/signing.py` | ECDSA signing and verification |
| `tools/trustless_audit/src/audit.py` | Audit report with tamper detection |
| `tools/trustless_audit/src/pqc_signing.py` | ML-DSA-65 post-quantum signing |
| `tools/itil5-ai-governance/approvals.log` | Production approval log |
| `tools/itil5-ai-governance/phase-gate.sh` | CLI for recording approvals |

## 日本語版

このファイルは `audit-log-sample.jsonl` の各フィールドを解説するアノテーション文書です。

### エントリ種別

| 種別 | 説明 |
|------|------|
| Pre-Signing Era | `signature` フィールドなし。後方互換のためカウントのみ、改ざん判定なし |
| ECDSA 署名済み | `signature` + `key_fingerprint` あり。audit.py が ECDSA 検証 |
| Dual-Signed | ECDSA + ML-DSA-65 両署名。量子コンピューター耐性 |

### 改ざん検知の仕組み

署名は `signature` と `key_fingerprint` を除いた全フィールドの JSON（キーソート済み）に
対して計算されます。フィールドを1文字でも変更すると署名が無効化され、
`audit_report()` が `flagged_entries` に追記します。

### 責任分界の証明

AI 鍵と人間鍵は別ペアのため、`key_fingerprint` が「どちらの鍵で署名したか」を
客観的に証明します。`operator_type` フィールドを自己申告に改ざんしても、
`key_fingerprint` との不一致で検出されます。
