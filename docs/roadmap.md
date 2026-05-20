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
| **Privacy law coverage (GDPR/APPI/CCPA)** | ✅ Complete | `tools/itil5-ai-governance/feature-gates/`, `privacy-law-matrix.md` |
| **Automated installation** | ✅ Complete | `install.sh` |
| **Role-based access control** | ✅ Complete | `tools/claude-config-manager/configs/`, `manage.sh` |
| **Automated onboarding pipeline** | ✅ Complete | `onboard.sh`, `generate-kb-list.sh`, `templates/` |

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

### Phase 3 — Privacy Law Coverage (GDPR / APPI / CCPA) ✅ Complete

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

### Phase 3 (cont.) — Automated Installation Script ✅ Complete

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

### Phase 3 (cont.) — Role-based Access Control ✅ Complete

**Gap filled**: `claude-config-manager` distributes behavioral specs (CLAUDE.md) but enforces no actual access control

Current state: role configs define *guidelines* only. Nothing in `settings.json` enforces which directories, tools, or commands each role can actually use.

**What will be added to `manage.sh install --role <role>`**:

| Control | Engineer | Analyst | Manager |
|---------|----------|---------|---------|
| `permissions.allow` (writable paths) | `src/`, `tests/` | read-only | read-only |
| `permissions.deny` (blocked commands) | `rm -rf`, `git push --force` | `git push *`, `Write`, `Edit` | `Bash(*)` |
| `additionalDirectories` (readable paths) | repo root | `docs/`, `reports/` | `docs/` |
| Role change requires admin approval | — | ✓ | ✓ |

**Implementation**:
- `manage.sh install` merges role-specific `permissions` block into `~/.claude/settings.json` (via `jq`, non-destructive)
- `manage.sh verify` checks `settings.json` permissions have not been manually overridden since install
- `manage.sh audit` logs who installed which role and when (append-only, sha256-signed)
- Role escalation (e.g., analyst → engineer) requires a second approver entry in the audit log

**Artifacts**: Updated `manage.sh`, new `configs/<role>-permissions.json` per role, updated `docs/deployment-playbook.md`

---

### Phase 3 (cont.) — Automated Onboarding Pipeline ✅ Complete

**Gap filled**: New user onboarding is a series of disconnected manual steps across multiple systems

Currently, adding a new team member requires an admin to manually create accounts, grant permissions, install hooks, and share documentation — across GitHub, 1Password, Claude Code, and any internal KB. Each step is a separate action with no audit trail connecting them.

**End-to-end pipeline triggered by a single command**:

```bash
./onboard.sh --user alice@example.com --role engineer --manager bob@example.com
```

| Step | What happens | Tool |
|------|-------------|------|
| **1. Account provisioning** | GitHub org invite + team assignment | GitHub API (`gh`) |
| **2. 1Password vault access** | Add user to shared vault (prompt admin to approve) | `op` CLI |
| **3. Hook + config install** | Run `install.sh --role <role>` on target machine via SSH or send install link | `install.sh` |
| **4. Access control apply** | Merge role-specific `permissions` into `settings.json` | `manage.sh install` |
| **5. Welcome email** | Send templated email with role, links, and KB pointers | SMTP / sendmail |
| **6. KB / manual sharing** | Generate role-specific reading list from `docs/` and attach to email | `generate-kb-list.sh` |
| **7. Audit log entry** | Record provisioning event (user, role, admin, timestamp, sha256) | append-only log |

**What cannot be automated** (requires human action):
- 1Password vault approval (security boundary — admin must confirm)
- Claude Code account creation (Anthropic console — no public API)
- SSH access to target machine (unless self-service install link is used)

**Design constraints**:
- No credentials stored in script — all secrets via `op run`
- Idempotent: re-running for existing user is a no-op with warning
- `--dry-run` flag previews all actions without executing
- Works without SSH: optionally generates a self-service install URL the new user runs themselves

**Artifacts**: `onboard.sh`, `templates/welcome-email.txt`, `generate-kb-list.sh`, updated `docs/deployment-playbook.md`

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
AI Deployment Playbook ✅ Multi-user CLAUDE.md ✅  Privacy Law Coverage ✅
                          Custom MCP Server ✅      install.sh ✅
                                                    Access Control ✅
                                                    Onboarding Pipeline ✅
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
| **各国個人情報保護法対応（GDPR/APPI/CCPA）** | ✅ 完了 | `feature-gates/01-05`, `privacy-law-matrix.md` |
| **インストール自動化** | ✅ 完了 | `install.sh` |
| **ロールベースアクセス制御** | ✅ 完了 | `configs/*-permissions.json`, `manage.sh` |
| **オンボーディング自動化パイプライン** | ✅ 完了 | `onboard.sh`, `generate-kb-list.sh`, `templates/` |

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

### Phase 3 — 各国個人情報保護法対応（GDPR / 個人情報保護法 / CCPA）✅ 完了

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

### Phase 3（続き）— インストール自動化スクリプト ✅ 完了

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

### Phase 3（続き）— ロールベースアクセス制御 ✅ 完了

**埋めるギャップ**: `claude-config-manager` は行動指示書（CLAUDE.md）を配布するだけで、実際のアクセス制御を強制していない

現状のロール設定はガイドラインの文書に過ぎず、`settings.json` の `permissions` によるディレクトリ・ツール・コマンドの実際の制限は存在しない。

**`manage.sh install --role <role>` に追加するアクセス制御**:

| 制御項目 | Engineer | Analyst | Manager |
|---------|----------|---------|---------|
| `permissions.allow`（書込可能パス）| `src/`, `tests/` | 読み取り専用 | 読み取り専用 |
| `permissions.deny`（ブロックコマンド）| `rm -rf`, force push | `git push *`, `Write`, `Edit` | `Bash(*)` |
| `additionalDirectories`（読取可能パス）| リポジトリルート | `docs/`, `reports/` | `docs/` |
| ロール変更時の承認要件 | — | 管理者承認必須 | 管理者承認必須 |

**実装方針**:
- `manage.sh install` がロール別 `permissions` ブロックを `~/.claude/settings.json` に `jq` マージ（既存設定を保持）
- `manage.sh verify` でインストール後の `settings.json` 改ざんを検知
- `manage.sh audit` でロール付与履歴をsha256署名付きappend-onlyログに記録
- ロール昇格（例: analyst → engineer）には第二承認者のログエントリが必要

**成果物**: `manage.sh` 更新、ロール別 `configs/<role>-permissions.json` 新規追加、`docs/deployment-playbook.md` 更新

---

### Phase 3（続き）— オンボーディング自動化パイプライン ✅ 完了

**埋めるギャップ**: 新規ユーザー追加時の作業が複数システムにまたがる手作業の連鎖になっている

現状はGitHub・1Password・Claude Code・社内KBそれぞれに対して管理者が個別に操作し、それらをつなぐ監査証跡も存在しない。

**1コマンドで一気通貫に実行されるパイプライン**:

```bash
./onboard.sh --user alice@example.com --role engineer --manager bob@example.com
```

| ステップ | 実行内容 | 手段 |
|---------|---------|------|
| **1. アカウントプロビジョニング** | GitHubオーガニゼーション招待 + チーム追加 | GitHub API (`gh`) |
| **2. 1Passwordボルトアクセス付与** | 共有ボルトへのユーザー追加（管理者承認をプロンプト） | `op` CLI |
| **3. hook + config インストール** | `install.sh --role <role>` をSSH経由またはセルフサービスリンクで実行 | `install.sh` |
| **4. アクセス制御適用** | ロール別 `permissions` を `settings.json` にマージ | `manage.sh install` |
| **5. ウェルカムメール送信** | ロール・リンク・KB参照先を含むテンプレートメール送信 | SMTP / sendmail |
| **6. KB・マニュアル共有** | `docs/` からロール別推奨ドキュメントリストを生成しメールに添付 | `generate-kb-list.sh` |
| **7. 監査ログ記録** | プロビジョニングイベント（ユーザー・ロール・管理者・日時・sha256）をログに追記 | append-only log |

**自動化できない作業**（人間・管理者が必要）:
- 1Passwordボルト承認（セキュリティ境界—管理者の確認必須）
- Claude Codeアカウント発行（Anthropicコンソール—公開APIなし）
- ターゲットマシンへのSSHアクセス（セルフサービスインストールリンクで代替可能）

**設計上の制約**:
- スクリプト内にcredentialを保持しない—すべて `op run` 経由
- 冪等性確保: 既存ユーザーへの再実行は警告を出してno-op
- `--dry-run` フラグで実行前に全アクションをプレビュー可能
- SSH不要モード: 新規ユーザー自身が実行するセルフサービスインストールURLを生成

**成果物**: `onboard.sh`、`templates/welcome-email.txt`、`generate-kb-list.sh`、`docs/deployment-playbook.md` 更新

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
