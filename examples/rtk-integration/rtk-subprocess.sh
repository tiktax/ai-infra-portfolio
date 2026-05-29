#!/usr/bin/env bash
# rtk-subprocess.sh — Combine RTK output compression with subprocess flag optimization
#
# Layer stack applied:
#   L5: --setting-sources "" --tools ""  → strips system prompt overhead (-99.3%)
#   L6: rtk                              → compresses content before LLM sees it (-60-90%)
#   L7: model routing                    → haiku for analysis, local for summaries
#
# Install RTK: brew install rtk
# RTK docs: https://www.rtk-ai.app/
#
# Usage:
#   # Analyze test output
#   npm test 2>&1 | bash rtk-subprocess.sh analyze-failures
#
#   # Summarize log file
#   cat app.log | bash rtk-subprocess.sh summarize-errors
#
#   # Review a diff
#   git diff HEAD~5 | bash rtk-subprocess.sh review-changes

set -euo pipefail

TASK="${1:-summarize}"
MODEL="${MODEL:-haiku}"
MAX_BUDGET="${MAX_BUDGET:-0.10}"

# Read stdin content
RAW_INPUT="$(cat)"

if [[ -z "$RAW_INPUT" ]]; then
  echo "ERROR: No input provided. Pipe content to this script." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# L6: RTK compression
# Compress content before building the prompt.
# Skip if RTK is not installed — degrades gracefully to uncompressed.
# ---------------------------------------------------------------------------
if command -v rtk &>/dev/null; then
  CONTENT="$(echo "$RAW_INPUT" | rtk)"
  RTK_USED=true
else
  CONTENT="$RAW_INPUT"
  RTK_USED=false
  echo "[rtk-subprocess] WARNING: rtk not found, using uncompressed input" >&2
  echo "[rtk-subprocess] Install: brew install rtk" >&2
fi

# ---------------------------------------------------------------------------
# Build task-specific prompt
# ---------------------------------------------------------------------------
case "$TASK" in
  analyze-failures)
    PROMPT="Analyze these test failures and identify the root cause(s). List each failure with a one-line diagnosis:

$CONTENT"
    ;;
  summarize-errors)
    PROMPT="Summarize the errors and warnings in this log. Group by type, count occurrences, note the most recent timestamp for each:

$CONTENT"
    ;;
  review-changes)
    PROMPT="Review this diff for breaking changes, security issues, and significant behavior changes. Be concise:

$CONTENT"
    ;;
  *)
    PROMPT="$TASK

$CONTENT"
    ;;
esac

# ---------------------------------------------------------------------------
# L5: subprocess flags — strip all config/tool overhead
# --setting-sources "": no CLAUDE.md, hooks, MCP, memory
# --tools "":           no built-in tool definitions
#
# Together: 166K → 1.1K system prompt tokens before content is added
# ---------------------------------------------------------------------------
OUTPUT="$(claude \
  -p "$PROMPT" \
  --output-format json \
  --model "$MODEL" \
  --setting-sources "" \
  --tools "" \
  --max-budget-usd "$MAX_BUDGET" \
  --no-session-persistence \
)"

# Parse result
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

# Debug info on stderr
# Note: character count (wc -m) is used as a token proxy here.
# It is NOT an exact token count — actual tokens depend on tokenizer and content type.
# For ASCII/English text, characters ≈ tokens × 4 (rough approximation).
# For exact token counts, use the Claude API's count_tokens endpoint.
if [[ "$RTK_USED" == "true" ]]; then
  RAW_CHARS="$(echo "$RAW_INPUT" | wc -m | tr -d ' ')"
  COMPRESSED_CHARS="$(echo "$CONTENT" | wc -m | tr -d ' ')"
  RATIO="$(python3 -c "print(f'{(1 - $COMPRESSED_CHARS/$RAW_CHARS)*100:.0f}%')" 2>/dev/null || echo "N/A")"
  echo "(cost: \$$COST | rtk char reduction: ~$RATIO | L5+L6 applied)" >&2
else
  echo "(cost: \$$COST | rtk: not available | L5 only)" >&2
fi
