# Activity 2: Design — Minimum Guaranteed Features
> **ITIL 5 Lifecycle Activity 2 of 8** | 6C Capabilities: Creation, Clarification, Coordination
> Based on ITIL 5 preview spec (PeopleCert, 2026); will align to final release.

The Design activity translates Discover outputs into a blueprint that is technically sound, ethically defensible, and operationally coordinated. It is the last checkpoint where structural flaws can be corrected at low cost. Design gates must be cleared before any model training, data pipeline construction, or infrastructure provisioning begins. Outputs from this activity form the authoritative specification that Build engineers and auditors will reference.

| Feature | Success Criteria | Evidence File | Status |
|---------|-----------------|---------------|--------|
| Architecture Review | System design reviewed and signed off by a senior engineer; major trade-offs documented | docs/architecture-review.md | ☐ |
| Ethics Assessment | Bias risk scenarios identified; mitigation strategy documented for each scenario | docs/ethics.md | ☐ |
| Data Governance Design | End-to-end data lineage tracking approach designed; ownership and retention policies specified | docs/data-governance.md | ☐ |
| Human Oversight Plan | Human override mechanisms specified for all automated decisions; escalation path defined | docs/human-oversight.md | ☐ |
| Explainability Design | XAI approach selected and documented; explanation format appropriate for target audience | docs/explainability.md | ☐ |
| Security Design | Threat model completed (STRIDE or equivalent); mitigations mapped to each identified threat | docs/threat-model.md | ☐ |
| Privacy by Design | Data minimization and purpose limitation principles documented per GDPR Art.25; no excess data collection in architecture | docs/privacy-design.md | ☐ |

---
## 日本語版
**アクティビティ2: Design — 最低保証機能カタログ**
ITIL 5適用: Creation（AI能力構築）, Clarification（要件定義）, Coordination（サービス調整）

Designは構造的欠陥を低コストで修正できる最後のチェックポイント。Build開始前にすべてのゲートを通過すること。

| 機能 | 合格基準 | 根拠ファイル | 状態 |
|-----|---------|------------|------|
| アーキテクチャレビュー | シニアエンジニアがサインオフ。主要トレードオフを文書化 | docs/architecture-review.md | ☐ |
| 倫理アセスメント | バイアスリスクシナリオを特定し、各シナリオへの緩和策を記録 | docs/ethics.md | ☐ |
| データガバナンス設計 | エンドツーエンドのデータリネージ追跡方法を設計。所有権・保持ポリシーを明記 | docs/data-governance.md | ☐ |
| 人間監督計画 | 全自動判断に対するオーバーライド機構とエスカレーションパスを定義 | docs/human-oversight.md | ☐ |
| 説明可能性設計 | XAIアプローチを選定・文書化。対象ユーザーに適した説明形式を指定 | docs/explainability.md | ☐ |
| セキュリティ設計 | 脅威モデル（STRIDE等）完成。各脅威に対する緩和策をマッピング | docs/threat-model.md | ☐ |
| プライバシーバイデザイン | GDPR第25条に基づくデータ最小化・目的限定の原則を設計書に明記; アーキテクチャに過剰データ収集なし | docs/privacy-design.md | ☐ |
