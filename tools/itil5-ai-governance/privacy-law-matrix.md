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
