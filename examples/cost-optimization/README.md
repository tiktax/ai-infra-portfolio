# Cost Optimization Examples

Reproducible implementations of the two techniques that achieved **−99.5% AI inference cost**.

---

## Technique 1: Optimized CLI Subprocess Invocation

### The Problem

When invoking `claude -p "prompt"` from a script, Claude Code loads its full
configuration into the system prompt on every call:

```
~/.claude/CLAUDE.md          (behavioral spec)
Hook configurations          (PreToolUse, PostToolUse, etc.)
MCP server definitions       (every connected server)
Memory files                 (project + global memories)
All built-in tools           (Bash, Read, Edit, Write, ...)
```

**Result**: ~166,000 input tokens per call → **$0.21/call** (Haiku pricing)

### The Fix

Two flags strip all of this overhead:

```bash
claude \
  -p "your prompt" \
  --setting-sources "" \   # ← disables CLAUDE.md, hooks, MCP, memory loading
  --tools ""               # ← disables all built-in tool definitions
```

**Result**: ~1,100 input tokens per call → **$0.001/call**

### Benchmark

Measured on Claude Code CLI 2.1.92 (2026-04-26):

| Configuration | Input tokens | Cost/call | Latency |
|--------------|-------------|-----------|---------|
| Default `claude -p` | ~166,000 | $0.210 | ~8s |
| `--setting-sources ""` only | ~20,000 | $0.025 | ~3s |
| `--setting-sources "" --tools ""` | ~1,100 | **$0.001** | **~1.3s** |

**Reduction**: ($0.21 − $0.001) / $0.21 = **99.52%**

### Real-World Impact

A workflow running 100+ automated Claude calls per day:

| | Monthly cost |
|-|-------------|
| Default | ~$630 |
| Optimized | **~$3** |

### Implementation

**Node.js** → [`claude-subprocess.js`](claude-subprocess.js)

```javascript
const args = [
  '-p', prompt,
  '--output-format', 'json',
  '--model', 'haiku',
  '--setting-sources', '',    // KEY: strip all config loading
  '--tools', '',              // KEY: strip all tool definitions
  '--system-prompt', minimalSystemPrompt,
  '--max-budget-usd', '0.50',
  '--no-session-persistence',
];
```

**Bash** → [`claude-subprocess.sh`](claude-subprocess.sh)

```bash
claude \
  -p "$PROMPT" \
  --output-format json \
  --model haiku \
  --setting-sources "" \
  --tools "" \
  --system-prompt "$SYSTEM_PROMPT" \
  --max-budget-usd 0.50 \
  --no-session-persistence
```

### Important Notes

- `--bare` flag is **not** a valid alternative — it bypasses OAuth authentication
  and requires `ANTHROPIC_API_KEY` directly. The `--setting-sources + --tools`
  combination preserves OAuth while minimizing token overhead.
- Always handle `is_error: true` in the JSON response (auth failures, budget
  exceeded, network errors all surface here).
- Add `--json-schema <schema>` for structured output enforcement.
- This optimization is for **scripted/automated calls only**. Interactive
  sessions should use the default configuration.

---

## Technique 2: Local/Cloud LLM Routing (LiteLLM Proxy)

### The Problem

All AI calls routed to Claude API at cloud pricing, even for simple tasks
(summarization, classification, reformatting) that a local model handles well.

### The Fix

Run a LiteLLM Proxy locally, routing by task complexity:

```
Simple tasks (summarize, classify, reformat) → Local LLM (Gemma4, free)
Complex tasks (design, architecture, debug)  → Claude API (pay-per-token)
```

### Example Config

```yaml
# litellm-config.yaml (anonymized example)
model_list:
  # Local model — zero marginal cost
  - model_name: light
    litellm_params:
      model: ollama/gemma4          # or any Ollama-served model
      api_base: http://127.0.0.1:11434

  # Cloud model — pay per token
  - model_name: heavy
    litellm_params:
      model: claude-haiku-4-5
      api_key: os.environ/ANTHROPIC_API_KEY

  # Alias: default to light unless explicitly overridden
  - model_name: auto
    litellm_params:
      model: light
```

**Start the proxy:**
```bash
litellm --config litellm-config.yaml --port 4000
```

**Use from Claude Code** (via `LITELLM_DEFAULT_ALIAS=light` env var):
```bash
# Light tasks use local model (free)
LITELLM_DEFAULT_ALIAS=light claude -p "summarize this text"

# Heavy tasks explicitly use cloud model
LITELLM_DEFAULT_ALIAS=heavy claude -p "design this architecture"
```

### Routing Decision Guide

| Task type | Model | Reason |
|-----------|-------|--------|
| Summarization | light | No reasoning required |
| Classification / tagging | light | Pattern matching only |
| Text reformatting | light | Template-based output |
| Code review (simple) | light | Heuristic checks |
| Architecture design | heavy | Multi-step reasoning |
| Security analysis | heavy | Precision critical |
| Complex debugging | heavy | Context-dependent |
| Writing production code | heavy | High accuracy needed |

---

## Combined Effect

These reductions are **multiplicative**, not additive. Each layer applies to
whatever remains after the previous layer.

### Waterfall: Per Automated Call

| Layer | Technique | Tokens remaining | Reduction |
|-------|-----------|-----------------|-----------|
| Baseline | Default `claude -p` | 166,000 | — |
| L5 | `--setting-sources "" --tools ""` | 1,100 | −99.3% (measured) |
| L6 | RTK output compression | ~330 | additional −70% avg (measured) |
| L7 | LocalLLM routing (70% at $0) | effective cost ≈ $0.00006 | — |

### Annual Projection (100 automated calls/day)

| Scenario | Annual tokens | Annual cost |
|----------|-------------|------------|
| Unoptimized | ~6,059M | ~$630/month |
| L5 only | ~40M | ~$4/month |
| L5 + L6 (RTK, −70% avg) | ~12M | ~$1.3/month |
| L5 + L6 + L7 (routing) | ~2–5M (cloud only) | ~$0.30/month |

See [`docs/token-optimization-layers.md`](../../docs/token-optimization-layers.md)
for the full 8-layer reference including interactive session optimizations.
See [`docs/achievements.md`](../../docs/achievements.md) for measured benchmarks and calculation basis.

### RTK Integration

[RTK (Rust Token Killer)](https://www.rtk-ai.app/) adds L6 compression.
See [`examples/rtk-integration/`](../rtk-integration/) for implementation.

---

## 日本語版

### コスト最適化の実装例

**技術1: CLI subprocess最適化**

`claude -p "prompt"` をスクリプトから呼ぶ際、デフォルトでは `~/.claude/CLAUDE.md`・hook設定・MCPサーバー定義・memoryファイルをすべてsystem promptに読み込み、約166,000トークン（$0.21/コール）消費する。

2つのフラグでこのオーバーヘッドを除去:
```bash
--setting-sources ""   # 設定読込を無効化
--tools ""             # ツール定義を無効化
```
→ 約1,100トークン（$0.001/コール）＝ **99.5%削減**

**技術2: LiteLLM Proxyによるローカル/クラウドLLMルーティング**

単純タスク（要約・分類・変換）→ローカルLLM（Gemma4、コスト0）
複雑タスク（設計・デバッグ・コードレビュー）→クラウドAPI（従量課金）

> 実装例: [`claude-subprocess.js`](claude-subprocess.js) / [`claude-subprocess.sh`](claude-subprocess.sh)
> ベンチマーク測定: 2026-04-26、Claude Code CLI 2.1.92
