# Project Roadmap

## Vision

To evolve from a personal AI harness (one person, one environment) into a **deployable AI governance framework** that a team or organization can adopt — with documented change management, multi-user controls, and validated ROI.

---

## Current State (as of May 2026)

| Capability | Status |
|-----------|--------|
| Security policy enforcement (9 hooks) | ✅ Complete |
| Cost optimization (local/cloud LLM routing) | ✅ Complete |
| ITSM-aligned incident management (INC→CIP) | ✅ Complete |
| Audit trail (GitHub Issues + git) | ✅ Complete |
| Observability (SLO monitoring, log digest) | ✅ Complete |
| LLM-Wiki / PDCA knowledge cycle | ✅ Complete |
| **Team deployment** | 🔲 Not started |
| **Hook regression testing** | 🔲 Not started |
| **Multi-user access control** | 🔲 Not started |
| **ROI calculator (org scale)** | 🔲 Not started |
| **Custom MCP server** | 🔲 Not started |

---

## Planned Projects

### P1 — AI Deployment Playbook
**Gap addressed**: Team deployment, change management

A runbook for deploying this harness to a team of 10+. Covers CLAUDE.md distribution strategy, hook management across machines, onboarding procedures, and resistance mitigation.

**Why this matters**: The current system works for one person. This project proves it can scale to an organization — the critical gap between "personal project" and "enterprise-ready."

**Deliverables**:
- Deployment guide (step-by-step)
- CLAUDE.md versioning strategy for teams
- Onboarding checklist per role
- FAQ / resistance handling guide

---

### P1 — Hook Test Suite
**Gap addressed**: Testing, quality assurance

Automated regression tests for all 9 security hooks. Each hook gets test cases for: expected blocks, expected passes, edge cases, and bypass attempts.

**Why this matters**: Currently, hooks are validated manually. A test suite makes the system verifiable and trustworthy for external review.

**Deliverables**:
- Test runner (bash or Python)
- Test cases per hook (pass / block / edge)
- CI integration (runs on every hook change)
- Coverage report

---

### P2 — ROI Calculator
**Gap addressed**: Business case at organizational scale

A tool that takes org size, AI usage patterns, and security incident rates as input, and outputs projected cost savings and risk reduction.

**Why this matters**: The personal ROI is documented (99.5% cost reduction). The business case for a 50- or 500-person org needs a separate model — this is what a CIO or CFO would ask for.

**Deliverables**:
- Input: team size, monthly AI spend, incident rate
- Output: projected savings, payback period, risk score reduction
- Format: spreadsheet or simple web tool

---

### P2 — Multi-user CLAUDE.md Manager
**Gap addressed**: Access control, role-based AI behavior

A system for distributing and versioning role-specific CLAUDE.md files across a team. Different roles (engineer, analyst, manager) get different behavioral specs and permission levels.

**Why this matters**: Today, one CLAUDE.md governs all behavior. In an organization, an engineer should have different AI permissions than an executive assistant.

**Deliverables**:
- Role taxonomy (3–5 roles)
- Per-role CLAUDE.md templates
- Distribution mechanism (git-based or CLI)
- Audit log of who has which version

---

### P3 — Custom MCP Server
**Gap addressed**: MCP design and implementation experience

Build one custom MCP server that connects an internal tool (e.g., a ticketing system or internal knowledge base) to Claude Code.

**Why this matters**: Currently, only existing MCP servers are used. Building one demonstrates the ability to extend the platform, not just configure it.

**Deliverables**:
- One working MCP server (Node.js or Python / FastMCP)
- Tool definitions with proper schemas
- Documentation and example usage

---

## Timeline (Tentative)

```
Jun 2026        Jul 2026        Aug 2026        Sep 2026
│               │               │               │
▼               ▼               ▼               ▼
Hook Test Suite  AI Deployment   ROI Calculator  Multi-user
                 Playbook                        CLAUDE.md Mgr
                                                 Custom MCP
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
| セキュリティポリシー強制（9種hook）| ✅ 完了 |
| コスト最適化（ローカル/クラウドLLMルーティング）| ✅ 完了 |
| ITSM準拠インシデント管理（INC→CIP）| ✅ 完了 |
| 監査証跡（GitHub Issues + git）| ✅ 完了 |
| 可観測性（SLOモニタリング・ログダイジェスト）| ✅ 完了 |
| LLM-Wiki / PDCAナレッジサイクル | ✅ 完了 |
| **チーム展開** | 🔲 未着手 |
| **hookリグレッションテスト** | 🔲 未着手 |
| **マルチユーザーアクセス制御** | 🔲 未着手 |
| **ROI計算ツール（組織規模）** | 🔲 未着手 |
| **カスタムMCPサーバー** | 🔲 未着手 |

---

## 予定プロジェクト

### P1 — AI展開プレイブック
**埋めるギャップ**: チーム展開・変更管理

10名以上のチームへのハーネス展開Runbook。CLAUDE.md配布戦略・複数端末でのhook管理・オンボーディング手順・抵抗への対処法を含む。

**なぜ重要か**: 現状は一人用設計。このプロジェクトは「個人プロジェクト」から「エンタープライズ対応」への飛躍を証明する。

---

### P1 — hookテストスイート
**埋めるギャップ**: テスト・品質保証

9種全hookの自動リグレッションテスト。各hookに「期待されるブロック」「期待される通過」「エッジケース」「バイパス試行」のテストケースを整備。CI上で実行できる形にする。

**なぜ重要か**: 現状はhookの検証が手動。テストスイートにより外部レビューに耐えられるシステムになる。

---

### P2 — ROI計算ツール
**埋めるギャップ**: 組織規模でのビジネスケース

組織規模・AI利用パターン・セキュリティインシデント発生率を入力として、コスト削減効果とリスク低減を算出するツール。CIOやCFOが問う「投資対効果」に答えられる形式。

---

### P2 — マルチユーザーCLAUDE.mdマネージャー
**埋めるギャップ**: アクセス制御・ロールベースのAI行動制御

ロール別のCLAUDE.mdをチームに配布・バージョン管理するシステム。エンジニア・アナリスト・管理職でAIの権限と行動規範を分ける。

---

### P3 — カスタムMCPサーバー
**埋めるギャップ**: MCP設計・実装経験

社内ツール（チケットシステム・社内ナレッジベース等）をClaude Codeに接続するカスタムMCPサーバーを1本構築。「使うだけ」から「設計・実装できる」への証拠。
