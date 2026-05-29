# RTK Integration Examples

How to combine [RTK (Rust Token Killer)](https://www.rtk-ai.app/) with the subprocess
optimization to compress content before it reaches the LLM.

---

## What RTK Does

RTK is a Rust-based CLI tool that filters and compresses text output before it is
passed to an LLM. It targets verbose, repetitive, or low-information-density content
(stack traces, log files, test output, file diffs) and strips or condenses it.

- **Install**: `brew install rtk`
- **Vendor-stated compression**: 60–90% token reduction on typical tool output
- **How it works**: pipe-based — reads stdin, writes compressed output to stdout

---

## When RTK Applies

RTK is relevant when the **content being passed to Claude is large**.

| Scenario | RTK useful? | Notes |
|----------|-------------|-------|
| Passing log files to Claude | Yes | Logs are highly compressible |
| Passing test output | Yes | Failures are dense, passes are noise |
| Passing git diffs | Yes | Context lines often redundant |
| Short prompts or structured queries | No | Already minimal; overhead not worth it |
| System prompts / CLAUDE.md | No | Use prompt caching for those instead |

---

## Pattern 1: RTK + Subprocess Flags (Automated Calls)

Combine L5 (subprocess flags) with L6 (RTK) for the smallest possible call cost.

```bash
# Without RTK: content passed verbatim into the subprocess prompt
TEST_OUTPUT="$(npm test 2>&1)"
claude -p "Analyze these test failures: $TEST_OUTPUT" \
  --setting-sources "" --tools "" --model haiku

# With RTK: compress content before it enters the prompt
TEST_OUTPUT="$(npm test 2>&1 | rtk)"
claude -p "Analyze these test failures: $TEST_OUTPUT" \
  --setting-sources "" --tools "" --model haiku
```

See [`rtk-subprocess.sh`](rtk-subprocess.sh) for a full implementation.

---

## Pattern 2: RTK in Interactive Sessions

In interactive Claude Code sessions, pipe large files or command output through RTK
before passing them to the LLM via shell substitution.

```bash
# Summarize a large log file
cat /var/log/app.log | rtk | claude -p "Summarize the last hour of errors"

# Analyze test failures
cargo test 2>&1 | rtk | claude -p "What caused these test failures?"

# Review a large diff
git diff HEAD~10 | rtk | claude -p "What breaking changes are in this diff?"
```

---

## Measured Compression (RTK Gain Monitor)

This project records every RTK invocation to a Notion database (RTK Gain Monitor),
auto-updated daily via launchd. Measured over 37 days, 5,668 commands:

| Metric | Value |
|--------|-------|
| Token-weighted average | **98.7%** |
| Simple daily average | **70%** |
| Range | 2.8% – 100% |
| P75 (median active day) | 97% |
| Days ≥90% compression | 35% of days |

**Variance explanation**: High compression (90%+) on large log files, test output,
directory trees. Low compression (under 50%) on short prompts and interactive sessions.
The 70% daily average is the conservative, representative figure.

Example: analyzing a 2,000-line application log.

| Approach | Input tokens | Cost (Haiku) |
|----------|-------------|--------------|
| Raw log, default `claude -p` | ~178,000 | $0.23 |
| Raw log + subprocess flags | ~13,000 | $0.017 |
| RTK-compressed + subprocess flags | ~3,900 (−70% avg) | $0.005 |

---

## Layer Positioning

RTK operates at L6 in the [8-layer optimization stack](../../docs/token-optimization-layers.md):

```
L5 subprocess flags: strips system prompt overhead  (−99.3%, measured)
L6 RTK:             strips content overhead         (−70% daily avg, measured)
L7 LocalLLM routing: shifts cost to $0              (50–80% of calls)
```

All three compound. On a 166K-token baseline call:

```
After L5:  1,100 tokens
After L6:    ~330 tokens (−70% daily avg)
After L7:   effective cost near $0 for routed calls
```

---

## Important Notes

- RTK is a third-party tool by [rtk-ai](https://www.rtk-ai.app/). This project
  uses it as an integration, not a replacement for the subprocess optimization.
- RTK does not modify prompts or instructions — it only compresses the *content*
  being analyzed. The LLM still receives a coherent, readable input.
- For very short content (<500 tokens), RTK overhead is not worth applying.
- RTK compression ratio varies by content type: logs and stack traces compress most;
  structured JSON or code compress less.

---

## 日本語版

**RTK連携例**

[RTK（Rust Token Killer）](https://www.rtk-ai.app/)はRust製のパイプベースCLIツールで、
LLMに渡す前にテキスト出力をフィルタリング・圧縮する。60〜90%のトークン削減を実現。

**インストール**: `brew install rtk`

**主なユースケース**:
- ログファイルの要約分析
- テスト失敗の原因分析
- git diffのレビュー

**subprocess最適化との組み合わせ**:
```bash
# L5（subprocess最適化）+ L6（RTK）の複合適用例
TEST_OUTPUT="$(npm test 2>&1 | rtk)"
claude -p "テスト失敗を分析: $TEST_OUTPUT" \
  --setting-sources "" --tools "" --model haiku
```

RTKはこのプロジェクトが実装したツールではなく、[rtk-ai](https://www.rtk-ai.app/)が開発・公開しているサードパーティツール。このプロジェクトでは連携パターンとして採用している。
