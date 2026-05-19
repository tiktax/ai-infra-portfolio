# AI Infrastructure / Harness Engineering Portfolio

**Period**: March – May 2026 (2 months, 50 commits) | Personal project

> 日本語版はページ末尾にあります。 / Japanese version is at the bottom of this page.

---

## What This Is

Most organizations adopt AI by giving employees access to a chat interface.
This project takes the opposite approach: **designing the infrastructure layer that makes AI safe, auditable, and cost-controlled before anyone uses it.**

Security policy enforcement, incident management, cost optimization, and audit traceability — built as a system, not bolted on afterward.

The result is a production-grade AI harness built end-to-end by one person, covering the same ground an enterprise IT/AI operations team would own.

---

## Governance Framework

A lightweight operational governance model aligned with **ISO/IEC 20000** (IT Service Management) and **ISO/IEC 27001** (Information Security Management) was adopted throughout — not as formal certification, but as a design discipline.

| Standard | Coverage in this project |
|----------|--------------------------|
| **ISO/IEC 20000** | Incident → Problem → Change cycle; continual improvement; service continuity |
| **ISO/IEC 27001** | Credential control (A.9); audit logging (A.12); security incident management (A.16); risk-based policy |

### Full Traceability & Audit Readiness

All governance artifacts are dual-tracked across **GitHub** and **Obsidian**, enabling complete traceability and monthly audit support:

| Layer | Tool | What is recorded |
|-------|------|-----------------|
| **Decision log** | GitHub Issues | Every incident (INC), problem (P), improvement proposal (CIP), and change (C) — immutable, timestamped |
| **Change history** | GitHub (git log) | All policy and config changes with author, date, and rationale in commit messages |
| **Knowledge base** | Obsidian (LLM-Wiki) | RCA findings, architectural decisions, lessons learned — searchable and cross-linked |
| **Audit trail** | GitHub Issues + git | Full INC→CIP→C traceability; monthly review against open incidents and SLO metrics |

**Risk assessment & scoring**: Each incident and improvement proposal is scored in Obsidian using a likelihood × impact matrix. Scores drive CIP prioritization and feed into the monthly audit review.

| Score | Likelihood | Impact | Action |
|-------|-----------|--------|--------|
| P0 (Critical) | High | High | Immediate remediation, block further work |
| P1 (High) | High or High | Medium or High | CIP within current cycle |
| P2 (Medium) | Medium | Medium | Scheduled CIP |
| P3 (Low) | Low | Any | Backlog |

**Monthly audit cycle**: Each month, open incidents, CIP status, SLO measurements, and risk scores are reviewed against the governance baseline — producing a closed-loop record suitable for internal audit or compliance review.

---

## Problems Solved

### 1. Security Governance
*Aligned with ISO/IEC 27001: A.9 Access Control, A.12 Operations Security, A.16 Incident Management*

**Problem**: Credential leak via AI tool output discovered in production (INC-011, INC-012)

**What I built**:
- 9 guardrail hooks (`PreToolUse` / `PostToolUse`) that intercept and block risky commands before execution
- AI behavioral policy document (ISO/IEC 27001-aligned), version-controlled in Git
- 1Password CLI integration — eliminated plaintext secrets from all config files
- gitleaks CI (GitHub Actions) scanning every push and pull request

**Result**: Zero recurrence after initial remediation

---

### 2. Cost Management & ROI

**Problem**: AI inference costs growing without visibility or control

**What I built**:
- Local LLM (Gemma4) / Cloud LLM (Claude API) auto-routing based on task complexity
- Optimized Claude Code CLI subprocess invocation

**Results**:

| Metric | Before | After | Reduction |
|--------|--------|-------|-----------|
| CLI call cost | $0.21/call | $0.001/call | **−99.5%** |
| SessionStart context size | 19 MB | 36 KB | **−99.8%** |
| Est. annual token usage | 33.2B tokens | 13.3M tokens | **−99.96%** |

> Calculation basis: [`docs/achievements.md`](docs/achievements.md)

---

### 3. Incident Management & Continuous Improvement
*Aligned with ISO/IEC 20000: Incident Management, Problem Management, Change Management, Continual Improvement*

**Problem**: AI system failures and policy violations were handled reactively with no permanent fixes

**What I built**:
- Full INC → Problem → CIP → Change cycle (ISO/IEC 20000-aligned)
- 13 incidents tracked from discovery through root cause analysis to permanent resolution
- SLO monitoring for context size and MCP connector count

**Result**: 6 permanent resolutions (CIP-001–006), improvement cycle now automated

---

### 4. Operations Automation
*Aligned with ISO/IEC 20000: Service Operation, Continual Service Improvement*

**Problem**: Repetitive tasks (information gathering, KPI reporting, procedure tracking) done manually

**What I built**:
- 3 scheduled agents (daily digest, weekly KPI review, weekly procedure tracking)
- API integration pipeline: Notion / GitHub / Telegram
- **LLM-Wiki**: implemented Karpathy's LLM-Wiki concept — an AI-maintained knowledge base that feeds back into the agent's context, introducing a PDCA cycle into knowledge management (Plan: index new learnings → Do: auto-sync to Obsidian → Check: surface relevant docs at session start → Act: refine via CIP)

---

### 5. Observability & Knowledge Management
*Aligned with ISO/IEC 27001: A.12 Operations Security; ISO/IEC 20000: Service Reporting*

**Problem**: AI session logs and incident records scattered across tools — hard to search or audit

**What I built**:
- 3-tier memory architecture (short-term session / mid-term project / long-term Obsidian)
- Daily log digest automation — 93% reduction in log file size
- Claude API usage monitoring tool (hard limit detection)

---

## Skills Demonstrated

| Domain | Evidence |
|--------|----------|
| **Security policy design** | 9 hooks, gitleaks CI, 1Password integration, zero-incident record |
| **ISO/IEC 27001 alignment** | Credential control, audit logging, incident response, risk-based policy |
| **ISO/IEC 20000 alignment** | INC→Problem→Change cycle, SLO monitoring, continual improvement |
| **Cost control & ROI analysis** | 99.5% cost reduction; documented calculation basis |
| **System integration** | Notion / GitHub / Telegram APIs; local + cloud LLM routing |
| **Observability** | SLO monitoring, 3-tier memory, log rotation automation |
| **Documentation & governance** | AI usage policy draft, version-controlled behavioral spec |
| **Automation** | 3 scheduled agents, CI/CD pipeline, shell hook system |

---

## 2-Month Timeline

```
March                April                May
│                    │                    │
▼                    ▼                    ▼
Notion/Telegram      Context optimization  ITSM improvement loop
API integrations     99.96% token cut      INC → CIP cycle
                     1Password migration   Git worktree guardrail
                     Security hook suite   Obsidian auto-sync
```

---

## Docs & Examples

| File | Contents |
|------|----------|
| [`docs/achievements.md`](docs/achievements.md) | Quantified results with calculation basis |
| [`docs/architecture.md`](docs/architecture.md) | System diagrams (Mermaid: hook flow, 5-layer stack, ITSM cycle) |
| [`docs/ai-usage-policy-draft.md`](docs/ai-usage-policy-draft.md) | AI usage policy draft (ISO/IEC 27001-aligned) |
| [`examples/hooks/`](examples/hooks/) | 4 security hook implementations (runnable) |
| [`examples/incidents/`](examples/incidents/) | Redacted incident records showing INC→RCA→CIP flow |
| [`tests/hooks/`](tests/hooks/) | Regression test suite for security hooks |
| [`demo.sh`](demo.sh) | One-command demo — verify hooks are working |
| [`docs/roadmap.md`](docs/roadmap.md) | Planned projects to scale from personal to organizational deployment |

---

## Tech Stack

- **AI agent**: Claude Code (Anthropic) + Claude API
- **Local LLM**: Gemma4 via LiteLLM Proxy
- **Security**: gitleaks / 1Password CLI / bash hooks
- **Integrations**: GitHub API / Notion API / Telegram Bot API
- **Automation**: cron / GitHub Actions / Shell scripts
- **Knowledge**: Obsidian / GitHub Issues

---

---

## 日本語版

> 以下は日本語での概要です。英語版と同等の内容を含みます。

**期間**: 2026年3〜5月（2ヶ月・50 commits）| 個人プロジェクト

多くの組織はAIの導入を「社員にチャット画面を与える」ことから始める。このプロジェクトはその逆のアプローチをとった——**誰かが使い始める前に、AIを安全・監査可能・コスト制御可能にするインフラ層を設計する**。

セキュリティポリシーの強制・インシデント管理・コスト最適化・監査証跡を、後付けではなくシステムとして設計・構築。エンタープライズのIT/AI運用チームが担うべき領域を、一人で一気通貫で実装しました。

---

### ガバナンスフレームワーク

**ISO/IEC 20000**（ITサービスマネジメント）および **ISO/IEC 27001**（情報セキュリティマネジメント）の軽量版に準拠した運用ガバナンスをプロジェクト全体に適用しました。正式認証取得ではなく、設計思想としての準拠です。

| 規格 | 本プロジェクトでの適用範囲 |
|------|--------------------------|
| **ISO/IEC 20000** | インシデント→問題→変更サイクル、継続的改善、サービス継続性 |
| **ISO/IEC 27001** | credential管理（A.9）、監査ログ（A.12）、セキュリティインシデント管理（A.16）、リスクベースポリシー |

### 完全トレーサビリティと月次監査対応

すべてのガバナンス成果物を **GitHub** と **Obsidian** でデュアルトラッキングし、完全なトレーサビリティと月次監査対応を実現しています。

| レイヤー | ツール | 記録内容 |
|---------|--------|---------|
| **意思決定ログ** | GitHub Issues | インシデント（INC）・問題（P）・改善提案（CIP）・変更（C）を不変タイムスタンプ付きで記録 |
| **変更履歴** | GitHub（git log）| ポリシー・設定変更を作成者・日時・理由とともにコミットメッセージで管理 |
| **知識ベース** | Obsidian（LLM-Wiki）| RCA結果・アーキテクチャ判断・教訓を検索可能・相互リンク形式で蓄積 |
| **監査証跡** | GitHub Issues + git | INC→CIP→Cの完全トレーサビリティ・月次でオープンインシデントとSLO指標をレビュー |

**リスク判定・スコアリング**: 各インシデントおよび改善提案をObsidianで発生可能性×影響度マトリクスによりスコアリング。スコアがCIPの優先度決定に反映され、月次監査レビューへフィードバックされる。

| スコア | 発生可能性 | 影響度 | 対応方針 |
|-------|-----------|--------|---------|
| P0（致命）| 高 | 高 | 即時対処・作業停止 |
| P1（高）| 高 or 高 | 中 or 高 | 当サイクル内でCIP |
| P2（中）| 中 | 中 | スケジュールCIP |
| P3（低）| 低 | 任意 | バックログ |

**月次監査サイクル**: 毎月、オープンインシデント・CIP進捗・SLO計測値・リスクスコアをガバナンスベースラインと照合し、内部監査またはコンプライアンスレビューに対応可能なクローズドループ記録を生成。

---

### 解いた問題と成果

**1. セキュリティガバナンス**（ISO/IEC 27001: A.9/A.12/A.16 準拠）

AI出力経由のcredential漏洩（INC-011/012）を発見・根本解消。PreToolUse/PostToolUse hookを9種実装し技術的に遮断。ISO/IEC 27001に沿ったポリシー文書をGit版管理。1Password CLI統合で秘密情報の直書きを根絶。再発ゼロを実現。

**2. コスト管理・ROI**

ローカルLLM（Gemma4）とクラウドLLM（Claude API）の自動ルーティングを設計。

| 指標 | Before | After | 削減率 |
|------|--------|-------|-------|
| CLI呼び出しコスト | $0.21/call | $0.001/call | **−99.5%** |
| SessionStartコンテキスト | 19 MB | 36 KB | **−99.8%** |
| 年間トークン消費（推定） | 33.2B tokens | 13.3M tokens | **−99.96%** |

> 計算根拠: [`docs/achievements.md`](docs/achievements.md)

**3. 障害管理・継続的改善**（ISO/IEC 20000 準拠）

INC→問題→CIP→変更のフルサイクルを実装。インシデント13件を体系管理し根本原因分析（RCA）を実施。6件を恒久解消（CIP-001〜006）。SLOモニタリングを自動化。

**4. 業務自動化**（ISO/IEC 20000: サービス運用・継続的改善）

Scheduledエージェント3本（日次情報収集・週次KPIレビュー・週次手続き管理）を実装。Notion/GitHub/Telegram APIを統合したパイプラインを構築。Karpathiが提唱するLLM-Wikiのコンセプトを実装し、AIが維持・更新する知識ベースをエージェントのコンテキストにフィードバックするPDCAサイクルを知識管理に導入（Plan: 新規学習のインデックス化 → Do: Obsidianへ自動同期 → Check: セッション起動時に関連ドキュメントを参照 → Act: CIPで改善）。

**5. 可観測性・知識管理**（ISO/IEC 27001: A.12; ISO/IEC 20000: サービスレポーティング）

3層メモリ構造（短期セッション/中期プロジェクト/長期Obsidian）を設計・実装。AGENT-LOG日次ダイジェスト化でログサイズ93%削減。Claude API使用制限モニタリングツールを実装。

---

### 発揮したスキル

| 領域 | 根拠 |
|-----|------|
| セキュリティポリシー策定 | hook 9種・gitleaks CI・1Password統合・再発ゼロの実績 |
| ISO/IEC 27001 準拠設計 | credential管理・監査ログ・インシデント対応・リスクベースポリシー |
| ISO/IEC 20000 準拠設計 | INC→問題→変更サイクル・SLOモニタリング・継続的改善 |
| コスト可視化・最適化 | 99.5%削減・計算根拠の文書化 |
| システム統合（API連携） | Notion/GitHub/Telegram・ローカル/クラウドLLMルーティング |
| 可観測性設計 | SLOモニタリング・3層メモリ・ログローテーション自動化 |
| ガバナンス文書化 | AI利活用ガイドライン草案・行動規範のバージョン管理 |
| 自動化設計 | Scheduledエージェント3本・CI/CDパイプライン・hookシステム |

---

### 2ヶ月の進化ロードマップ

```
3月                    4月                    5月
│                      │                      │
▼                      ▼                      ▼
Notion/Telegram        コンテキスト最適化        ITSM改善ループ
API連携実装            トークン99.96%削減        INC→CIPフロー
                       1Password移行            worktree安全弁
                       セキュリティhook群        Obsidian同期自動化
```

---

### ドキュメント

| ファイル | 内容 |
|---------|------|
| [`docs/achievements.md`](docs/achievements.md) | 定量実績・計算根拠 |
| [`docs/architecture.md`](docs/architecture.md) | システム構成図（Mermaid）|
| [`docs/ai-usage-policy-draft.md`](docs/ai-usage-policy-draft.md) | AI利活用ガイドライン草案 |
| [`docs/dashboard.md`](docs/dashboard.md) | 運用ダッシュボード（Mermaid 6グラフ）|
| [`docs/roadmap.md`](docs/roadmap.md) | 個人→組織展開へのスケールアップ計画 |
| [`examples/hooks/`](examples/hooks/) | セキュリティhookのサンプル実装 |

---

### 技術スタック

- **AIエージェント**: Claude Code (Anthropic) + Claude API
- **ローカルLLM**: Gemma4 via LiteLLM Proxy
- **セキュリティ**: gitleaks / 1Password CLI / bash hooks
- **統合**: GitHub API / Notion API / Telegram Bot API
- **自動化**: cron / GitHub Actions / Shell scripts
- **知識管理**: Obsidian / GitHub Issues
