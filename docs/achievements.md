# Quantified Results

**Period**: March 17 – May 29, 2026 (2.5 months)  
**Project**: Claude Code AI Harness Infrastructure (personal project)  
**Governance**: Lightweight alignment with ISO/IEC 20000 (ITSM) and ISO/IEC 27001 (Information Security)

---

## Cost Optimization

### Techniques Ranked by Impact

Each technique operates in a specific context. They are not additive — they target different overhead types.

| # | Technique | Effect | Context | Contribution to savings | Data source |
|---|-----------|--------|---------|------------------------|-------------|
| **1** | Subprocess flags `--setting-sources "" --tools ""` | **−99.3%** per call | Automated calls only | 99.7% of per-call dollar savings | Measured — see ① |
| **2** | SessionStart log compression | **−99.8%** context size | Interactive sessions | Eliminates 19MB → 36KB per session | Measured — see ② |
| **3** | RTK output compression | **−70% avg** content tokens | Both (tool output) | Measured: 37 days, 5,668 cmds | Measured — see ③ |
| **4** | LocalLLM routing (light/heavy) | **~70% of calls** at $0 | All calls | Shifts majority of calls off cloud billing | Usage estimate — see ④ |

**Why #1 and #2 look similar (both −99%) but are different things:**
- #1 reduces the system prompt loaded on every **automated subprocess call** (per-call cost)
- #2 reduces the context loaded at **session startup** (one-time per interactive session)
- They target completely separate overhead and compound independently

### Per-Call Waterfall: L5 → L6 → L7

For one automated subprocess call, all three layers apply in sequence:

```
Baseline (default claude -p):   166,000 tokens  $0.210/call
│
├─ L5: subprocess flags         →   1,100 tokens  $0.001   −99.3%  (measured ①)
│
├─ L6: RTK compression          →     330 tokens  $0.0003  −70%    (measured ③)
│
└─ L7: LocalLLM routing         →  effective $0.00009/call (70% routed to local)

Compound: ($0.210 − $0.00009) / $0.210 = −99.96%
```

**Which layer accounts for what share of the savings — and why they can't be compared directly:**

L5 saves $0.209 per call (strips 164,900 tokens of fixed system prompt overhead).
L6 saves $0.0007 per call on the *remaining* 1,100 tokens — but on a 50,000-token log file,
L6 would save 35,000 tokens, dwarfing L5's contribution in that context.
L7 does not reduce tokens — it shifts 70% of calls to $0 by routing to a local model.

**These three layers operate at different scales and cannot be meaningfully compared on one chart.**
Use the right tool for the right context:

| Technique | Primary use case | Apply when |
|-----------|-----------------|-----------|
| L5 subprocess flags | Automated scripted calls | Always — strips fixed overhead |
| L6 RTK compression | Large content (logs, diffs, test output) | Content > ~2,000 tokens |
| L7 LocalLLM routing | Any AI call | Always — route by task complexity |

The full 8-layer reference: [`docs/token-optimization-layers.md`](token-optimization-layers.md)

---

## KPI Summary

| Category | Metric | Value | Basis |
|----------|--------|-------|-------|
| **Cost** | Subprocess cost reduction (L5) | **−99.3%** | $0.21 → $0.001/call — see ① |
| **Cost** | SessionStart context size (L2) | **−99.8%** | 19 MB → 36 KB/session — see ② |
| **Cost** | RTK output compression (L6) | **−70% avg** | 37 days, 5,668 cmds — see ③ |
| **Cost** | L5+L6+L7 compound per call | **−99.96%** | $0.21 → ~$0.00009/call — see ④ |
| **Security** | Guardrail hooks implemented | **9** | PreToolUse × 7, PostToolUse × 1, SessionStart × 1 — see ⑤ |
| **Security** | Credential detection patterns | **14** | See `bash-secret-guard.sh` |
| **Security** | INC-011/012 recurrence after fix | **0** | Measured after hook deployment |
| **Incident mgmt** | Total incidents tracked | **13** | INC-001 – INC-013 |
| **Incident mgmt** | Permanently resolved via CIP | **6** | CIP-001 – CIP-006 |
| **Automation** | Scheduled agents running | **3** | retirement-countdown, job-digest-daily, weekly-itsm-review |
| **Automation** | Auto-rotation scripts | **4** | Daily, weekly ×2, quarterly |
| **Knowledge mgmt** | Memory files maintained | **25+** | 3-tier: short / mid / long-term |
| **Knowledge mgmt** | Log file size reduction | **−93%** | Daily digest automation |
| **Governance** | ITIL 5 lifecycle coverage | **8/8 activities** | `tools/itil5-ai-governance/` |
| **Governance** | Jurisdictions covered | **3 (JP/US/EU)** | `tools/itil5-ai-governance/phase-gate.sh` |
| **Governance** | TRiSM Privacy coverage | **40% → 75%** | Phase 6: pii-guard.sh + scrub_pii() + DPIA dashboard — see ⑦ |

---

## Calculation Basis

### ① Subprocess Flag Optimization (−99.3% per automated call)

When invoking `claude -p` from a script, Claude Code loads its full configuration
(CLAUDE.md, hook configs, MCP server definitions, memory files, all tool definitions)
into the system prompt on every call. For automated/scripted invocations this overhead
is pure waste.

**Root cause**: `--setting-sources` defaults to `user,project,local` (loads all config);
`--tools` defaults to all built-in tools (Bash, Read, Edit, Write, etc.).

**Fix**: two flags strip all overhead:

```bash
claude \
  -p "your prompt" \
  --setting-sources "" \   # disables CLAUDE.md, hooks, MCP, memory loading
  --tools ""               # disables all built-in tool definitions
```

**Measured benchmark** (Claude Code CLI 2.1.92, 2026-04-26):

| Configuration | Input tokens | Cost/call |
|--------------|-------------|-----------|
| Default `claude -p` | ~166,000 | $0.210 |
| `--setting-sources ""` only | ~20,000 | $0.025 |
| `--setting-sources "" --tools ""` | ~1,100 | **$0.001** |

Reduction: ($0.21 − $0.001) / $0.21 = **99.52%**

Real-world impact (100+ automated calls/day): **$630/month → $3/month**

**Security design note**: In a zero-trust pipeline, security operates at the content layer —
input scanning before the call, output validation after — independent of Claude Code flags.
This makes `--setting-sources ""` safe by architecture, not by assumption.
See [`docs/architecture.md`](architecture.md) Diagram 4. P-004 (resolved) — multi-layer injection defense implemented and verified with 23 tests.

> Reproducible: [`examples/cost-optimization/claude-subprocess.sh`](../examples/cost-optimization/claude-subprocess.sh) · [`claude-subprocess.js`](../examples/cost-optimization/claude-subprocess.js)  
> Measure your own baseline: [`examples/benchmark/measure-baseline.sh`](../examples/benchmark/measure-baseline.sh)

---

### ② SessionStart Context Reduction (−99.8% context size)

Optimized the set of files auto-loaded at every session start.

```
Before:
  AGENT-LOG.md        19.0 MB  (327 sessions of uncompressed logs)
  git diff output     25–35 KB
  Total               ≈ 19.03 MB / session

After:
  AGENT-LOG (daily digest)   12 KB
  MEMORY.md (index only)     24 KB
  Total                      ≈ 36 KB / session

Reduction: (19,030 − 36) / 19,030 = 99.81%
```

**How**: Daily log digest automation (`~/.claude/scripts/summarize-improvement-log.sh`)
compresses raw session logs into structured summaries on a scheduled basis.

> **Reproducibility**: The before/after measurement is real. The automation script
> has not yet been extracted as a standalone reproducible example — tracked in roadmap (Phase 7a).

---

### ③ RTK Output Compression (−70% daily average, measured)

[RTK (Rust Token Killer)](https://www.rtk-ai.app/) is a third-party Rust CLI tool that
filters and compresses text content before it reaches the LLM.

```bash
# Without RTK: full output passed to LLM
cat large-log.txt | claude -p "summarize errors"

# With RTK: compressed before LLM sees it
cat large-log.txt | rtk | claude -p "summarize errors"
```

**Measured compression — RTK Gain Monitor (Notion DB, auto-updated daily via launchd):**

| Metric | Value | Notes |
|--------|-------|-------|
| Token-weighted average | **98.7%** | Total saved / total input over 37 days |
| Simple daily average | **70%** | Mean of per-day compression ratios — the representative figure |
| Range | 2.8% – 100% | Highly content-dependent |
| P25 / P75 | 47% / 97% | — |
| Measurement period | 2026-04-11 – 2026-05-29 | 5,668 commands |

**The token-weighted (98.7%) and daily average (70%) differ this much because**:
RTK is most effective on large log files and test output (common in this project),
which dominate token volume. On short conversational prompts, compression is low.
**Use 70% as the conservative estimate** for general workloads.

> Install: `brew install rtk` · Implementation: [`examples/rtk-integration/`](../examples/rtk-integration/)

---

### ④ LocalLLM Routing — Compound Effect (L5+L6+L7)

LiteLLM Proxy routes calls by task complexity:

```
Simple tasks (summarize, classify, reformat) → local model (Gemma4, $0)
Complex tasks (design, architecture, debug)  → Claude API (pay-per-token)
```

Applied on top of L5 and L6, the three layers compound on a single automated call:

| After | Tokens | Cost | Reduction from baseline |
|-------|--------|------|------------------------|
| Baseline | 166,000 | $0.210 | — |
| L5 | 1,100 | $0.001 | −99.3% (measured) |
| L5 + L6 | ~330 | $0.0003 | −99.9% |
| L5 + L6 + L7 | effective | ~$0.00009 | −99.96% |

L7 routing estimate: ~70% of calls routed to local model based on observed light/heavy task mix.

> Full 8-layer reference: [`docs/token-optimization-layers.md`](token-optimization-layers.md)

---

### ⑤ Security Hook Inventory (9 hooks)
*ISO/IEC 27001: A.9 Access Control, A.12 Operations Security*

| Hook | Type | Purpose |
|------|------|---------|
| `bash-secret-guard.sh` | PreToolUse | Block credential leak patterns in Bash commands |
| `pre-commit-secrets.sh` | PreToolUse | Scan for credentials before git commit (gitleaks) |
| `mcp-config-guard.sh` | PreToolUse | Prevent unauthorized MCP config changes |
| `npm-install-guard.sh` | PreToolUse | Detect typosquatting attack patterns |
| `worktree-guard.sh` | PreToolUse | Block accidental writes to parent repository |
| `detect-rerebuke.sh` | PreToolUse | Detect repeated violations of the same rule |
| `pii-guard.sh` | PreToolUse | Block Bash commands containing real PII patterns |
| `audit-output.sh` | PostToolUse | Record audit log of tool outputs |
| `session-start-suggest-worktree.sh` | SessionStart | Suggest re-entering existing worktrees |

**Scope**: Active for interactive sessions only. Subprocess calls using `--setting-sources ""`
bypass all hooks by design. WikiBuilder no longer uses this flag (P-004, resolved — multi-layer content-layer defenses implemented instead).

---

### ⑥ ITIL 5 AI Governance Implementation

A complete ITIL 5-aligned AI product lifecycle governance tool implementing 4 core practices.

| ITIL 5 Practice | Implementation | Artifact |
|----------------|---------------|---------|
| Product/Service Lifecycle | Minimum Guaranteed Feature Catalog (8 activities × 5–7 features each) | `feature-gates/01-08` |
| AI Governance (6C) | Phase gate evaluation + EU AI Act risk tier classification | `phase-gate.sh` |
| Service Financial Management | 7-role RACI matrix + 7 outcome KPIs + financial escalation logic | `cost-template.md`, `generate-report.sh` |
| Change Enablement | Append-only JSON audit trail with sha256 tamper detection | `approvals.log` |

**Jurisdiction compliance matrix**:

| Jurisdiction | Standard | Approval Requirement |
|---|---|---|
| JP | 金融庁AIリスク管理ガイドライン | Director level |
| US | SR 11-7 (financial sector) | CRO / Independent Model Risk Officer |
| EU | EU AI Act Art.43 + Annex III | Third-party Conformity Assessment Body |

> Based on ITIL 5 preview spec (PeopleCert, 2026); will align to final release.

---

### ⑦ TRiSM Privacy Coverage (40% → 75%)

**Framework**: AI TRiSM (Gartner) — AI Trust, Risk, and Security Management

| Layer | Addition | Artifact |
|---|---|---|
| Technical detection | `scrub_pii()` in `audit.py` — regex-based PII redaction at display time | `tools/trustless_audit/src/audit.py` |
| Technical detection | `pii-guard.sh` — PreToolUse hook blocking PII patterns in Bash and Write | `examples/hooks/pii-guard.sh` |
| Policy dashboard | `PRIVACY.md` — DPIA tracker, consent registry, breach notification timing | LLM-Wiki `governance/PRIVACY.md` |
| Compliance docs | Cross-border transfer rules (GDPR Ch.V / APPI Art.24 / CCPA) | `tools/itil5-ai-governance/privacy-law-matrix.md` |

**Remaining 25% gap** — structural limits of a single-person project:

| Gap | Required for 100% |
|---|---|
| Real-time consent enforcement | Consent management DB checked before every AI inference |
| Pseudonymization engine | Reversible PII tokenization with key management |
| Right to erasure (Art.17) | Cascade deletion across audit logs + WORM storage — conflicts with tamper-evident design |

> The `scrub_pii()` function is display-time substitution only, not anonymization under GDPR/APPI/CCPA.
> Signed originals are preserved for accountability. This boundary is documented in `audit.py` and `privacy-law-matrix.md`.

---

---

## 日本語版

**期間**: 2026年3月17日〜5月29日（約2.5ヶ月）  
**プロジェクト**: Claude Code AIハーネス基盤構築（個人プロジェクト）  
**ガバナンス**: ISO/IEC 20000（ITSM）およびISO/IEC 27001（情報セキュリティ）の軽量版準拠

---

## コスト最適化

### 削減インパクト順の技術一覧

各技術は異なるオーバーヘッドを対象とする。単純に足し算できない（乗算で効果が合成される）。

| # | 技術 | 効果 | 適用コンテキスト | 削減への寄与 | データ根拠 |
|---|------|------|----------------|------------|----------|
| **1** | subprocessフラグ (`--setting-sources "" --tools ""`) | **−99.3%**/コール | 自動化コールのみ | コスト削減の99.7% | 実測 — ①参照 |
| **2** | SessionStart ログ圧縮 | **−99.8%** context | インタラクティブセッション | 19MB → 36KB/session | 実測 — ②参照 |
| **3** | RTK出力圧縮 | **−70% 日次平均** | ツール出力トークン | 37日・5,668コマンド実測 | 実測 — ③参照 |
| **4** | LocalLLMルーティング (light/heavy) | **約70%のコール**が$0 | 全コール | クラウド課金の大半をゼロ化 | 使用実績推定 — ④参照 |

**#1と#2がどちらも−99%台なのに別物な理由:**
- #1は**自動化subprocessコール**ごとのシステムプロンプト削減（1コール単位のコスト）
- #2は**セッション起動時**のコンテキスト削減（セッション開始の1回のみ）
- 対象が全く異なり、独立して効果が合成される

### 1コールのウォーターフォール: L5 → L6 → L7

```
ベースライン (デフォルト):    166,000 tokens  $0.210/コール
│
├─ L5: subprocessフラグ    →   1,100 tokens  $0.001   −99.3%  (実測①)
│
├─ L6: RTK圧縮             →     330 tokens  $0.0003  −70%    (実測③)
│
└─ L7: LocalLLMルーティング →  実効 $0.00009/コール (70%をローカルへ)

複合削減: ($0.210 − $0.00009) / $0.210 = −99.96%
```

**3技術はなぜ1枚の図で比較できないか:**

L5は1コールあたり$0.209を削減（166,000 tokenの固定オーバーヘッドを除去）。
L6は残余の1,100 tokenに適用すると$0.0007の削減だが、50,000 tokenのログを渡せばL5を上回る削減になる。
L7はトークンを削減しない — 課金先を変える（70%をローカルモデルへ）。

**3技術は適用スケールが根本的に異なる。同じ軸で比較することに意味はない。**

| 技術 | 何を圧縮するか | いつ使うか |
|------|--------------|-----------|
| L5 subprocessフラグ | 固定システムプロンプト | 自動化コール全てに適用 |
| L6 RTK圧縮 | コンテンツ（ログ・差分・大型出力） | コンテンツが〜2,000 token超の場合 |
| L7 LocalLLMルーティング | クラウド課金 | 常時 — タスク複雑度でルーティング |

8層最適化の全体リファレンス: [`docs/token-optimization-layers.md`](token-optimization-layers.md)

---

## KPI一覧

| カテゴリ | 指標 | 値 | 計算根拠 |
|---------|------|---|---------|
| **コスト** | subprocess削減率 (L5) | **−99.3%** | $0.21 → $0.001/コール — ①参照 |
| **コスト** | SessionStart context削減率 (L2) | **−99.8%** | 19 MB → 36 KB/session — ②参照 |
| **コスト** | RTK出力圧縮 (L6) | **−70% 日次平均** | 37日・5,668コマンド実測 — ③参照 |
| **コスト** | L5+L6+L7 複合削減 | **−99.96%** | $0.21 → ~$0.00009/コール — ④参照 |
| **セキュリティ** | ガードレールhook数 | **9種類** | PreToolUse×7・PostToolUse×1・SessionStart×1 — ⑤参照 |
| **セキュリティ** | Credential検出パターン | **14種類** | bash-secret-guard.sh参照 |
| **セキュリティ** | INC-011/012再発件数 | **0件** | hook導入後の実測値 |
| **障害管理** | 管理インシデント総数 | **13件** | INC-001〜INC-013 |
| **障害管理** | CIPによる恒久解消数 | **6件** | CIP-001〜CIP-006 |
| **自動化** | Scheduledエージェント | **3本** | retirement-countdown / job-digest-daily / weekly-itsm-review |
| **自動化** | 自動ローテーションスクリプト | **4本** | 日次・週次×2・季刊 |
| **知識管理** | メモリファイル数 | **25+件** | 短期/中期/長期の3層 |
| **知識管理** | AGENT-LOG削減率 | **−93%** | 日次ダイジェスト化による |
| **ガバナンス** | ITIL 5カバレッジ | **8/8アクティビティ** | `tools/itil5-ai-governance/` |
| **ガバナンス** | 対応管轄数 | **3管轄（JP/US/EU）** | `tools/itil5-ai-governance/phase-gate.sh` |
| **ガバナンス** | TRiSM Privacyカバレッジ | **40% → 75%** | Phase 6: pii-guard.sh + scrub_pii() + DPIAダッシュボード — ⑦参照 |

---

## 計算根拠

### ① subprocessフラグ最適化（−99.3%/コール）

`claude -p` をスクリプトから呼ぶと、デフォルトで `~/.claude/CLAUDE.md`・hook設定・MCPサーバー定義・memoryファイル・全ツール定義をsystem promptに読み込む。自動化用途ではすべて無駄なオーバーヘッド。

```bash
claude -p "prompt" \
  --setting-sources "" \   # CLAUDE.md・hooks・MCP・memory読込を無効化
  --tools ""               # 全ビルトインツール定義を無効化
```

**実測ベンチマーク**（Claude Code CLI 2.1.92、2026-04-26）:

| 設定 | 入力トークン | コスト/コール |
|-----|------------|------------|
| デフォルト `claude -p` | 約166,000 | $0.210 |
| `--setting-sources ""` のみ | 約20,000 | $0.025 |
| `--setting-sources "" --tools ""` | 約1,100 | **$0.001** |

実運用インパクト（100コール/日）: 月$630 → 月$3

**セキュリティ設計注記**: ゼロトラストパイプラインではセキュリティはコンテンツ層で機能する — Claude Codeのフラグとは独立した入力スキャン（呼び出し前）と出力検証（呼び出し後）。これにより `--setting-sources ""` は「信頼前提」ではなく「設計として安全」になる。詳細: [`docs/architecture.md`](../docs/architecture.md) Diagram 4。P-004（解決済み）— WikiBuilderは多層コンテンツ層防御を実装・23テスト検証済み。

> 再現可能: [`examples/cost-optimization/claude-subprocess.sh`](../examples/cost-optimization/claude-subprocess.sh)  
> 自分の環境での削減量測定: [`examples/benchmark/measure-baseline.sh`](../examples/benchmark/measure-baseline.sh)

---

### ② SessionStart context削減（−99.8%）

セッション起動時に自動読み込みされるファイル群の最適化。

```
Before: AGENT-LOG.md 19.0 MB（327セッション分の未圧縮ログ）≈ 19.03 MB/session
After:  AGENT-LOG（日次ダイジェスト）12 KB + MEMORY.md（インデックス）24 KB ≈ 36 KB/session
削減率: (19,030 - 36) / 19,030 = 99.81%
```

日次ダイジェスト自動化スクリプト（`~/.claude/scripts/summarize-improvement-log.sh`）で実現。
スクリプト自体はロードマップPhase 7aでポートフォリオに抽出予定。

---

### ③ RTK出力圧縮（日次平均−70%、実測値）

[RTK (Rust Token Killer)](https://www.rtk-ai.app/) はコンテンツをLLMに渡す前にパイプで圧縮するRust製CLIツール。

**実測データ — RTK Gain Monitor（Notion DB、launchdで毎日自動更新）:**

| 指標 | 値 | 備考 |
|-----|---|------|
| トークン加重平均 | **98.7%** | 37日間の総削減/総入力 |
| 単純日次平均 | **70%** | 日ごとの圧縮率の平均 — 代表的な推定値 |
| レンジ | 2.8% – 100% | コンテンツ依存性が高い |
| P25 / P75 | 47% / 97% | — |
| 計測期間 | 2026-04-11〜2026-05-29 | 5,668コマンド |

トークン加重(98.7%)と日次平均(70%)が乖離する理由: 大量ログファイルの処理日がトークン量を支配するため。**汎用的な推定には70%を使用すること。**

---

### ④ LocalLLMルーティング — L5+L6+L7複合効果

LiteLLM ProxyがタスクomplexityでLLMを切り替える:

```
単純タスク（要約・分類・変換） → ローカルモデル（Gemma4、コスト$0）
複雑タスク（設計・デバッグ・コードレビュー） → Claude API（従量課金）
```

L5・L6と積み重ねた複合削減:

| 適用後 | トークン | コスト | ベースラインからの削減 |
|--------|--------|------|-------------------|
| ベースライン | 166,000 | $0.210 | — |
| L5適用後 | 1,100 | $0.001 | −99.3%（実測） |
| L5+L6適用後 | ~330 | $0.0003 | −99.9% |
| L5+L6+L7適用後 | 実効 | ~$0.00009 | −99.96% |

---

### ⑤ セキュリティhook一覧（9種類）

| hook名 | 種別 | 目的 |
|--------|------|------|
| `bash-secret-guard.sh` | PreToolUse | Bashコマンド内のcredential漏洩パターンをブロック |
| `pre-commit-secrets.sh` | PreToolUse | git commit前のcredentialスキャン（gitleaks連携）|
| `mcp-config-guard.sh` | PreToolUse | MCP設定ファイルの無断変更を防止 |
| `npm-install-guard.sh` | PreToolUse | typosquatting攻撃パターンの検出 |
| `worktree-guard.sh` | PreToolUse | 親リポジトリへの誤った書込操作をブロック |
| `detect-rerebuke.sh` | PreToolUse | 同一ルール違反の繰り返し検出 |
| `pii-guard.sh` | PreToolUse | PII（個人情報）パターンを含む操作をブロック |
| `audit-output.sh` | PostToolUse | ツール出力の監査ログ記録 |
| `session-start-suggest-worktree.sh` | SessionStart | 既存worktreeへの再入を提案（誤作成防止）|

適用範囲: インタラクティブセッションのみ有効。`--setting-sources ""` を使うsubprocessコールでは hook が無効（設計上の意図）。WikiBuilderはこのフラグを廃止済み（P-004 解決済み）。

---

### ⑥ ITIL 5 AIガバナンス実装

| ITIL 5プラクティス | 実装内容 | 成果物 |
|-----------------|---------|-------|
| プロダクト/サービスライフサイクル | 8アクティビティ × 各5〜7機能の最低保証カタログ | `feature-gates/01-08` |
| AIガバナンス（6C） | フェーズゲート評価 + EU AI Actリスク階層判定 | `phase-gate.sh` |
| サービス財務管理 | 7ロールRACI + 7アウトカムKPI + 財務エスカレーション | `cost-template.md` |
| Change Enablement | sha256改ざん検知付きappend-only承認ログ | `approvals.log` |

管轄対応: JP（金融庁）・US（SR 11-7）・EU（AI Act Art.43）

---

### ⑦ TRiSM Privacy カバレッジ（40% → 75%）

| レイヤー | 追加内容 | 成果物 |
|---------|---------|-------|
| 技術的検知 | `scrub_pii()` — 表示時のPII正規表現マスキング | `tools/trustless_audit/src/audit.py` |
| 技術的検知 | `pii-guard.sh` — PreToolUse hookでPIIパターンをブロック | `examples/hooks/pii-guard.sh` |
| ポリシーダッシュボード | `PRIVACY.md` — DPIA追跡・同意管理・違反通知タイムライン | LLM-Wiki `governance/PRIVACY.md` |
| コンプライアンス文書 | クロスボーダー移転規定（GDPR/APPI/CCPA） | `privacy-law-matrix.md` |

残り25%のギャップは単独プロジェクトの構造的限界（リアルタイム同意管理・仮名化エンジン・忘れられる権利のWORMストレージ矛盾）。

> `scrub_pii()` は表示時置換のみでありGDPR/APPI/CCPA上の匿名化には該当しない。署名済み原本は監査証跡として保持される。
