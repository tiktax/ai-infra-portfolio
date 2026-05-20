# Activity 3: Build — Minimum Guaranteed Features
> **ITIL 5 Lifecycle Activity 3 of 8** | 6C Capabilities: Creation, Curation, Cognition
> Based on ITIL 5 preview spec (PeopleCert, 2026); will align to final release.

The Build activity is where AI system components are constructed, trained, and validated against the specifications produced in Design. Evidence generated here serves as the primary artifact for regulatory conformity assessments and post-deployment audits. Build outputs must be reproducible and traceable; any result that cannot be independently re-created is considered non-compliant. All features below must be verified before the Deploy gate is opened.

| Feature | Success Criteria | Evidence File | Status |
|---------|-----------------|---------------|--------|
| Model Accuracy | F1 ≥ 0.85 on held-out test set, or task-specific threshold documented and justified | results/eval.json | ☐ |
| Bias Audit | Demographic disparity across protected groups < 5%; results reviewed by ethics lead | audit/fairness.md | ☐ |
| Data Lineage | End-to-end lineage traced from raw source to model artifact; no undocumented transformations | docs/lineage.md | ☐ |
| Human Override | Override mechanism implemented, tested with ≥ 3 scenarios, and results documented | tests/override.md | ☐ |
| EU Art.12 Lifecycle Log | Automated logging active throughout build; log format compliant with EU AI Act Article 12 | logs/ai-lifecycle.log | ☐ |
| Unit Test Coverage | ≥ 80% line coverage on core model logic and pre/post-processing pipelines | tests/coverage.html | ☐ |
| Reproducibility | Full build reproducible from documented seed and environment spec; verified by second engineer | docs/reproducibility.md | ☐ |

---
## 日本語版
**アクティビティ3: Build — 最低保証機能カタログ**
ITIL 5適用: Creation（AI能力構築）, Curation（AIアセット管理）, Cognition（AI推論）

Build成果物は規制適合審査と事後監査の一次エビデンスとなる。再現不可能な結果は非準拠とみなす。

| 機能 | 合格基準 | 根拠ファイル | 状態 |
|-----|---------|------------|------|
| モデル精度 | テストセットでF1 ≥ 0.85、またはタスク固有閾値を文書化・正当化 | results/eval.json | ☐ |
| バイアス監査 | 保護属性グループ間の格差 < 5%。倫理リードがレビュー | audit/fairness.md | ☐ |
| データリネージ | 生データからモデル成果物まで完全追跡。未記録の変換なし | docs/lineage.md | ☐ |
| 人間オーバーライド | 3シナリオ以上でテスト済み。結果を文書化 | tests/override.md | ☐ |
| EUアート.12ライフサイクルログ | Build全体で自動ログ稼働。EU AI Act第12条準拠フォーマット | logs/ai-lifecycle.log | ☐ |
| ユニットテストカバレッジ | コアロジックと前後処理パイプラインで行カバレッジ ≥ 80% | tests/coverage.html | ☐ |
| 再現性 | シードと環境仕様から完全再現可能。第二エンジニアが検証 | docs/reproducibility.md | ☐ |
