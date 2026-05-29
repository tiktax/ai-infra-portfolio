# Quantified Results

**Period**: March 17 – May 17, 2026 (2 months)
**Project**: Claude Code AI Harness Infrastructure (personal project)
**Governance**: Lightweight alignment with ISO/IEC 20000 (ITSM) and ISO/IEC 27001 (Information Security)

---

## KPI Summary

| Category | Metric | Value | Basis |
|----------|--------|-------|-------|
| **Cost** | CLI subprocess cost reduction (L5) | **−99.5%** | $0.21 → $0.001/call (see ①) — hooks disabled |
| **Cost** | RTK output compression (L6) | **−70% avg** | Daily avg over 37 days, 5,668 cmds (see ⑦) — RTK Gain Monitor |
| **Cost** | SessionStart context size reduction | **−99.8%** | 19 MB → 36 KB/session (see ②) |
| **Cost** | L5+L6+L7 compound per call | **−99.97%** | Waterfall: $0.21 → ~$0.00006/call (see ③) |
| **Security** | Guardrail hooks implemented | **9** | (see ④) — 対話セッションのみ有効 |
| **Security** | Credential detection patterns | **14** | See `bash-secret-guard.sh` |
| **Security** | INC-011/012 recurrence after fix | **0** | Measured after hook deployment |
| **Incident mgmt** | Total incidents tracked | **13** | INC-001 – INC-013 (INC-015 除く) |
| **Incident mgmt** | Permanently resolved via CIP | **6** | CIP-001 – CIP-006 |
| **Automation** | Scheduled agents running | **要確認** | cron登録数と不一致 (INC-015) |
| **Automation** | Auto-rotation scripts | **4** | Daily, weekly ×2, quarterly |
| **Knowledge mgmt** | Memory files maintained | **25+** | 3-tier: short / mid / long-term |
| **Knowledge mgmt** | Log file size reduction | **−93%** | Daily digest automation |
| **Governance** | ITIL 5 compliance coverage | **8/8 lifecycle activities** | `tools/itil5-ai-governance/` |
| **Governance** | Jurisdictions covered | **3 (JP/US/EU)** | `tools/itil5-ai-governance/phase-gate.sh` |
| **Governance** | TRiSM Privacy coverage | **40% → 75%** | Phase 6: pii-guard.sh + scrub_pii() + DPIA dashboard + cross-border docs (see ⑥) |

---

## Calculation Basis

### ① CLI Subprocess Cost Reduction (−99.5%)

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

```
Reduction: ($0.21 - $0.001) / $0.21 = 99.52%
```

**Real-world impact** (100+ automated calls/day): $630/month → $3/month

> **Reproducible implementation**: [`examples/cost-optimization/claude-subprocess.js`](../examples/cost-optimization/claude-subprocess.js)
> (Node.js) and [`claude-subprocess.sh`](../examples/cost-optimization/claude-subprocess.sh) (bash)
>
> Note: `--bare` is NOT a valid alternative — it bypasses OAuth authentication.
> `--setting-sources "" --tools ""` preserves OAuth while eliminating token overhead.

### ② SessionStart Context Reduction (−99.8%)

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

Reduction: (19,030 - 36) / 19,030 = 99.81%
```

**How this was achieved**: Daily log digest automation compresses raw session logs
into structured summaries on a scheduled basis. The digest script lives in the
harness runtime (`~/.claude/scripts/summarize-improvement-log.sh`) and has not
yet been extracted as a standalone reproducible example in this repository.

> **Reproducibility status**: The before/after measurement is real.
> The automation script is not yet published here — extracting it as a reusable
> example is tracked in the roadmap (Phase 7a).

### ③ Per-Call Compound Reduction: L5 + L6 + L7 (−99.97%)

Each layer applies to what remains after the previous one — multiplicative, not additive.

```
Waterfall for one automated subprocess call:

  Baseline (default claude -p):        166,000 tokens    $0.210/call
  │
  ├─ L5: --setting-sources "" --tools ""
  │       strips CLAUDE.md + hooks + MCP + tools
  │       result: 1,100 tokens         $0.001/call     −99.3%  (measured ①)
  │
  ├─ L6: RTK output compression
  │       compresses content before LLM sees it
  │       result: 110–440 tokens       $0.0001–0.0004  −60–90% (RTK vendor ⑦)
  │
  └─ L7: LocalLLM routing
          70% of calls routed to local model at $0
          effective: ~$0.00003–0.00012 × 0.3           (usage-based estimate)

  Combined effective cost: ~$0.00006/call
  Compound reduction: ($0.210 − $0.00006) / $0.210 ≈ 99.97%
```

**What each layer targets**:

| Layer | Overhead type | Reduction basis |
|-------|--------------|----------------|
| L5 | System prompt bloat (config, tools, MCP, memory) | Measured benchmark, 2026-04-26 |
| L6 | Content/output token volume | RTK vendor-stated range; actual ratio varies by content type |
| L7 | Cloud API cost vs local | Estimated from light/heavy task distribution |

**Observed historical data** (context, not controlled comparison):
Before interventions, session startup loaded 19MB of logs (~3.79M tokens).
After SessionStart optimization (②), startup fell to 36KB (~9K tokens).
Current measured annual run rate: ~13.3M tokens/year.
Pre-intervention trajectory (if log bloat had continued): ~33.2B tokens/year.
These are not compared as a controlled before/after — the pre-intervention state
was unsustainable by design, not a stable operating baseline.

> See [`docs/token-optimization-layers.md`](token-optimization-layers.md) for
> the full 8-layer reference with interactive session optimizations (L1–L4, L8).

### ④ Security Hook Inventory (9 hooks)
*ISO/IEC 27001 alignment: A.9 Access Control, A.12 Operations Security*

| Hook | Type | Purpose |
|------|------|---------|
| `bash-secret-guard.sh` | PreToolUse | Block credential leak patterns in Bash commands |
| `pre-commit-secrets.sh` | PreToolUse | Scan for credentials before git commit (gitleaks) |
| `mcp-config-guard.sh` | PreToolUse | Prevent unauthorized MCP config changes |
| `npm-install-guard.sh` | PreToolUse | Detect typosquatting attack patterns |
| `worktree-guard.sh` | PreToolUse | Block accidental writes to parent repository |
| `detect-rerebuke.sh` | PreToolUse | Detect repeated violations of the same rule |
| `audit-output.sh` | PostToolUse | Record audit log of tool outputs |
| `session-start-suggest-worktree.sh` | SessionStart | Suggest re-entering existing worktrees (prevent duplicates) |
| `load-feedback-rules.sh` | SessionStart | Auto-load feedback rules at session start |

---

## ⑤ ITIL 5 AI Governance Implementation

**What was built**: A complete ITIL 5-aligned AI product lifecycle governance tool implementing 4 core ITIL 5 practices.

| ITIL 5 Practice | Implementation | Artifact |
|----------------|---------------|---------|
| Product/Service Lifecycle | Minimum Guaranteed Feature Catalog (8 activities × 5-7 features each) | `feature-gates/01-08` |
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

## ⑥ TRiSM Privacy Coverage (40% → 75%)

**Framework**: AI TRiSM (Gartner) — AI Trust, Risk, and Security Management

TRiSM defines six capability areas. Privacy is one of the weakest in most AI deployments.

### Before Phase 6 (40%)

All privacy coverage was policy-layer only:
- `privacy-law-matrix.md`: GDPR/APPI/CCPA mapped to ITIL 5 lifecycle activities
- `feature-gates/01-05`: DPIA trigger and consent checklist items (manual, no tooling)
- No technical enforcement of any kind

### After Phase 6 (75%)

| Layer | Addition | Artifact |
|---|---|---|
| Technical detection | `scrub_pii()` in `audit.py` — regex-based PII redaction at display time (email, JP phone, My Number, card) | `tools/trustless_audit/src/audit.py` |
| Technical detection | `pii-guard.sh` — PreToolUse hook blocking Bash commands and Write content containing real PII patterns | `examples/hooks/pii-guard.sh` |
| Policy dashboard | `PRIVACY.md` — DPIA tracker, consent registry, breach notification timing (GDPR 72h / JP / CCPA) | LLM-Wiki `governance/PRIVACY.md` |
| Compliance docs | Cross-border transfer rules (GDPR Ch.V / APPI Art.24 / CCPA) + anonymization standards comparison | `tools/itil5-ai-governance/privacy-law-matrix.md` |

### Why not 100%

The remaining 25% gap is structural — out of scope for a single-person project:

| Gap | Required for 100% | Assessment |
|---|---|---|
| Real-time consent enforcement | Consent management DB checked before every AI inference | Separate project-scale infrastructure |
| Pseudonymization engine | Reversible PII tokenization with key management | New data pipeline component |
| Right to erasure (Art.17) | Cascade deletion across audit logs + WORM storage | Conflicts with tamper-evident design |

> The `scrub_pii()` function explicitly does **not** constitute anonymization under GDPR, APPI, or CCPA — it is display-time substitution only. Signed originals are preserved for accountability. This boundary is documented in both `audit.py` docstrings and `privacy-law-matrix.md §Anonymization Standards`.

---

## ⑦ RTK Output Compression (measured: ~70% daily avg, 98.7% token-weighted)

[RTK (Rust Token Killer)](https://www.rtk-ai.app/) is a third-party Rust-based CLI tool
that filters and compresses text content before it is passed to an LLM.
This project uses RTK as an integration in the optimization stack (Layer 6 of 8).

**How RTK works**: pipe-based filter applied to tool output, log files, diffs,
and other large text before it enters the prompt.

```bash
# Without RTK
cat large-log.txt | claude -p "summarize errors"         # e.g. 50,000 tokens

# With RTK (L6)
cat large-log.txt | rtk | claude -p "summarize errors"   # e.g. 5,000–20,000 tokens
```

**Install**: `brew install rtk`

**Measured compression (RTK Gain Monitor — auto-recorded Notion DB)**:

| Metric | Value | Basis |
|--------|-------|-------|
| Token-weighted average | **98.7%** | Total saved / total input across 37 days |
| Simple daily average | **70%** | Mean of per-day compression ratios |
| Range | 2.8% – 100% | Highly content-dependent |
| P25 / P75 | 47% / 97% | Half of days fall above 97% or below 47% |
| Days ≥90% compression | 13 / 37 (35%) | Large log/file processing sessions |
| Days <50% compression | 10 / 37 (27%) | Interactive/conversational sessions |
| Measurement period | 2026-04-11 – 2026-05-29 | 5,668 commands, auto-recorded |

**Why the wide variance**: RTK is most effective on high-volume, repetitive content
(large log files, test output, directory trees). On short or already-dense content
(JSON, structured queries, brief prompts), compression is minimal or not applied.

**The token-weighted figure (98.7%) is real but not representative of a typical session.**
The simple daily average (70%) is the better estimate for daily expected compression.

**Position in stack**: RTK addresses content token volume; the subprocess flags (①)
address system prompt overhead. They are complementary and applied in sequence.

> Data source: RTK Gain Monitor (Notion DB, auto-updated daily via launchd)  
> Implementation: [`examples/rtk-integration/`](../examples/rtk-integration/)

---

---

## 日本語版

**期間**: 2026年3月17日〜5月17日（2ヶ月）
**プロジェクト**: Claude Code AIハーネス基盤構築（個人プロジェクト）
**ガバナンス**: ISO/IEC 20000（ITSM）およびISO/IEC 27001（情報セキュリティ）の軽量版準拠

---

### ⚠️ 既知の問題 (INC-015, 2026-05-24)

このドキュメントには以下の不正確な記述が含まれています。修正中です。

1. **セキュリティとコスト最適化の設計矛盾**: コスト最適化フラグはセキュリティフック9種を完全に迂回する。
2. **定期エージェント稼働数の誤記**: cronの実登録数と不一致。
3. **WikiBuilderが本番でフックを迂回中**: 本番環境でフックが無効な状態で稼働している。

> 詳細: INC-015（解決済み）/ P-004（登録済み、対策中）— [PROBLEMS.md](../../../../governance/PROBLEMS.md)

---

### KPI一覧

| カテゴリ | 指標 | 値 | 計算根拠 |
|---------|------|---|---------|
| **コスト** | CLI subprocess コスト削減率 | **−99.5%** | $0.21 → $0.001/call（後述①）— フック無効時のみ成立 |
| **コスト** | SessionStart context削減率 | **−99.8%** | 19 MB → 36 KB/session（後述②） |
| **コスト** | 年間トークン消費削減（推定） | **−99.96%** | 33.2B → 13.3M tokens/年（後述③）— worst-case比較 |
| **セキュリティ** | 実装したセキュリティhook数 | **9種類** | （後述④）— 対話セッションのみ有効 |
| **セキュリティ** | Credential検出パターン数 | **14種類** | bash-secret-guard.sh参照 |
| **セキュリティ** | INC-011/012再発件数 | **0件** | hook導入後の実測値 |
| **障害管理** | 管理インシデント総数 | **13件** | INC-001〜INC-013（INC-015除く） |
| **障害管理** | CIPによる恒久解消数 | **6件** | CIP-001〜CIP-006 |
| **自動化** | Scheduledエージェント稼働数 | **要確認** | cron登録数と不一致（INC-015） |
| **自動化** | 自動ローテーションスクリプト | **4本** | 日次・週次×2・季刊 |
| **知識管理** | メモリファイル数 | **25+件** | 短期/中期/長期の3層 |
| **知識管理** | AGENT-LOG削減率 | **−93%** | 日次ダイジェスト化による |
| **ガバナンス** | ITIL 5ライフサイクルカバレッジ | **8/8アクティビティ** | `tools/itil5-ai-governance/` |
| **ガバナンス** | 対応管轄数 | **3管轄（JP/US/EU）** | `tools/itil5-ai-governance/phase-gate.sh` |
| **ガバナンス** | TRiSM Privacy カバレッジ | **40% → 75%** | Phase 6: pii-guard.sh + scrub_pii() + DPIAダッシュボード + クロスボーダー規定（後述⑥） |

---

### 計算根拠

**① CLI subprocess コスト削減（−99.5%）**

`claude -p` をスクリプトから呼び出す際、Claude Code はデフォルトで `~/.claude/CLAUDE.md`・hook設定・MCPサーバー定義・memoryファイル・全ツール定義をsystem promptに読み込む。自動化用途ではこのオーバーヘッドはすべて無駄。

**根本原因**: `--setting-sources` のデフォルトは `user,project,local`（全設定読込）。`--tools` のデフォルトは全ビルトインツール（Bash/Read/Edit/Write等）。

**対策**: 2つのフラグで全オーバーヘッドを除去:

```bash
claude \
  -p "プロンプト" \
  --setting-sources "" \   # CLAUDE.md・hooks・MCP・memory読込を無効化
  --tools ""               # 全ビルトインツール定義を無効化
```

**実測ベンチマーク**（Claude Code CLI 2.1.92、2026-04-26）:

| 設定 | 入力トークン | コスト/コール |
|-----|------------|------------|
| デフォルト `claude -p` | 約166,000 | $0.210 |
| `--setting-sources ""` のみ | 約20,000 | $0.025 |
| `--setting-sources "" --tools ""` | 約1,100 | **$0.001** |

```
削減: ($0.21 - $0.001) / $0.21 = 99.52%
```

**実運用インパクト**（100+コール/日）: 月$630 → 月$3

> **再現可能な実装**: [`examples/cost-optimization/claude-subprocess.js`](../examples/cost-optimization/claude-subprocess.js)（Node.js）および [`claude-subprocess.sh`](../examples/cost-optimization/claude-subprocess.sh)（bash）
>
> 注: `--bare` は代替手段として**使用不可**（OAuth認証をバイパスしてしまう）。`--setting-sources "" --tools ""` の組み合わせがOAuth認証を保持しつつ最小化する正解。

**② SessionStart context削減（−99.8%）**

セッション起動時に自動読み込みされるファイル群の最適化。

```
Before:
  AGENT-LOG.md      19.0 MB（327セッション分の未圧縮ログ）
  git diff出力      25–35 KB
  合計              ≈ 19.03 MB / session

After:
  AGENT-LOG（日次ダイジェスト）  12 KB
  MEMORY.md（インデックスのみ）  24 KB
  合計                          ≈ 36 KB / session

削減: (19,030 - 36) / 19,030 = 99.81%
```

**実現方法**: 日次ダイジェスト自動化スクリプトが生ログをスケジュール実行で構造化サマリーに圧縮する。
スクリプトはハーネスランタイム（`~/.claude/scripts/summarize-improvement-log.sh`）に存在するが、
このリポジトリにはまだ独立した再現可能な例として抽出されていない。

> **再現性ステータス**: before/afterの実測値は本物。
> 自動化スクリプト自体はまだここに公開されていない — ロードマップのPhase 7aで抽出予定。

**③ 年間トークン消費削減（−99.96%）**

**この数値を引用する前に注意して読んでほしい。**

これは「最悪ケースの上限推定（before）」と「実測ベース推定（after）」の比較であり、
管理された条件下でのbefore/after計測ではない。

```
Before（最悪ケース — ログ肥大化が無制限に続いた場合）:
  3.79M tokens/session × 400 sessions/year
  = 1.516 Billion tokens/year + その他消費推定
  ≈ 33.2B tokens/year（上限推定値、実測ではない）

After:
  13.3M tokens/year（②の実測ベース推定）

削減: (33.2B - 13.3M) / 33.2B ≈ 99.96%
```

**この数値が実際に示すもの**: ログ肥大化が観測された成長率で継続していた場合、
年間トークン消費は約33Bに達していた。実装した最適化により実測消費は約13M/年に収まっている。

**この数値が示さないもの**: フェアな管理比較ではない。
「before」は持続不可能な軌跡からの推定であり、安定した運用状態ではない。
ログを手動で一定サイズに保つといった保守的なベースラインとの比較では削減率はより小さくなる。

> 構造化されていないAI運用がトークン消費の際限ない増加を引き起こすという観測は本物だ。
> 正確な削減率は選択するベースライン次第で変わる。

**④ セキュリティhook一覧（9種類）**
*ISO/IEC 27001 準拠: A.9 アクセス制御、A.12 運用のセキュリティ*

| hook名 | 種別 | 目的 |
|--------|------|------|
| `bash-secret-guard.sh` | PreToolUse | Bashコマンド内のcredential漏洩パターンをブロック |
| `pre-commit-secrets.sh` | PreToolUse | git commit前のcredentialスキャン（gitleaks連携）|
| `mcp-config-guard.sh` | PreToolUse | MCP設定ファイルの無断変更を防止 |
| `npm-install-guard.sh` | PreToolUse | typosquatting攻撃パターンの検出 |
| `worktree-guard.sh` | PreToolUse | 親リポジトリへの誤った書込操作をブロック |
| `detect-rerebuke.sh` | PreToolUse | 同一ルール違反の繰り返し検出 |
| `audit-output.sh` | PostToolUse | ツール出力の監査ログ記録 |
| `session-start-suggest-worktree.sh` | SessionStart | 既存worktreeへの再入を提案（誤作成防止）|
| `load-feedback-rules.sh` | SessionStart | フィードバックルールの自動ロード |

---

### ⑤ ITIL 5 AIガバナンス実装

ITIL 5（2026年PeopleCert）の4コアプラクティスを実装したAIプロダクトライフサイクル管理ツール。

| ITIL 5プラクティス | 実装内容 |
|-----------------|---------|
| プロダクト/サービスライフサイクル | 8アクティビティ × 各5〜7機能の最低保証カタログ |
| AIガバナンス（6C） | フェーズゲート評価 + EU AI Actリスク階層判定 |
| サービス財務管理 | 7ロールRACI + 7アウトカムKPI + 財務エスカレーションロジック |
| Change Enablement | sha256改ざん検知付きappend-only承認ログ |

管轄対応: JP（金融庁）・US（SR 11-7, 金融機関向け）・EU（AI Act Art.43）
