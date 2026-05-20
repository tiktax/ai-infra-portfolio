# AI Product Cost Governance Template
**ITIL 5 Service Financial Management — Outcome-based KPI Framework**
> Based on ITIL 5 preview spec (PeopleCert, 2026); will align to final release.

Effective AI financial governance requires clear accountability across the full model lifecycle — from budget approval through audit retention. This template implements ITIL 5 Service Financial Management practice adapted for AI-specific cost drivers: inference compute, retraining runs, data pipeline, and regulatory compliance overhead. The RACI matrix below assigns decision rights; the KPI table defines measurable outcomes that justify continued investment.

---

## RACI Matrix — AI Product Cost Governance

**R** = Responsible (does the work) | **A** = Accountable (single owner, signs off) | **C** = Consulted (input required before decision) | **I** = Informed (notified of outcome)

| Activity | AI Product Owner | Data Scientist | MLOps Engineer | Chief Risk Officer | Chief Financial Officer | Compliance Officer | Business Stakeholder |
|----------|:----------------:|:--------------:|:--------------:|:------------------:|:-----------------------:|:-----------------:|:--------------------:|
| Budget Approval | C | I | I | C | A | C | R |
| Cost Monitoring | A | C | R | I | C | I | I |
| ROI Reporting | R | C | C | C | A | I | C |
| Risk Escalation | C | I | C | A | I | R | I |
| Audit Trail | C | I | R | C | I | A | I |
| Vendor Management | A | I | R | C | C | C | I |
| Regulatory Filing | C | I | I | C | I | A | I |

---

## Outcome-based KPI Framework

| KPI | Target | Measurement | Frequency |
|-----|--------|-------------|-----------|
| Inference Cost per Request | ≤ budget ceiling defined in ops/cost-metrics.csv | Total inference spend ÷ successful requests in period | Weekly |
| Model Accuracy Maintained | ≥ 95% of baseline accuracy established at Deploy | Evaluation metric (F1 / AUROC / RMSE) vs. baseline | Weekly |
| Bias Disparity | Demographic parity gap ≤ 5 percentage points across protected groups | Fairness metric per monitoring/fairness-trend.csv | Monthly |
| Incident Response Time | MTTR ≤ SLA target defined in ops/ai-runbook.md | Time from alert to resolution; P95 across all AI incidents | Monthly |
| Regulatory Compliance Score | 100% of mandatory controls in feature-gates/ marked complete | Automated gate check against feature-gates/*.md | Quarterly |
| ROI | Realized business value ≥ 120% of total lifecycle cost | (Revenue impact + cost savings) ÷ total AI spend | Quarterly |
| Time-to-Retrain | ≤ threshold defined in docs/retrain-policy.md after drift trigger | Calendar time from drift alert to new model in production | Per event |

---

## Cost Category Breakdown

Use the following categories when populating ops/cost-metrics.csv to ensure comparability across model versions and time periods.

| Category | Description | Cost Driver |
|----------|-------------|-------------|
| Inference Compute | GPU/CPU cycles for serving predictions | Requests × per-unit rate |
| Retraining Runs | Compute for periodic model updates | Training hours × instance rate |
| Data Pipeline | Ingestion, validation, feature engineering | Data volume + ETL job hours |
| Human Review | EU Art.14 oversight queue labor cost | Review hours × FTE rate |
| Compliance Overhead | Audit prep, regulatory filing, legal review | FTE time allocated to governance |
| Vendor / API Fees | Third-party model APIs or data providers | Contract rate + usage overage |

---
## 日本語版
**AIプロダクトコストガバナンステンプレート**
ITIL 5 サービス財務管理 — アウトカムベースKPIフレームワーク

AIの財務ガバナンスには推論コスト・再学習・データパイプライン・規制対応コストを横断する責任体制が必要。RACIマトリクスで意思決定権を明確化し、KPI表で投資継続の根拠を定量化する。

**RACIの凡例**: R=実施責任 | A=説明責任（1人） | C=協議必要 | I=情報共有

**主要KPI要点**:
- 推論コスト/リクエスト: ops/cost-metrics.csvの上限以下を週次確認
- モデル精度維持: ベースライン精度95%以上を週次評価
- バイアス格差: 保護属性間の格差5ポイント以内を月次監視
- インシデント対応時間: MTTR ≤ ランブック定義値、月次P95集計
- 規制準拠スコア: feature-gates/全必須コントロール完了率100%を四半期確認
- ROI: 実現ビジネス価値 ≥ ライフサイクル総コストの120%を四半期報告
- 再学習所要時間: ドリフトアラートから本番投入まで docs/retrain-policy.md 閾値以内
