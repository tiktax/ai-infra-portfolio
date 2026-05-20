# Activity 5: Operate — Minimum Guaranteed Features
> **ITIL 5 Lifecycle Activity 5 of 8** | 6C Capabilities: Coordination, Cognition, Curation
> Based on ITIL 5 preview spec (PeopleCert, 2026); will align to final release.

The Operate activity ensures that deployed AI systems run reliably, cost-effectively, and within regulatory tolerances. It covers day-to-day service delivery from inference serving to incident response, translating deployed capabilities into measurable business value. Operate creates the evidence trail that feeds both Observe (Activity 6) and regulatory audit requests. Without rigorous operational gates, latency degradation and cost overruns compound silently until they surface as incidents.

| Feature | Success Criteria | Evidence File | Status |
|---------|-----------------|---------------|--------|
| SLA Monitoring | Inference latency P99 ≤ threshold defined in docs/sla.md; breaches trigger automated alert within 5 minutes | ops/sla-dashboard.json | ☐ |
| Cost Tracking | Inference cost per request tracked per model version; monthly variance ≤ 10% vs. budget | ops/cost-metrics.csv | ☐ |
| Incident Response Plan | AI-specific runbook exists; MTTR target defined; escalation path includes AI Risk Owner | ops/ai-runbook.md | ☐ |
| Data Quality Monitoring | Input distribution checked daily against training baseline; anomaly score logged per batch | ops/data-quality-log.csv | ☐ |
| EU Art.14 Human Oversight | Human review queue operational for high-risk decisions; queue depth and review SLA tracked | ops/review-queue.md | ☐ |
| Capacity Planning | Scaling thresholds documented; peak-load tests completed; auto-scale policy reviewed quarterly | ops/capacity-plan.md | ☐ |
| Breach Notification Procedure | GDPR 72-hour notification runbook tested; APPI prompt notification procedure documented and drilled; contacts list current | ops/breach-runbook.md | ☐ |

---
## 日本語版
**アクティビティ5: Operate — 最低保証機能カタログ**
ITIL 5適用: Coordination（AI サービス統合）, Cognition（AI 推論実行）, Curation（運用資産管理）

Operateはデプロイ済みAIを安定・低コスト・規制準拠で動かす活動。運用エビデンスはObserve・監査の両方に供給される。

| 機能 | 合格基準 | 根拠ファイル | 状態 |
|-----|---------|------------|------|
| SLA監視 | 推論レイテンシP99 ≤ docs/sla.md定義値、違反時5分以内アラート | ops/sla-dashboard.json | ☐ |
| コスト追跡 | リクエスト単価をモデル版別に記録、月次予算差異≤10% | ops/cost-metrics.csv | ☐ |
| インシデント対応計画 | AI専用ランブック存在、MTTR目標定義、エスカレーション先にAIリスクオーナー含む | ops/ai-runbook.md | ☐ |
| データ品質監視 | 入力分布を学習ベースラインと日次比較、バッチごとに異常スコア記録 | ops/data-quality-log.csv | ☐ |
| EU第14条人間監視 | 高リスク判断の人間レビューキューが稼働、キュー深度とSLA追跡 | ops/review-queue.md | ☐ |
| キャパシティ計画 | スケーリング閾値文書化、ピーク負荷テスト完了、自動スケールポリシー四半期レビュー | ops/capacity-plan.md | ☐ |
| 漏洩通知手順 | GDPR72時間通知ランブックをテスト済み; 個人情報保護法の速やかな通知手順を文書化・訓練済み; 連絡先リストを最新化 | ops/breach-runbook.md | ☐ |
