# Activity 4: Deploy — Minimum Guaranteed Features
> **ITIL 5 Lifecycle Activity 4 of 8** | 6C Capabilities: Coordination, Communication, Creation
> Based on ITIL 5 preview spec (PeopleCert, 2026); will align to final release.

The Deploy activity transitions a validated AI system from a controlled build environment into live production. Deployment is the point of highest regulatory exposure; deficiencies here create direct liability under the EU AI Act, JP AI Guidelines, and US Executive Order 14110. Every feature below must be satisfied and evidenced before traffic is routed to the new system. Post-deployment, the Operate activity assumes responsibility for the running system.

| Feature | Success Criteria | Evidence File | Status |
|---------|-----------------|---------------|--------|
| Pre-deployment Approval | Human sign-off from authorized approver recorded with timestamp and rationale | approvals.log | ☐ |
| Conformity Check | EU AI Act Article 43 assessment completed if system is High-Risk; waiver documented if not applicable | docs/conformity.md | ☐ |
| Rollback Plan | Rollback procedure documented, tested in staging, and executable within defined RTO | docs/rollback.md | ☐ |
| Monitoring Setup | Inference metrics pipeline active; alerts configured for accuracy degradation and data drift | ops/monitoring-config.yaml | ☐ |
| EU Art.13 Transparency | User-facing disclosure notice in place; content reviewed by legal; version-controlled | docs/transparency-notice.md | ☐ |
| Jurisdiction Approval | JP, US, and EU specific regulatory approvals obtained as required; approval references logged | approvals.log | ☐ |
| Data Processing Agreement | DPA signed with all third-party data processors before go-live; GDPR Art.28 compliant; register maintained | docs/dpa-register.md | ☐ |

---
## 日本語版
**アクティビティ4: Deploy — 最低保証機能カタログ**
ITIL 5適用: Coordination（AIサービス調整）, Communication（AI-人間インタラクション）, Creation（AI能力構築）

Deployは規制上の露出が最も高いポイント。EU AI Act・JP AIガイドライン・米大統領令14110の下で直接的な責任が生じる。

| 機能 | 合格基準 | 根拠ファイル | 状態 |
|-----|---------|------------|------|
| デプロイ前承認 | 権限保有者のサインオフをタイムスタンプと理由付きで記録 | approvals.log | ☐ |
| 適合性チェック | 高リスクシステムはEU AI Act第43条アセスメント完了。非該当は免除理由を文書化 | docs/conformity.md | ☐ |
| ロールバック計画 | ステージング環境でテスト済み。定義済みRTO内で実行可能な手順を文書化 | docs/rollback.md | ☐ |
| モニタリング設定 | 推論メトリクスパイプライン稼働中。精度劣化・データドリフトのアラート設定済み | ops/monitoring-config.yaml | ☐ |
| EUアート.13透明性 | ユーザー向け開示通知を設置。法務レビュー済み・バージョン管理下 | docs/transparency-notice.md | ☐ |
| 管轄承認 | JP/US/EU 各管轄の規制承認を必要に応じて取得。承認参照番号をログに記録 | approvals.log | ☐ |
| データ処理委託契約（DPA） | 本番稼働前に全委託先とDPAに署名; GDPR第28条準拠; 委託先台帳を維持 | docs/dpa-register.md | ☐ |
