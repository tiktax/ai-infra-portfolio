# AI Infrastructure / Harness Engineering Portfolio

**Period**: March – May 2026 (2 months, 50 commits) | Personal project

> 日本語版はページ末尾にあります。 / Japanese version is at the bottom of this page.

---

## What This Is

A solo project engineering the **control layer** around Claude Code (Anthropic's AI agent platform) — covering security policy, cost optimization, incident management, and automation.

This is the kind of infrastructure work an IT/AI operations team would own in an enterprise context, built end-to-end by one person.

---

## Problems Solved

### 1. Security Governance

**Problem**: Credential leak via AI tool output discovered in production (INC-011, INC-012)

**What I built**:
- 9 guardrail hooks (`PreToolUse` / `PostToolUse`) that intercept and block risky commands before execution
- AI behavioral policy document (ITSM §10 compliant), version-controlled in Git
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

### 3. Incident Management & Continuous Improvement (ITSM)

**Problem**: AI system failures and policy violations were handled reactively with no permanent fixes

**What I built**:
- Full INC → Problem → CIP → Change cycle (ITIL-aligned)
- 13 incidents tracked from discovery through root cause analysis to permanent resolution
- SLO monitoring for context size and MCP connector count

**Result**: 6 permanent resolutions (CIP-001–006), improvement cycle now automated

---

### 4. Operations Automation

**Problem**: Repetitive tasks (information gathering, KPI reporting, procedure tracking) done manually

**What I built**:
- 3 scheduled agents (daily digest, weekly KPI review, weekly procedure tracking)
- API integration pipeline: Notion / GitHub / Telegram
- WikiBuilder: automated knowledge base construction with Obsidian sync

---

### 5. Observability & Knowledge Management

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
| **Cost control & ROI analysis** | 99.5% cost reduction; documented calculation basis |
| **ITSM / incident management** | INC→CIP cycle, 13 incidents tracked, 6 permanently resolved |
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
| [`docs/ai-usage-policy-draft.md`](docs/ai-usage-policy-draft.md) | AI usage policy draft (personal project scope) |
| [`examples/hooks/`](examples/hooks/) | Sample security hook implementation |

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

> 以下は日本語での概要です。

**期間**: 2026年3〜5月（2ヶ月・50 commits）| 個人プロジェクト

Claude Code（Anthropic社製AIエージェント開発環境）の制御レイヤーを個人プロジェクトとして設計・構築。セキュリティポリシー・コスト管理・障害管理・自動化を一気通貫で実装しました。

### 主な成果

| 領域 | 実績 |
|-----|------|
| セキュリティ | credential漏洩インシデント（INC-011/012）を根本解消。hook9種・gitleaks CI導入後、再発ゼロ |
| コスト削減 | AI推論コスト99.5%削減（$0.21→$0.001/call）、年間トークン消費99.96%削減 |
| 障害管理 | ITSM準拠のINC→CIPフロー実装。13件を体系管理・6件を恒久解消 |
| 自動化 | Scheduledエージェント3本・Notion/GitHub/Telegram API連携 |
| 可観測性 | 3層メモリ設計・SLOモニタリング・ログ93%削減 |

### 発揮したスキル

セキュリティポリシー策定 / コスト可視化・最適化 / ITIL準拠障害管理 /
システム統合（API連携） / 自動化設計 / ガバナンス文書化
