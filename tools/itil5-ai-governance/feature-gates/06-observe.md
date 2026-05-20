# Activity 6: Observe — Minimum Guaranteed Features
> **ITIL 5 Lifecycle Activity 6 of 8** | 6C Capabilities: Cognition, Curation, Communication
> Based on ITIL 5 preview spec (PeopleCert, 2026); will align to final release.

The Observe activity provides the continuous sensing layer that makes ITIL 5's Improve loop actionable. Where Operate focuses on keeping the system running, Observe focuses on whether the system is still producing the right outcomes. This distinction is critical for AI: a model can be operationally healthy (low latency, no errors) while silently degrading in accuracy, fairness, or regulatory alignment. Observe surfaces invisible drift before it becomes an incident.

| Feature | Success Criteria | Evidence File | Status |
|---------|-----------------|---------------|--------|
| Model Drift Detection | Statistical drift test (PSI or KS) run weekly; alert triggered if drift score exceeds threshold | monitoring/drift-report.json | ☐ |
| KPI Tracking | Business KPIs tracked weekly against pre-AI baseline; dashboard reviewed in monthly governance meeting | monitoring/kpi-dashboard.md | ☐ |
| Bias Drift Monitoring | Fairness metrics (demographic parity, equalized odds) tracked per demographic group; trend plotted monthly | monitoring/fairness-trend.csv | ☐ |
| Explainability Monitoring | SHAP/LIME scores tracked per model version; feature importance shifts flagged when delta > 15% | monitoring/xai-log.csv | ☐ |
| Feedback Loop | User feedback collected via structured channel; analyzed bi-weekly; insights routed to Improve activity | monitoring/feedback.md | ☐ |
| Regulatory Update Watch | JP (Act on Protection of Personal Information), US (Executive Order on AI), and EU (AI Act amendments) tracked; new obligations logged within 30 days of publication | monitoring/regulatory-watch.md | ☐ |

---
## 日本語版
**アクティビティ6: Observe — 最低保証機能カタログ**
ITIL 5適用: Cognition（AI 推論品質評価）, Curation（観測データ管理）, Communication（KPI 報告）

Operateがシステム稼働維持に集中するのに対し、Observeは「正しい成果を生み続けているか」を問う。精度・公平性・規制準拠の静かな劣化はObserveだけが検出できる。

| 機能 | 合格基準 | 根拠ファイル | 状態 |
|-----|---------|------------|------|
| モデルドリフト検出 | PSI/KS検定を週次実施、閾値超過でアラート | monitoring/drift-report.json | ☐ |
| KPI追跡 | ビジネスKPIをAI導入前ベースラインと週次比較、月次ガバナンス会議でダッシュボードレビュー | monitoring/kpi-dashboard.md | ☐ |
| バイアスドリフト監視 | デモグラフィックパリティ・均等化オッズを属性別月次集計 | monitoring/fairness-trend.csv | ☐ |
| 説明可能性監視 | SHAP/LIMEスコアをモデル版別追跡、特徴重要度変化が15%超でフラグ | monitoring/xai-log.csv | ☐ |
| フィードバックループ | ユーザーフィードバックを構造化チャネルで収集、隔週分析しImproveへルーティング | monitoring/feedback.md | ☐ |
| 規制改正ウォッチ | JP個人情報保護法・US AI大統領令・EU AI Act改正を追跡、公布30日以内に記録 | monitoring/regulatory-watch.md | ☐ |
