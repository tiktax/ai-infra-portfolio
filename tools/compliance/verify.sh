#!/usr/bin/env bash
# verify.sh — OWASP Agentic AI Top 10 coverage report
#
# Checks artifact existence for each ASI risk and reports coverage status.
# Honest by design: ASI09 and ASI10 are design tradeoffs, not gaps.
#
# Usage:
#   ./tools/compliance/verify.sh          # terminal output (colored)
#   ./tools/compliance/verify.sh --json   # JSON output for CI
#   ./tools/compliance/verify.sh --md     # GitHub Markdown table
#
# Exit codes:
#   0  All covered/tradeoff items verified
#   1  One or more COVERED items are missing artifacts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

MODE="${1:-terminal}"

# ── Color codes (terminal only) ───────────────────────────────────────────────
if [ "$MODE" = "terminal" ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    GRAY='\033[0;37m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' RED='' CYAN='' GRAY='' NC=''
fi

# ── Artifact check helpers ────────────────────────────────────────────────────
_file()  { [ -f "${REPO_ROOT}/$1" ] && echo "yes" || echo "no"; }
_dir()   { [ -d "${REPO_ROOT}/$1" ] && echo "yes" || echo "no"; }
_any()   { find "${REPO_ROOT}/$1" -name "$2" 2>/dev/null | grep -q . && echo "yes" || echo "no"; }

# ── Coverage matrix ───────────────────────────────────────────────────────────
# Format: "ASI_ID|STATUS|RISK_NAME|ARTIFACT_CHECK|ARTIFACT_PATH|NOTES"
# STATUS: covered | partial | tradeoff
# ARTIFACT_CHECK: file | dir | any

declare -a MATRIX=(
    "ASI01|covered|Goal Hijacking|file|examples/hooks/prompt-injection-guard.sh|14 injection patterns; override: # injection-guard:allow"
    "ASI02|covered|Tool Misuse|file|examples/hooks/bash-secret-guard.sh|bash-secret-guard.sh + mcp-config-guard.sh"
    "ASI03|partial|Identity/Privilege Abuse|file|tools/trustless_audit/src/signing.py|Key fingerprint distinguishes AI vs HUMAN. Full IAM-style identity registry out of scope."
    "ASI04|covered|Supply Chain|file|examples/hooks/pre-commit-secrets.sh|pre-commit-secrets.sh + sbom-scan.yml CI"
    "ASI05|covered|Code Execution|file|examples/hooks/bash-secret-guard.sh|Bash command patterns blocked at PreToolUse"
    "ASI06|covered|Memory Poisoning|file|examples/hooks/claude-md-integrity.sh|CLAUDE.md writes blocked + ECDSA-signed audit entry"
    "ASI07|partial|Inter-Agent Comms|file|tools/trustless_audit/src/orchestration_audit.py|Hash-linked delegation chain. Agent-to-agent protocol verification not implemented."
    "ASI08|covered|Cascading Failures|file|tools/kill-switch/kill-switch.sh|Kill switch + circuit breaker with signed stop events"
    "ASI09|tradeoff|Trust Exploitation|none|n/a|Design tradeoff: Claude Code single-developer harness focuses on proving actions, not runtime agent identity registry. Requires separate identity infrastructure."
    "ASI10|tradeoff|Rogue Agents|none|n/a|Design tradeoff: Runtime agent behavioral monitoring requires persistent agent processes. Out of scope for a single-developer Claude Code harness."
)

# ── Verify artifacts ──────────────────────────────────────────────────────────
declare -a RESULTS=()
FAIL=0
COVERED=0
PARTIAL=0
TRADEOFF=0
MISSING=0

for row in "${MATRIX[@]}"; do
    IFS='|' read -r asi_id status risk_name check_type artifact_path notes <<< "$row"

    artifact_ok="yes"
    if [ "$check_type" = "file" ]; then
        artifact_ok=$(_file "$artifact_path")
    elif [ "$check_type" = "dir" ]; then
        artifact_ok=$(_dir "$artifact_path")
    fi
    # check_type "none" → tradeoff, always ok

    case "$status" in
        covered)
            if [ "$artifact_ok" = "yes" ]; then
                symbol="✅" ; color="$GREEN" ; ((COVERED++))
            else
                symbol="❌" ; color="$RED" ; ((MISSING++)) ; FAIL=1
            fi
            ;;
        partial)
            symbol="⚠️ " ; color="$YELLOW" ; ((PARTIAL++))
            ;;
        tradeoff)
            symbol="🔹" ; color="$GRAY" ; ((TRADEOFF++))
            ;;
    esac

    RESULTS+=("${asi_id}|${status}|${artifact_ok}|${symbol}|${color}|${risk_name}|${artifact_path}|${notes}")
done

# ── Claude.md audit entry check (ASI06 evidence) ─────────────────────────────
CLAUDE_MD_ENTRIES=0
APPROVALS_LOG="${REPO_ROOT}/tools/itil5-ai-governance/approvals.log"
if [ -f "$APPROVALS_LOG" ]; then
    # grep -c exits 1 when count=0; use || true to suppress the non-zero exit
    # grep -c always prints the count, so output is "0" not "0\n0"
    CLAUDE_MD_ENTRIES=$(grep -c '"action":"claude_md_modified"' "$APPROVALS_LOG" 2>/dev/null || true)
    CLAUDE_MD_ENTRIES="${CLAUDE_MD_ENTRIES:-0}"
fi

# ── Output ────────────────────────────────────────────────────────────────────

if [ "$MODE" = "--json" ]; then
    # Write items to a temp JSONL file to avoid shell interpolation issues
    TMP_ITEMS=$(mktemp)
    trap "rm -f $TMP_ITEMS" EXIT

    for row in "${RESULTS[@]}"; do
        IFS='|' read -r asi_id status artifact_ok symbol color risk_name artifact_path notes <<< "$row"
        # Write one JSON object per line (JSONL)
        python3 -c "
import json, sys
asi_id   = sys.argv[1]
status   = sys.argv[2]
art_ok   = sys.argv[3] == 'yes'
risk     = sys.argv[4]
artifact = sys.argv[5] if sys.argv[5] != 'n/a' else None
notes    = sys.argv[6]
print(json.dumps({'id': asi_id, 'status': status, 'risk': risk,
                  'artifact_found': art_ok, 'artifact': artifact, 'notes': notes}))
" "$asi_id" "$status" "$artifact_ok" "$risk_name" "$artifact_path" "$notes" >> "$TMP_ITEMS"
    done

    python3 - "$TMP_ITEMS" "$COVERED" "$PARTIAL" "$TRADEOFF" "$MISSING" "$CLAUDE_MD_ENTRIES" <<'PYEOF'
import json, sys
items_file, covered, partial, tradeoff, missing, cm_entries = sys.argv[1:]
items = [json.loads(line) for line in open(items_file) if line.strip()]
summary = {
    "covered": int(covered.strip()),
    "partial": int(partial.strip()),
    "tradeoff": int(tradeoff.strip()),
    "missing": int(missing.strip()),
    "claude_md_audit_entries": int(cm_entries.strip()),
    "items": items,
}
print(json.dumps(summary, indent=2))
PYEOF
    exit $FAIL

elif [ "$MODE" = "--md" ]; then
    echo "## OWASP Agentic AI Top 10 Coverage"
    echo ""
    echo "| ID | Status | Risk | Artifact | Notes |"
    echo "|---|---|---|---|---|"
    for row in "${RESULTS[@]}"; do
        IFS='|' read -r asi_id status artifact_ok symbol color risk_name artifact_path notes <<< "$row"
        artifact_display=""
        if [ "$artifact_path" != "n/a" ]; then
            artifact_display="\`${artifact_path}\`"
        else
            artifact_display="—"
        fi
        echo "| **${asi_id}** | ${symbol} ${status} | ${risk_name} | ${artifact_display} | ${notes} |"
    done
    echo ""
    echo "**Summary**: ${COVERED}/10 covered ✅ · ${PARTIAL}/10 partial ⚠️ · ${TRADEOFF}/10 design tradeoffs 🔹"
    if [ "$CLAUDE_MD_ENTRIES" -gt 0 ]; then
        echo ""
        echo "> ASI06 audit evidence: ${CLAUDE_MD_ENTRIES} CLAUDE.md modification(s) in signed audit log"
    fi
    exit $FAIL

else
    # Terminal mode
    echo ""
    echo -e "${CYAN}OWASP Agentic AI Top 10 — Coverage Report${NC}"
    echo -e "${CYAN}===========================================${NC}"
    echo ""

    for row in "${RESULTS[@]}"; do
        IFS='|' read -r asi_id status artifact_ok symbol color risk_name artifact_path notes <<< "$row"
        artifact_display=""
        if [ "$artifact_path" != "n/a" ]; then
            artifact_display="${artifact_path}"
        fi
        printf "${color}  ${symbol} %-6s %-26s${NC} %s\n" \
            "$asi_id" "$risk_name" "$artifact_display"
    done

    echo ""
    echo -e "  ${GREEN}Covered:  ${COVERED}/10${NC}"
    echo -e "  ${YELLOW}Partial:  ${PARTIAL}/10${NC}  (artifact exists; partial coverage)"
    echo -e "  ${GRAY}Tradeoff: ${TRADEOFF}/10${NC}  (intentionally out of scope — see notes)"

    if [ "$MISSING" -gt 0 ]; then
        echo -e "  ${RED}Missing:  ${MISSING}/10${NC}  (covered items with no artifact found)"
    fi

    if [ "$CLAUDE_MD_ENTRIES" -gt 0 ]; then
        echo ""
        echo -e "  ${GREEN}ASI06 audit entries: ${CLAUDE_MD_ENTRIES} CLAUDE.md modification(s) signed (ECDSA P-256)${NC}"
    fi

    echo ""
    echo -e "  ${GRAY}Tradeoff design rationale:${NC}"
    echo -e "  ${GRAY}  ASI09/ASI10: This harness focuses on proving what the AI did (audit),${NC}"
    echo -e "  ${GRAY}  not on runtime agent identity or behavioral monitoring. Implementing${NC}"
    echo -e "  ${GRAY}  a runtime agent identity registry is a separate infrastructure concern.${NC}"
    echo ""

    if [ $FAIL -eq 0 ]; then
        echo -e "  ${GREEN}✅ All covered items verified.${NC}"
    else
        echo -e "  ${RED}❌ ${MISSING} covered item(s) missing artifacts. Run from repo root.${NC}"
    fi
    echo ""
    exit $FAIL
fi
