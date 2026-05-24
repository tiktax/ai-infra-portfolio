# Quantified Results

**Period**: March 17 – May 17, 2026 (2 months)
**Project**: Claude Code AI Harness Infrastructure (personal project)
**Governance**: Lightweight alignment with ISO/IEC 20000 (ITSM) and ISO/IEC 27001 (Information Security)

---

## KPI Summary

| Category | Metric | Value | Basis |
|----------|--------|-------|-------|
| **Cost** | CLI subprocess cost reduction | **−99.5%** | $0.21 → $0.001/call (see ①) |
| **Cost** | SessionStart context size reduction | **−99.8%** | 19 MB → 36 KB/session (see ②) |
| **Cost** | Est. annual token consumption reduction | **−99.96%** | 33.2B → 13.3M tokens/year (see ③) |
| **Security** | Guardrail hooks implemented | **9** | (see ④) |
| **Security** | Credential detection patterns | **14** | See `bash-secret-guard.sh` |
| **Security** | INC-011/012 recurrence after fix | **0** | Measured after hook deployment |
| **Incident mgmt** | Total incidents tracked | **13** | INC-001 – INC-013 |
| **Incident mgmt** | Permanently resolved via CIP | **6** | CIP-001 – CIP-006 |
| **Automation** | Scheduled agents running | **3** | Daily, weekly ×2 |
| **Automation** | Auto-rotation scripts | **4** | Daily, weekly ×2, quarterly |
| **Knowledge mgmt** | Memory files maintained | **25+** | 3-tier: short / mid / long-term |
| **Knowledge mgmt** | Log file size reduction | **−93%** | Daily digest automation |
| **Governance** | ITIL 5 compliance coverage | **8/8 lifecycle activities** | `tools/itil5-ai-governance/` |
| **Governance** | Jurisdictions covered | **3 (JP/US/EU)** | `tools/itil5-ai-governance/phase-gate.sh` |

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

### ③ Annual Token Consumption Reduction (−99.96%)

**Read this number carefully before citing it.**

This is a comparison between a worst-case upper-bound projection (before)
and a measurement-based estimate (after). It is not a controlled before/after measurement.

```
Before (worst case — log bloat continuing unchecked):
  3.79M tokens/session × 400 sessions/year
  = 1.516 Billion tokens/year
  + other session overhead
  ≈ 33.2B tokens/year (upper-bound projection, not measured)

After:
  13.3M tokens/year (measurement-based estimate from ②)

Reduction: (33.2B - 13.3M) / 33.2B ≈ 99.96%
```

**What this number actually shows**: If log bloat had continued at the observed
growth rate, annual token consumption would have reached ~33B tokens.
The implemented optimizations brought measured consumption to ~13M tokens/year.

**What this number does not show**: A fair controlled comparison.
The "before" baseline is a projection from an unsustainable trajectory,
not a stable operating state. The reduction would be smaller against
a more conservative baseline (e.g., logs managed manually at a fixed size).

> The observation that unstructured AI operations produce runaway token growth
> is real. The exact percentage depends on the baseline chosen.

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

---

## 日本語版

**期間**: 2026年3月17日〜5月17日（2ヶ月）
**プロジェクト**: Claude Code AIハーネス基盤構築（個人プロジェクト）
**ガバナンス**: ISO/IEC 20000（ITSM）およびISO/IEC 27001（情報セキュリティ）の軽量版準拠

---

### KPI一覧

| カテゴリ | 指標 | 値 | 計算根拠 |
|---------|------|---|---------|
| **コスト** | CLI subprocess コスト削減率 | **−99.5%** | $0.21 → $0.001/call（後述①） |
| **コスト** | SessionStart context削減率 | **−99.8%** | 19 MB → 36 KB/session（後述②） |
| **コスト** | 年間トークン消費削減（推定） | **−99.96%** | 33.2B → 13.3M tokens/年（後述③） |
| **セキュリティ** | 実装したセキュリティhook数 | **9種類** | （後述④） |
| **セキュリティ** | Credential検出パターン数 | **14種類** | bash-secret-guard.sh参照 |
| **セキュリティ** | INC-011/012再発件数 | **0件** | hook導入後の実測値 |
| **障害管理** | 管理インシデント総数 | **13件** | INC-001〜INC-013 |
| **障害管理** | CIPによる恒久解消数 | **6件** | CIP-001〜CIP-006 |
| **自動化** | Scheduledエージェント稼働数 | **3本** | 日次・週次×2 |
| **自動化** | 自動ローテーションスクリプト | **4本** | 日次・週次×2・季刊 |
| **知識管理** | メモリファイル数 | **25+件** | 短期/中期/長期の3層 |
| **知識管理** | AGENT-LOG削減率 | **−93%** | 日次ダイジェスト化による |
| **ガバナンス** | ITIL 5ライフサイクルカバレッジ | **8/8アクティビティ** | `tools/itil5-ai-governance/` |
| **ガバナンス** | 対応管轄数 | **3管轄（JP/US/EU）** | `tools/itil5-ai-governance/phase-gate.sh` |

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
