# Project Roadmap

## Vision

To evolve from a personal AI harness (one person, one environment) into a **deployable AI governance framework** that a team or organization can adopt — with documented change management, multi-user controls, and validated ROI.

---

## Current State (as of May 2026)

| Capability | Status | Artifact |
|-----------|--------|----------|
| Security policy enforcement (9 hooks) | ✅ Complete | `examples/hooks/` |
| Cost optimization (local/cloud LLM routing) | ✅ Complete | `docs/achievements.md` |
| ITSM-aligned incident management (INC→CIP) | ✅ Complete | `examples/incidents/` |
| Audit trail (GitHub Issues + git) | ✅ Complete | `docs/ai-usage-policy-draft.md` |
| Observability (SLO monitoring, log digest) | ✅ Complete | `docs/dashboard.md` |
| LLM-Wiki / PDCA knowledge cycle | ✅ Complete | `docs/architecture.md` |
| **Hook regression testing** | ✅ Complete | `tests/hooks/` (38 test cases) |
| **Team deployment playbook** | ✅ Complete | `docs/deployment-playbook.md` |
| **ROI calculator (org scale)** | ✅ Complete | `tools/roi-calculator/` |
| **Multi-user access control** | ✅ Complete | `tools/claude-config-manager/` |
| **Custom MCP server** | ✅ Complete | `tools/governance-mcp/` |
| **ITIL 5 AI Governance Compliance Tool** | ✅ Complete | `tools/itil5-ai-governance/` |

---

### Phase 2 — ITIL 5 AI Governance Compliance Tool ✅ Complete

**Gap filled**: AI product lifecycle governance aligned to latest ITSM standard

Implements ITIL 5 (PeopleCert, 2026) — the first ITSM standard to mandate AI Governance:

- **8-activity lifecycle** (Discover → Design → Build → Deploy → Operate → Observe → Improve → Retire) — minimum guaranteed feature catalog per activity
- **AI Governance 6C Capability Model** — phase gate evaluation mapped to each capability
- **Multi-jurisdiction compliance** — JP (金融庁), US (SR 11-7※), EU (AI Act Art.43/Annex III)
- **Append-only audit trail** — human approval log with tamper-evident sha256 hashing
- **Financial governance** — 7-role RACI matrix + outcome-based KPI reporting

> ※ SR 11-7 applies to financial sector organizations

**Artifacts**: `phase-gate.sh`, `generate-report.sh`, `feature-gates/01-08`, `cost-template.md`, `approvals.log`

---

### Phase 3 — Privacy Law Coverage (GDPR / APPI / CCPA) 🔲 Planned

**Gap filled**: Personal data protection compliance across the full AI lifecycle

Current ITIL 5 tool covers data deletion at Retire phase only. This phase adds structured privacy law checkpoints to each of the 8 lifecycle activities:

| Activity | Addition |
|----------|---------|
| **01-discover** | DPIA trigger assessment (GDPR Art.35) / 要配慮個人情報分類 (APPI) / CCPA data category inventory |
| **02-design** | Privacy by Design (GDPR Art.25) / data minimization / purpose limitation |
| **03-build** | Pseudonymization / anonymization verification / CCPA-covered data identification |
| **04-deploy** | Third-party data sharing consent / DPA (Data Processing Agreement) check |
| **05-operate** | Breach notification procedure (GDPR 72h / APPI prompt notification) |

**Jurisdictions**: JP (個人情報保護法 / APPI) | EU (GDPR) | US (CCPA + sectoral)

**Artifacts**: Updates to `feature-gates/01-05.md`, addition of `privacy-law-matrix.md`

---

### Phase 3 (cont.) — Automated Installation Script 🔲 Planned

**Gap filled**: Organization-wide deployment of hooks and settings is currently fully manual

Current `docs/deployment-playbook.md` requires each team member to manually copy hook files, hand-edit `settings.json`, and update path references in `worktree-guard.sh`. At 10+ people this is error-prone and unscalable.

**`install.sh` — what it automates**:

| Step | Current (manual) | Automated |
|------|-----------------|-----------|
| Copy hooks + chmod | Per-machine copy | `cp` + `chmod +x` in one command |
| Register hooks in `settings.json` | Hand-edit JSON | `jq` merge (preserves existing config) |
| Set repo path in `worktree-guard.sh` | Edit source file | Prompted input or `--repo-path` arg |
| Pre-flight check (claude/bash/python3/git/op versions) | Read table, run manually | Auto-checked with pass/fail output |
| Verify installation | Run `demo.sh` manually | Auto-run at end of install |

**What cannot be automated** (requires human / admin action):
- GitHub repository access grant
- 1Password vault access grant
- Claude Code account provisioning

**Artifacts**: `install.sh` (new), updated `docs/deployment-playbook.md` Installation section

---

## Completed Projects

### P1 — AI Deployment Playbook ✅ Complete
**Gap addressed**: Team deployment, change management

A runbook for deploying this harness to a team of 10+. Covers CLAUDE.md distribution strategy, hook management across machines, onboarding procedures, and resistance mitigation.

**Artifact**: [`docs/deployment-playbook.md`](docs/deployment-playbook.md)

---

### P1 — Hook Test Suite ✅ Complete
**Gap addressed**: Testing, quality assurance

Automated regression tests for all 9 security hooks. Each hook gets test cases for: expected blocks, expected passes, edge cases, and bypass attempts.

**Artifact**: [`tests/hooks/`](tests/hooks/) — 38 test cases, CI-integrated

---

### P2 — ROI Calculator ✅ Complete
**Gap addressed**: Business case at organizational scale

A tool that takes org size, AI usage patterns, and security incident rates as input, and outputs projected cost savings and risk reduction.

**Artifact**: [`tools/roi-calculator/`](tools/roi-calculator/)

---

### P2 — Multi-user CLAUDE.md Manager ✅ Complete
**Gap addressed**: Access control, role-based AI behavior

A system for distributing and versioning role-specific CLAUDE.md files across a team. Different roles (engineer, analyst, manager) get different behavioral specs and permission levels.

**Artifact**: [`tools/claude-config-manager/`](tools/claude-config-manager/)

---

### P3 — Custom MCP Server ✅ Complete
**Gap addressed**: MCP design and implementation experience

Custom MCP server connecting governance data (hooks, role config, incidents, SLO metrics) to Claude Code.

**Artifact**: [`tools/governance-mcp/`](tools/governance-mcp/)

---

## Timeline (All Complete)

```
Mar–Apr 2026              May 2026                  May 2026
│                         │                         │
▼                         ▼                         ▼
Hook Test Suite ✅        ROI Calculator ✅         ITIL 5 AI Governance ✅
AI Deployment Playbook ✅ Multi-user CLAUDE.md ✅
                          Custom MCP Server ✅
```

---

---

## 日本語版

## ビジョン

個人用AIハーネス（一人・一環境）から、チームや組織が導入できる**デプロイ可能なAIガバナンスフレームワーク**へ進化させる。変更管理の文書化・マルチユーザー制御・検証済みROIを備えた状態を目指す。

---

## 現状（2026年5月時点）

| 機能 | 状態 |
|------|------|
| セキュリティポリシー強制（9種hook）| ✅ 完了 | `examples/hooks/` |
| コスト最適化（ローカル/クラウドLLMルーティング）| ✅ 完了 | `docs/achievements.md` |
| ITSM準拠インシデント管理（INC→CIP）| ✅ 完了 | `examples/incidents/` |
| 監査証跡（GitHub Issues + git）| ✅ 完了 | `docs/ai-usage-policy-draft.md` |
| 可観測性（SLOモニタリング・ログダイジェスト）| ✅ 完了 | `docs/dashboard.md` |
| LLM-Wiki / PDCAナレッジサイクル | ✅ 完了 | `docs/architecture.md` |
| **hookリグレッションテスト** | ✅ 完了 | `tests/hooks/`（38件）|
| **チーム展開プレイブック** | ✅ 完了 | `docs/deployment-playbook.md` |
| **ROI計算ツール（組織規模）** | ✅ 完了 | `tools/roi-calculator/` |
| **マルチユーザーアクセス制御** | ✅ 完了 | `tools/claude-config-manager/` |
| **カスタムMCPサーバー** | ✅ 完了 | `tools/governance-mcp/` |
| **ITIL 5 AIガバナンス準拠ツール** | ✅ 完了 | `tools/itil5-ai-governance/` |

---

### Phase 2 — ITIL 5 AIガバナンス準拠ツール ✅ 完了

**埋めるギャップ**: 最新ITSMフレームワーク準拠のAIプロダクトライフサイクルガバナンス

ITIL 5（2026年PeopleCert）は、ITSMとしてAI Governanceを初めて必須要件とした。

- **8アクティビティライフサイクル**: 各フェーズの最低保証機能カタログ
- **6C Capability Model**: 各能力軸への評価マッピング
- **多管轄対応**: JP・US・EU の高リスクAI承認フロー
- **改ざん検知**: sha256ハッシュ付きappend-only承認ログ
- **財務ガバナンス**: 7ロールRACIマトリクス + アウトカムKPIレポート

---

### Phase 3 — 各国個人情報保護法対応（GDPR / 個人情報保護法 / CCPA）🔲 予定

**埋めるギャップ**: AIライフサイクル全フェーズへのプライバシー法準拠チェックポイント追加

現在のITIL 5ツールはRetireフェーズのデータ削除（GDPR Art.17 / 個人情報保護法）のみ対応。本フェーズで8アクティビティ全体に構造的なプライバシー法チェックを追加する。

| アクティビティ | 追加内容 |
|------------|--------|
| **01-discover** | DPIAトリガー評価（GDPR Art.35）/ 要配慮個人情報分類（個人情報保護法）/ CCPAデータカテゴリ棚卸し |
| **02-design** | Privacy by Design（GDPR Art.25）/ データ最小化 / 目的外利用禁止設計 |
| **03-build** | 仮名化・匿名化の実施確認 / CCPA対象データの識別 |
| **04-deploy** | 第三者提供同意確認 / DPA（データ処理委託契約）チェック |
| **05-operate** | 漏洩時通知手順（GDPR 72時間 / 個人情報保護法 速やかに） |

**対応管轄**: JP（個人情報保護法 / APPI）| EU（GDPR）| US（CCPA + セクトラル法）

**成果物**: `feature-gates/01-05.md` 更新 + `privacy-law-matrix.md` 新規追加

---

### Phase 3（続き）— インストール自動化スクリプト 🔲 予定

**埋めるギャップ**: 組織展開時のhook・設定登録がすべて手作業

現状の `docs/deployment-playbook.md` では、hook ファイルのコピー・`settings.json` の手編集・`worktree-guard.sh` のパス書き換えを各自で実施する必要がある。10名以上では手順ミスが発生しやすくスケールしない。

**`install.sh` が自動化する作業**:

| 手順 | 現状（手動） | 自動化後 |
|-----|-----------|--------|
| hookコピー + 実行権限付与 | 各自で実施 | 1コマンドで完結 |
| `settings.json` へのhook登録 | JSON手編集（構文ミスリスク） | `jq` マージ（既存設定を保持） |
| `worktree-guard.sh` のリポパス設定 | ファイル直接編集 | 対話入力 or `--repo-path` 引数 |
| 前提ツールのバージョン確認 | 表を見て手動実行 | 自動チェック + 合否表示 |
| インストール後の動作確認 | `demo.sh` を手動実行 | インストール完了時に自動実行 |

**自動化できない作業**（管理者・人間が必要）:
- GitHubリポジトリのアクセス権付与
- 1Passwordボルトのアクセス権付与
- Claude Codeアカウントの発行

**成果物**: `install.sh`（新規）、`docs/deployment-playbook.md` Installation セクション更新

---

## 完了済みプロジェクト

### P1 — AI展開プレイブック ✅ 完了
**埋めるギャップ**: チーム展開・変更管理

10名以上のチームへのハーネス展開Runbook。CLAUDE.md配布戦略・複数端末でのhook管理・オンボーディング手順・抵抗への対処法を含む。

**成果物**: [`docs/deployment-playbook.md`](docs/deployment-playbook.md)

---

### P1 — hookテストスイート ✅ 完了
**埋めるギャップ**: テスト・品質保証

9種全hookの自動リグレッションテスト（38件）。CI統合済み。

**成果物**: [`tests/hooks/`](tests/hooks/)

---

### P2 — ROI計算ツール ✅ 完了
**埋めるギャップ**: 組織規模でのビジネスケース

組織規模・AI利用パターン・セキュリティインシデント発生率を入力として、コスト削減効果とリスク低減を算出するツール。

**成果物**: [`tools/roi-calculator/`](tools/roi-calculator/)

---

### P2 — マルチユーザーCLAUDE.mdマネージャー ✅ 完了
**埋めるギャップ**: アクセス制御・ロールベースのAI行動制御

ロール別のCLAUDE.mdをチームに配布・バージョン管理するシステム。

**成果物**: [`tools/claude-config-manager/`](tools/claude-config-manager/)

---

### P3 — カスタムMCPサーバー ✅ 完了
**埋めるギャップ**: MCP設計・実装経験

ガバナンスデータ（hook・ロール設定・インシデント・SLOメトリクス）をClaude Codeに接続するカスタムMCPサーバー。

**成果物**: [`tools/governance-mcp/`](tools/governance-mcp/)
