#!/bin/bash
# run-tests.sh — Regression test suite for all AI harness security hooks.
#
# Usage:
#   ./tests/hooks/run-tests.sh           # run all hook tests
#   ./tests/hooks/run-tests.sh --hook bash-secret-guard  # run one hook
#
# Exit codes:
#   0 = all tests passed
#   1 = one or more tests failed

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOKS_DIR="$REPO_ROOT/examples/hooks"
TOTAL_PASS=0
TOTAL_FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Test runner ──────────────────────────────────────────────────────────────

run_hook_test() {
    local hook_name="$1"
    local desc="$2"
    local payload="$3"
    local expected="$4"   # "block" (exit 2) or "pass" (exit 0)

    local hook_path="$HOOKS_DIR/${hook_name}.sh"
    if [ ! -f "$hook_path" ]; then
        echo -e "  ${RED}SKIP${NC} $desc — hook file not found: $hook_path"
        return
    fi

    local exit_code=0
    echo "$payload" | bash "$hook_path" 2>/dev/null || exit_code=$?

    if [ "$expected" = "block" ] && [ "$exit_code" = "2" ]; then
        echo -e "  ${GREEN}✅ BLOCK${NC}  $desc"
        ((TOTAL_PASS++))
    elif [ "$expected" = "pass" ] && [ "$exit_code" = "0" ]; then
        echo -e "  ${GREEN}✅ PASS${NC}   $desc"
        ((TOTAL_PASS++))
    else
        echo -e "  ${RED}❌ FAIL${NC}   $desc"
        echo -e "     Expected: $expected | Got exit code: $exit_code"
        ((TOTAL_FAIL++))
    fi
}

bash_payload() { printf '{"tool_input":{"command":"%s"}}' "$1"; }

# ── bash-secret-guard tests ───────────────────────────────────────────────────

test_bash_secret_guard() {
    echo -e "\n${CYAN}▶ bash-secret-guard.sh${NC}"
    echo "  Blocks credential leak patterns in Bash commands"

    # --- Should BLOCK ---
    run_hook_test "bash-secret-guard" \
        "cat .env" \
        "$(bash_payload 'cat .env')" "block"

    run_hook_test "bash-secret-guard" \
        "grep token .env" \
        "$(bash_payload 'grep token .env')" "block"

    run_hook_test "bash-secret-guard" \
        "awk print .env" \
        '{"tool_input":{"command":"awk '"'"'{print}'"'"' .env"}}' "block"

    run_hook_test "bash-secret-guard" \
        "sed read .env" \
        '{"tool_input":{"command":"sed -n 1p .env"}}' "block"

    run_hook_test "bash-secret-guard" \
        "cat tokens.json" \
        "$(bash_payload 'cat tokens.json')" "block"

    run_hook_test "bash-secret-guard" \
        "cat credentials.json" \
        "$(bash_payload 'cat credentials.json')" "block"

    run_hook_test "bash-secret-guard" \
        'echo $SECRET_TOKEN (env var display)' \
        '{"tool_input":{"command":"echo $SECRET_TOKEN"}}' "block"

    run_hook_test "bash-secret-guard" \
        'echo $API_KEY (env var display)' \
        '{"tool_input":{"command":"echo $API_KEY"}}' "block"

    run_hook_test "bash-secret-guard" \
        "printenv (full env dump)" \
        "$(bash_payload 'printenv')" "block"

    run_hook_test "bash-secret-guard" \
        "env (full env dump)" \
        "$(bash_payload 'env')" "block"

    # --- Should PASS ---
    run_hook_test "bash-secret-guard" \
        "wc -l .env (metadata only)" \
        "$(bash_payload 'wc -l .env')" "pass"

    run_hook_test "bash-secret-guard" \
        "[ -f .env ] existence check" \
        '{"tool_input":{"command":"[ -f .env ] && echo exists"}}' "pass"

    run_hook_test "bash-secret-guard" \
        "cat .env.example (template)" \
        "$(bash_payload 'cat .env.example')" "pass"

    run_hook_test "bash-secret-guard" \
        "cat .env.1password (template)" \
        "$(bash_payload 'cat .env.1password')" "pass"

    run_hook_test "bash-secret-guard" \
        "git status (safe command)" \
        "$(bash_payload 'git status')" "pass"

    run_hook_test "bash-secret-guard" \
        "ls -la (safe command)" \
        "$(bash_payload 'ls -la')" "pass"

    run_hook_test "bash-secret-guard" \
        "npm install (safe command)" \
        "$(bash_payload 'npm install')" "pass"
}

# ── npm-install-guard tests ───────────────────────────────────────────────────

test_npm_install_guard() {
    echo -e "\n${CYAN}▶ npm-install-guard.sh${NC}"
    echo "  Blocks typosquatting and suspicious package installs"

    run_hook_test "npm-install-guard" \
        "npm install expresss (typosquat)" \
        "$(bash_payload 'npm install expresss')" "block"

    run_hook_test "npm-install-guard" \
        "npm install (safe, no args)" \
        "$(bash_payload 'npm install')" "pass"

    run_hook_test "npm-install-guard" \
        "npm install lodash (known safe)" \
        "$(bash_payload 'npm install lodash')" "pass"
}

# ── Summary ───────────────────────────────────────────────────────────────────

print_summary() {
    echo ""
    echo "════════════════════════════════════"
    echo -e "Results: ${GREEN}$TOTAL_PASS passed${NC}, ${RED}$TOTAL_FAIL failed${NC}"
    echo ""
    if [ "$TOTAL_FAIL" -eq 0 ]; then
        echo -e "${GREEN}✅ All hook tests passed.${NC}"
        exit 0
    else
        echo -e "${RED}❌ $TOTAL_FAIL test(s) failed.${NC}"
        exit 1
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────

echo -e "${YELLOW}🧪 AI Harness Hook Test Suite${NC}"
echo "════════════════════════════════════"

FILTER="${1:-all}"

if [ "$FILTER" = "all" ] || [ "$FILTER" = "--hook" ] && [ "${2:-}" = "bash-secret-guard" ]; then
    test_bash_secret_guard
fi

if [ "$FILTER" = "all" ] || [ "$FILTER" = "--hook" ] && [ "${2:-}" = "npm-install-guard" ]; then
    test_npm_install_guard
fi

print_summary
