# Activity 8: Retire — Minimum Guaranteed Features
> **ITIL 5 Lifecycle Activity 8 of 8** | 6C Capabilities: Coordination, Curation
> Based on ITIL 5 preview spec (PeopleCert, 2026); will align to final release.

The Retire activity is the most compliance-critical and most frequently neglected phase of the AI lifecycle. Decommissioning an AI system without a structured procedure leaves regulatory exposure open indefinitely: PII may remain in storage beyond legal retention limits, model endpoints may persist and be exploitable, and successor teams inherit undocumented technical debt. ITIL 5 treats Retire as a first-class activity requiring human sign-off, audit archiving, and — where applicable — regulatory notification to supervisory authorities. Completing Retire cleanly is the only way to formally close an AI system's risk profile.

| Feature | Success Criteria | Evidence File | Status |
|---------|-----------------|---------------|--------|
| Data Deletion Plan | PII deletion procedure documented per GDPR Art.17 and Japan Act on Protection of Personal Information; deletion completion confirmed with data owner signature | docs/data-deletion.md | ☐ |
| Model Decommission Checklist | All inference endpoints shut down and verified offline; model artifacts removed from serving infrastructure; checklist signed by MLOps Engineer | docs/decommission.md | ☐ |
| Audit Archive | Operational logs archived for required retention period (minimum 5 years for financial sector; jurisdiction-specific); archive integrity verified with checksum | archive/audit-archive.md | ☐ |
| Successor Handoff | Knowledge transfer document covers model design decisions, known failure modes, and lessons learned; signed by both outgoing and incoming responsible parties | docs/handoff.md | ☐ |
| Retirement Approval | Human sign-off recorded in approvals.log with approver identity, date, jurisdiction, and required approval level | approvals.log | ☐ |
| Regulatory Notification | JP Personal Information Protection Commission and/or EU supervisory authority notified where required; notification sent within prescribed deadline | docs/regulatory-notification.md | ☐ |

---
## 日本語版
**アクティビティ8: Retire — 最低保証機能カタログ**
ITIL 5適用: Coordination（退役プロセス統制）, Curation（アーカイブ・知識継承管理）

Retireは最も法的リスクが高く最も省略されやすいフェーズ。構造的な廃止手順なしでは個人情報の保持期限超過・未閉鎖エンドポイント・文書化されていない技術的負債が残存する。ITIL 5はRetireを正式なアクティビティとして、人間承認・監査アーカイブ・規制当局通知を必須とする。

| 機能 | 合格基準 | 根拠ファイル | 状態 |
|-----|---------|------------|------|
| データ削除計画 | GDPR第17条および個人情報保護法に基づくPII削除手順を文書化、完了をデータオーナーが署名確認 | docs/data-deletion.md | ☐ |
| モデル廃止チェックリスト | 全推論エンドポイントのオフライン確認、提供基盤からのモデル成果物削除、MLOpsエンジニアが署名 | docs/decommission.md | ☐ |
| 監査アーカイブ | 法定保持期間（金融セクター最低5年、管轄依存）の運用ログアーカイブ、チェックサムで完全性検証 | archive/audit-archive.md | ☐ |
| 後任引継ぎ | 設計決定・既知の故障モード・教訓を含む引継ぎ文書を前任者と後任者が共同署名 | docs/handoff.md | ☐ |
| 退役承認 | 承認者・日時・管轄・必要承認レベルを含む人間の承認をapprovals.logに記録 | approvals.log | ☐ |
| 規制当局通知 | 必要に応じ個人情報保護委員会またはEU監督機関へ規定期限内に通知 | docs/regulatory-notification.md | ☐ |
