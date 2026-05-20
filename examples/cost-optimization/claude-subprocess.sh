#!/usr/bin/env bash
# claude-subprocess.sh — Optimized Claude Code CLI subprocess (bash version)
#
# Benchmark (Claude Code CLI 2.1.92, 2026-04-26):
#   Default:                         $0.21/call  (166K tokens)
#   --setting-sources "" only:       $0.025/call (20K tokens)
#   --setting-sources "" --tools "": $0.001/call (1.1K tokens, 1.3s)
#
# Usage:
#   bash claude-subprocess.sh "your prompt here"
#   bash claude-subprocess.sh "your prompt" haiku
#   SYSTEM_PROMPT="Be concise." bash claude-subprocess.sh "your prompt"

set -euo pipefail

PROMPT="${1:-Summarize the key benefit of the --setting-sources flag in one sentence.}"
MODEL="${2:-haiku}"
SYSTEM_PROMPT="${SYSTEM_PROMPT:-You are a helpful assistant. Be concise.}"
MAX_BUDGET="${MAX_BUDGET:-0.50}"

# ---------------------------------------------------------------------------
# Optimized invocation — the two critical flags:
#
#   --setting-sources ""
#     Prevents Claude Code from loading ~/.claude/CLAUDE.md, hook configs,
#     MCP server definitions, and memory files into the system prompt.
#     Without this: ~166K tokens of overhead on every call.
#
#   --tools ""
#     Disables all built-in tools (Bash, Read, Edit, Write, etc.).
#     For text-only tasks these are never needed and add token overhead.
#
#   Together: 1.1K input tokens vs 166K = 99.3% token reduction
# ---------------------------------------------------------------------------

OUTPUT="$(claude \
  -p "$PROMPT" \
  --output-format json \
  --model "$MODEL" \
  --setting-sources "" \
  --tools "" \
  --system-prompt "$SYSTEM_PROMPT" \
  --max-budget-usd "$MAX_BUDGET" \
  --no-session-persistence \
)"

# Parse result (requires python3 or jq)
if command -v jq &>/dev/null; then
  IS_ERROR="$(echo "$OUTPUT" | jq -r '.is_error')"
  RESULT="$(echo "$OUTPUT" | jq -r '.result')"
  COST="$(echo "$OUTPUT" | jq -r '.cost_usd // "N/A"')"
else
  IS_ERROR="$(python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('is_error','false'))" <<< "$OUTPUT")"
  RESULT="$(python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('result',''))" <<< "$OUTPUT")"
  COST="$(python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('cost_usd','N/A'))" <<< "$OUTPUT")"
fi

if [[ "$IS_ERROR" == "true" ]]; then
  echo "ERROR: $RESULT" >&2
  exit 1
fi

echo "$RESULT"
echo "(cost: \$$COST)" >&2
