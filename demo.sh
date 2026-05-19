#!/bin/bash
# demo.sh — Verify that AI harness security hooks are working correctly.
#
# Usage:
#   ./demo.sh
#
# Requirements:
#   - bash
#   - python3
#   - examples/hooks/bash-secret-guard.sh (included in this repo)
#
# No external dependencies or API keys required.

set -euo pipefail

HOOK="$(dirname "$0")/examples/hooks/bash-secret-guard.sh"
PASS=0
FAIL=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

run_test() {
    local desc="$1"
    local command="$2"
    local expected="$3"  # "block" or "pass"

    local payload
    payload=$(printf '{"tool_input":{"command":"%s"}}' "$command")

    local exit_code=0
    echo "$payload" | bash "$HOOK" 2>/dev/null || exit_code=$?

    if [ "$expected" = "block" ] && [ "$exit_code" = "2" ]; then
        echo -e "  ${GREEN}✅ BLOCKED${NC}  $desc"
        ((PASS++))
    elif [ "$expected" = "pass" ] && [ "$exit_code" = "0" ]; then
        echo -e "  ${GREEN}✅ PASSED${NC}   $desc"
        ((PASS++))
    else
        echo -e "  ${RED}❌ UNEXPECTED${NC} $desc — expected '$expected', got exit code $exit_code"
        ((FAIL++))
    fi
}

echo ""
echo -e "${YELLOW}🔍 AI Harness Security Hook Demo${NC}"
echo "================================="
echo ""
echo "Hook under test: bash-secret-guard.sh"
echo "Purpose: Block credential leak patterns before Claude Code executes Bash commands"
echo ""

echo "--- Commands that SHOULD be blocked ---"
run_test "cat .env"                    "cat .env"               "block"
run_test "grep password .env"          "grep password .env"     "block"
run_test "awk '{print}' .env"          "awk '{print}' .env"     "block"
run_test "sed -n '1p' .env"            "sed -n '1p' .env"       "block"
run_test "cat tokens.json"             "cat tokens.json"        "block"
run_test "cat credentials.json"        "cat credentials.json"   "block"
run_test 'echo $SECRET_TOKEN'          'echo $SECRET_TOKEN'     "block"
run_test 'echo $API_KEY'               'echo $API_KEY'          "block"
run_test "printenv"                    "printenv"               "block"

echo ""
echo "--- Commands that SHOULD pass ---"
run_test "wc -l .env (metadata only)"  "wc -l .env"            "pass"
run_test "[ -f .env ] && echo exists"  "[ -f .env ] && echo exists" "pass"
run_test "cat .env.example (template)" "cat .env.example"      "pass"
run_test "cat .env.1password (template)" "cat .env.1password"  "pass"
run_test "ls -la"                      "ls -la"                "pass"
run_test "git status"                  "git status"            "pass"
run_test "npm install"                 "npm install"           "pass"

echo ""
echo "================================="
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed. Hook is working correctly.${NC}"
    echo ""
    echo "This hook runs automatically as a PreToolUse event in Claude Code,"
    echo "blocking dangerous commands before they execute."
    exit 0
else
    echo -e "${RED}❌ $FAIL test(s) failed. Verify hook installation.${NC}"
    exit 1
fi
