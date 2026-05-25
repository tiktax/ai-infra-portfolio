# Privacy Law Compliance Matrix
ITIL 5 AI Governance — JP (APPI) / EU (GDPR) / US (CCPA) Requirements by Lifecycle Activity

> Based on ITIL 5 preview spec (PeopleCert, 2026). Legal requirements subject to change — verify with qualified counsel.

| Activity | JP (APPI 個人情報保護法) | EU (GDPR) | US (CCPA) |
|----------|------------------------|-----------|-----------|
| Discover | 要配慮個人情報の識別・分類 | DPIA trigger assessment (Art.35) | Sensitive data category inventory |
| Design | 利用目的の特定・通知設計 | Privacy by Design (Art.25); data minimization | Purpose limitation; no sale of data by default |
| Build | 仮名加工情報の適用検討 | Pseudonymization (Art.4); anonymization | De-identification per CCPA §1798.140 |
| Deploy | 第三者提供の同意取得・記録 | DPA with processors (Art.28); consent records | Notice at collection; opt-out mechanism |
| Operate | 開示・訂正・削除請求への対応体制 | Data subject rights responses (Art.15-22); breach 72h (Art.33) | Consumer rights responses; breach notification |
| Observe | 漏洩インシデントの監視・記録 | Ongoing Art.30 records; DPA supervisory authority watch | CCPA amendment tracking; AG enforcement watch |
| Improve | プライバシー影響を考慮した再学習設計 | Re-consent if purpose changes (Art.6); updated DPIA | Re-assess de-identification on model update |
| Retire | 保有期間終了データの削除証明 | Right to erasure (Art.17); deletion audit trail | Right to delete (§1798.105); record of deletion |

## Evidence Files by Activity

| Activity | Evidence File |
|----------|--------------|
| Discover | docs/dpia-assessment.md, docs/data-categories.md |
| Design | docs/privacy-design.md |
| Build | docs/anonymization.md |
| Deploy | docs/dpa-register.md |
| Operate | ops/breach-runbook.md |
| Observe | monitoring/regulatory-watch.md |
| Improve | docs/retrain-policy.md |
| Retire | docs/data-deletion.md |

---

## 日本語版

**プライバシー法令準拠マトリクス（ITIL 5 ライフサイクル別）**

各アクティビティで対応すべき主要要件の要点:

| アクティビティ | JP（個人情報保護法） | EU（GDPR） | US（CCPA） |
|--------------|------------------|-----------|-----------|
| Discover | 要配慮個人情報の識別・分類 | DPIA実施要否の閾値評価（第35条） | センシティブデータカテゴリ棚卸し |
| Design | 利用目的の特定と通知設計 | プライバシーバイデザイン（第25条）・データ最小化 | 目的限定・デフォルト非販売 |
| Build | 仮名加工情報の適用検討 | 仮名化（第4条）・匿名化 | CCPA §1798.140 非識別化基準 |
| Deploy | 第三者提供の同意取得・記録 | 処理委託契約DPA（第28条）・同意記録 | 収集時通知・オプトアウト機構 |
| Operate | 開示・訂正・削除請求への対応 | データ主体の権利（第15-22条）・72時間漏洩通知（第33条） | 消費者権利対応・漏洩通知 |
| Observe | 漏洩インシデントの監視・記録 | 第30条記録継続・監督機関モニタリング | CCPA改正追跡・AG執行動向監視 |
| Improve | 再学習設計へのプライバシー影響評価 | 目的変更時の再同意（第6条）・DPIA更新 | モデル更新時の非識別化再評価 |
| Retire | 保有期限到来データの削除証明 | 消去権（第17条）・削除監査証跡 | 削除権（§1798.105）・削除記録 |

---

## Cross-Border Data Transfer Rules

Applicable when AI systems transfer personal data across jurisdictions (e.g., sending audit logs to AWS S3 in a different region, using cloud AI APIs).

| Jurisdiction | Regulation | Transfer Mechanism | Requirements |
|---|---|---|---|
| **EU → Third Country** | GDPR Chapter V (Art.44–49) | Adequacy decision / SCCs / BCRs | No transfer without adequacy or appropriate safeguards. Japan has adequacy decision (2019). US: no blanket adequacy; use SCCs or DPF. |
| **JP → Foreign** | APPI Art.24 (改正後) | 相手国の個人情報保護水準の確認 | 2022年改正で外国提供時の情報提供義務追加。EU・英国は同等水準。米国は個別評価が必要。 |
| **US (CA) → Foreign** | CCPA / CPRA | No explicit transfer restriction | CPRA §1798.100(d): consumers have right to know recipients. No equivalent of GDPR adequacy mechanism. |
| **All** | Contract | Data Processing Agreement (DPA) | All processors must sign DPA per GDPR Art.28. Equivalent contractual protection recommended for JP/US. |

**For this project (ai-infra-portfolio)**:
- Audit logs → AWS S3 `ap-northeast-1` (Tokyo): JP domestic → no transfer issue
- Claude API calls → Anthropic (US): JP→US transfer; mitigated by operator-controlled data minimization
- All transfers logged in `tools/itil5-ai-governance/approvals.log` via Change Enablement

---

## Anonymization Standards Comparison

Different jurisdictions define anonymization/pseudonymization differently. This table reconciles the three regimes.

| Concept | JP (APPI) | EU (GDPR) | US (CCPA) | Notes |
|---|---|---|---|---|
| **Pseudonymization** | 仮名加工情報 (Art.41) | Pseudonymisation (Art.4(5)) | Not defined as distinct concept | JP: cannot re-identify without additional info held separately. EU: similar but not exempt from GDPR entirely. |
| **Anonymization** | 匿名加工情報 (Art.43) | Anonymous information (Recital 26) | De-identification (§1798.140(h)) | JP: irreversibly processed; APPI no longer applies. EU: genuinely anonymous data exempt from GDPR. US: must be "reasonably" non-re-identifiable. |
| **Re-identification risk** | Objective standard: "cannot be re-identified using generally available information" | "means reasonably likely to be used" — context-dependent | "reasonably" — no bright-line rule | EU standard is broader (context-sensitive). JP/US more objective. |
| **Regulatory exemption** | 匿名加工情報: APPI exempt | Truly anonymous: GDPR exempt | De-identified: CCPA exempt (with technical and process safeguards) | All three: pseudonymized data is NOT exempt and remains regulated. |

**For this project**:
- `audit.py` `scrub_pii()`: display-time substitution only — does **not** constitute anonymization under any jurisdiction
- True anonymization of audit logs would require irreversible removal + independent verification
- Current approach: retain signed originals (for accountability) + scrub display output (for operational privacy)

### Reconciliation Summary

```
JP 匿名加工情報 ≈ EU Anonymous Information ≈ US De-identified
JP 仮名加工情報 ≈ EU Pseudonymized (but regulatory treatment differs)

Safest common standard: EU GDPR anonymization criteria
(most stringent re-identification risk assessment)
```

---

## 日本語版 — クロスボーダー転送・匿名化基準

### クロスボーダーデータ転送ルール

| 管轄 | 法令 | 移転手段 | 要件 |
|---|---|---|---|
| EU → 第三国 | GDPR 第5章 (第44〜49条) | 十分性認定 / SCC / BCR | 日本は十分性認定済み (2019年)。米国は SCC または DPF が必要。 |
| JP → 外国 | 改正 APPI 第24条 | 相手国の保護水準確認 | 2022年改正で外国提供時の情報提供義務追加。EU・英国は同等水準とみなす。 |
| US (CA) → 外国 | CCPA / CPRA | 明示的な制限なし | 消費者への開示義務あり (CPRA §1798.100(d))。GDPRの十分性認定に相当する制度なし。 |

### 匿名化基準の差分

| 概念 | JP (APPI) | EU (GDPR) | US (CCPA) |
|---|---|---|---|
| 仮名化 / 擬名化 | 仮名加工情報（第41条）| Pseudonymisation（第4条(5)号）| 定義なし |
| 匿名化 | 匿名加工情報（第43条）| Anonymous information（前文第26項）| De-identification（§1798.140(h)）|
| 再識別リスク基準 | 客観的基準：「一般に入手可能な情報を使用しても識別不可能」 | 文脈依存：「合理的に使用される可能性のある手段」 | 「合理的に」（明確な基準なし）|
| 規制適用除外 | 匿名加工情報は APPI 適用外 | 真の匿名データは GDPR 適用外 | De-identified は CCPA 適用外（技術的・プロセス的保護措置が必要）|

**共通の最も安全な基準**: EU GDPR の匿名化基準（再識別リスク評価が最も厳格）
