# Activity 7: Improve — Minimum Guaranteed Features
> **ITIL 5 Lifecycle Activity 7 of 8** | 6C Capabilities: Creation, Curation, Cognition, Coordination
> Based on ITIL 5 preview spec (PeopleCert, 2026); will align to final release.

The Improve activity closes the feedback loop that separates a governed AI program from an ad-hoc experiment. It converts signals from Observe into deliberate, traceable changes — whether a retraining run, a bias remediation procedure, or a stakeholder report. ITIL 5 embeds Continual Improvement as a practice that spans all lifecycle activities, but Activity 7 is where improvement becomes explicit, funded, and accountable. All changes produced here re-enter the lifecycle at Design or Build, ensuring full traceability.

| Feature | Success Criteria | Evidence File | Status |
|---------|-----------------|---------------|--------|
| Retraining Trigger | Drift threshold that triggers retraining is documented and version-controlled; trigger event logged per occurrence | docs/retrain-policy.md | ☐ |
| CIP Cycle | Continual Improvement Plan documented with owner, timeline, and success metric for each initiative; reviewed quarterly | docs/cip.md | ☐ |
| A/B Test Framework | Champion/challenger testing capability implemented; statistical significance threshold (p ≤ 0.05) enforced before promotion | tests/ab-framework.md | ☐ |
| Bias Remediation | Bias fix procedure documented; remediation tested against fairness metrics before deployment; rollback plan included | docs/bias-remediation.md | ☐ |
| Model Version Control | Model artifacts versioned with semantic versioning; provenance (training data hash, hyperparameters) recorded per version | models/VERSIONS.md | ☐ |
| Stakeholder Reporting | Improvement results communicated to business stakeholders within 30 days of initiative completion; report includes before/after KPI delta | reports/improvement-report.md | ☐ |

---
## 日本語版
**アクティビティ7: Improve — 最低保証機能カタログ**
ITIL 5適用: Creation（改善版AI構築）, Curation（モデル資産管理）, Cognition（改善判断）, Coordination（改善ライフサイクル調整）

Improveはad-hoc実験を脱してガバナンス付き改善サイクルを実現する活動。Observeからのシグナルを追跡可能な変更へ変換し、すべての変更はDesignまたはBuildへ再入する。

| 機能 | 合格基準 | 根拠ファイル | 状態 |
|-----|---------|------------|------|
| 再学習トリガー | ドリフト閾値を文書化してバージョン管理、トリガー発生ごとに記録 | docs/retrain-policy.md | ☐ |
| CIPサイクル | 担当者・期限・成功指標付き継続的改善計画を四半期レビュー | docs/cip.md | ☐ |
| A/Bテストフレームワーク | チャンピオン/チャレンジャーテスト実装、昇格前にp≤0.05の統計的有意性を強制 | tests/ab-framework.md | ☐ |
| バイアス修正 | 修正手順を文書化、デプロイ前に公平性指標でテスト、ロールバック計画含む | docs/bias-remediation.md | ☐ |
| モデルバージョン管理 | セマンティックバージョニングでモデル管理、版ごとに学習データハッシュ・ハイパーパラメータ記録 | models/VERSIONS.md | ☐ |
| ステークホルダー報告 | 改善完了30日以内にビジネスKPI前後比較を含む報告書を配布 | reports/improvement-report.md | ☐ |
