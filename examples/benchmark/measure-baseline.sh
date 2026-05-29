#!/usr/bin/env bash
# measure-baseline.sh — Reproduce the L5 benchmark: 166K vs 1.1K tokens/call
#
# This script measures the actual token count difference between:
#   - Default claude -p invocation (loads CLAUDE.md + hooks + MCP + tools)
#   - Optimized invocation with --setting-sources "" --tools ""
#
# Reproduces the benchmark from docs/achievements.md ①
# Measured reference: Claude Code CLI 2.1.92, 2026-04-26
#   Default:                         ~166,000 tokens  $0.21/call
#   --setting-sources "" --tools "": ~  1,100 tokens  $0.001/call
#
# Requirements:
#   - claude CLI installed and authenticated
#   - jq (for JSON parsing)
#
# Usage:
#   bash measure-baseline.sh
#   bash measure-baseline.sh --skip-default   # skip the expensive default call

set -euo pipefail

SKIP_DEFAULT=false
for arg in "$@"; do
  [[ "$arg" == "--skip-default" ]] && SKIP_DEFAULT=true
done

PROBE_PROMPT="Reply with the single word: DONE"
MODEL="haiku"

echo "=== L5 Benchmark: Token overhead measurement ==="
echo "Model: $MODEL"
echo ""

# ---------------------------------------------------------------------------
# Helper: run claude and extract token counts from JSON output
# ---------------------------------------------------------------------------
run_and_measure() {
  local label="$1"
  shift
  local output
  output="$(claude -p "$PROBE_PROMPT" --output-format json --model "$MODEL" \
    --max-budget-usd 0.05 --no-session-persistence "$@" 2>/dev/null)"

  if [[ "$(echo "$output" | jq -r '.is_error')" == "true" ]]; then
    echo "ERROR ($label): $(echo "$output" | jq -r '.result')" >&2
    return 1
  fi

  local input_tokens cost
  input_tokens="$(echo "$output" | jq -r '.usage.input_tokens // "N/A"')"
  cost="$(echo "$output" | jq -r '.cost_usd // "N/A"')"

  printf "%-40s  input_tokens: %s  cost: $%s\n" "$label" "$input_tokens" "$cost"
}

# ---------------------------------------------------------------------------
# Measurement 1: Default invocation (expensive — loads full config)
# ---------------------------------------------------------------------------
if [[ "$SKIP_DEFAULT" == "false" ]]; then
  echo "--- Measurement 1: Default (loads CLAUDE.md + hooks + MCP + tools) ---"
  echo "Note: this call is expensive (~\$0.21). Use --skip-default to skip it."
  echo ""
  run_and_measure "Default claude -p"
  echo ""
else
  echo "--- Measurement 1: Skipped (--skip-default flag set) ---"
  echo "Reference value from benchmark: ~166,000 tokens, \$0.210/call"
  echo ""
fi

# ---------------------------------------------------------------------------
# Measurement 2: --setting-sources "" only
# ---------------------------------------------------------------------------
echo "--- Measurement 2: --setting-sources \"\" only ---"
run_and_measure "--setting-sources \"\" only" --setting-sources ""
echo ""

# ---------------------------------------------------------------------------
# Measurement 3: --setting-sources "" --tools "" (full L5 optimization)
# ---------------------------------------------------------------------------
echo "--- Measurement 3: --setting-sources \"\" --tools \"\" (L5 optimized) ---"
run_and_measure "--setting-sources \"\" --tools \"\"" --setting-sources "" --tools ""
echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "=== Reference benchmark (Claude Code CLI 2.1.92, 2026-04-26) ==="
echo ""
printf "%-40s  input_tokens: ~%-10s  cost: \$%s\n" "Default" "166,000" "0.210"
printf "%-40s  input_tokens: ~%-10s  cost: \$%s\n" "--setting-sources \"\" only" "20,000" "0.025"
printf "%-40s  input_tokens: ~%-10s  cost: \$%s\n" "--setting-sources \"\" --tools \"\"" "1,100" "0.001"
echo ""
echo "L5 reduction: (0.210 - 0.001) / 0.210 = 99.5%"
echo ""
echo "Note: your numbers will differ based on:"
echo "  - How many MCP servers you have registered"
echo "  - Size of your CLAUDE.md and memory files"
echo "  - Current Claude Code CLI version"
echo "  - Number of hooks configured"
echo ""
echo "Larger CLAUDE.md / more MCP servers = higher 'Default' baseline = higher reduction ratio."
