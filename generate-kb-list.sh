#!/usr/bin/env bash
# generate-kb-list.sh — Generate role-specific KB reading list from docs/
# Usage: bash generate-kb-list.sh --role <engineer|analyst|manager> [--format text|markdown]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROLE=""
FORMAT="text"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --role)
      ROLE="$2"; shift 2 ;;
    --format)
      FORMAT="$2"; shift 2 ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 --role <engineer|analyst|manager> [--format text|markdown]" >&2
      exit 1 ;;
  esac
done

if [[ -z "$ROLE" ]]; then
  echo "Error: --role is required (engineer|analyst|manager)" >&2
  exit 1
fi

if [[ "$FORMAT" != "text" && "$FORMAT" != "markdown" ]]; then
  echo "Error: --format must be 'text' or 'markdown'" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Role-specific file lists: "<path>|<description>"
# ---------------------------------------------------------------------------
declare -a FILES=()

case "$ROLE" in
  engineer)
    # docs/*.md — all
    FILES+=(
      "docs/achievements.md|Quantified results with calculation basis"
      "docs/architecture.md|System diagrams (Mermaid)"
      "docs/deployment-playbook.md|Step-by-step deployment guide"
      "docs/ai-usage-policy-draft.md|AI usage governance policy draft"
      "docs/dashboard.md|Operational metrics dashboard"
      "docs/roadmap.md|Feature roadmap and milestones"
    )
    # docs/considerations/ — all
    for f in "${SCRIPT_DIR}/docs/considerations/"*.md; do
      [[ -f "$f" ]] || continue
      rel="${f#${SCRIPT_DIR}/}"
      base="$(basename "$f" .md)"
      FILES+=("${rel}|Scale considerations: ${base}")
    done
    # examples/hooks/
    for f in "${SCRIPT_DIR}/examples/hooks/"*; do
      [[ -f "$f" ]] || continue
      rel="${f#${SCRIPT_DIR}/}"
      base="$(basename "$f")"
      FILES+=("${rel}|Hook example: ${base}")
    done
    # tools/*/README.md
    for f in "${SCRIPT_DIR}/tools/"*/README.md; do
      [[ -f "$f" ]] || continue
      rel="${f#${SCRIPT_DIR}/}"
      tool_dir="$(basename "$(dirname "$f")")"
      FILES+=("${rel}|Tool README: ${tool_dir}")
    done
    ;;
  analyst)
    FILES+=(
      "docs/achievements.md|Quantified results with calculation basis"
      "docs/dashboard.md|Operational metrics dashboard"
      "docs/ai-usage-policy-draft.md|AI usage governance policy draft"
    )
    for f in "${SCRIPT_DIR}/docs/considerations/"*.md; do
      [[ -f "$f" ]] || continue
      rel="${f#${SCRIPT_DIR}/}"
      base="$(basename "$f" .md)"
      FILES+=("${rel}|Scale considerations: ${base}")
    done
    ;;
  manager)
    FILES+=(
      "docs/deployment-playbook.md|Step-by-step deployment guide"
      "docs/achievements.md|Quantified results with calculation basis"
      "docs/roadmap.md|Feature roadmap and milestones"
      "docs/architecture.md|System diagrams (Mermaid)"
    )
    ;;
  *)
    echo "Error: Unknown role '${ROLE}'. Valid roles: engineer|analyst|manager" >&2
    exit 1 ;;
esac

# ---------------------------------------------------------------------------
# Filter to existing files only
# ---------------------------------------------------------------------------
declare -a EXISTING=()
for entry in "${FILES[@]}"; do
  path="${entry%%|*}"
  desc="${entry##*|}"
  full="${SCRIPT_DIR}/${path}"
  if [[ -f "$full" ]]; then
    EXISTING+=("${path}|${desc}")
  fi
done

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
if [[ "$FORMAT" == "text" ]]; then
  echo "Recommended resources for role: ${ROLE}"
  echo "=========================================="
  idx=1
  for entry in "${EXISTING[@]}"; do
    path="${entry%%|*}"
    desc="${entry##*|}"
    printf "[%d] %s — %s\n" "$idx" "$path" "$desc"
    (( idx++ ))
  done
  if [[ ${#EXISTING[@]} -eq 0 ]]; then
    echo "(No matching files found in ${SCRIPT_DIR}/docs/)"
  fi

elif [[ "$FORMAT" == "markdown" ]]; then
  echo "## Recommended Resources — ${ROLE}"
  echo ""
  echo "| # | File | Description |"
  echo "|---|------|-------------|"
  idx=1
  for entry in "${EXISTING[@]}"; do
    path="${entry%%|*}"
    desc="${entry##*|}"
    printf "| %d | [%s](%s) | %s |\n" "$idx" "$path" "$path" "$desc"
    (( idx++ ))
  done
  if [[ ${#EXISTING[@]} -eq 0 ]]; then
    echo ""
    echo "_No matching files found._"
  fi
fi
