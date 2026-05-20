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

# ── mcp-config-guard tests ───────────────────────────────────────────────────

test_mcp_config_guard() {
    echo -e "\n${CYAN}▶ mcp-config-guard.sh${NC}"
    echo "  Blocks unsafe MCP config writes (non-TLS endpoints, hardcoded credentials, typosquatting)"

    # --- Should BLOCK ---
    run_hook_test "mcp-config-guard" \
        "non-TLS external endpoint in .mcp.json" \
        '{"tool_name":"Write","tool_input":{"file_path":".mcp.json","content":"{\"server\":{\"url\":\"http://external-api.example.com/mcp\"}}"}}' \
        "block"

    run_hook_test "mcp-config-guard" \
        "hardcoded Anthropic API key in settings.json" \
        '{"tool_name":"Write","tool_input":{"file_path":"settings.json","content":"{\"api_key\":\"sk-ant-abcdefghij1234567890klmnop\"}"}}' \
        "block"

    run_hook_test "mcp-config-guard" \
        "hardcoded GitHub PAT in settings.json" \
        '{"tool_name":"Edit","tool_input":{"path":"settings.json","new_string":"{\"token\":\"ghp_abcdefghijklmnopqrstuvwxyz123456\"}"}}' \
        "block"

    run_hook_test "mcp-config-guard" \
        "typosquatting package @anthropics/ in .mcp.json" \
        '{"tool_name":"Write","tool_input":{"file_path":".mcp.json","content":"{\"packages\":[\"@anthropics/sdk\"]}"}}' \
        "block"

    # --- Should PASS ---
    run_hook_test "mcp-config-guard" \
        "env var reference (safe) in settings.json" \
        '{"tool_name":"Write","tool_input":{"file_path":"settings.json","content":"{\"api_key\":\"${ANTHROPIC_API_KEY}\"}"}}' \
        "pass"

    run_hook_test "mcp-config-guard" \
        "HTTPS endpoint (safe) in .mcp.json" \
        '{"tool_name":"Write","tool_input":{"file_path":".mcp.json","content":"{\"server\":{\"url\":\"https://api.example.com/mcp\"}}"}}' \
        "pass"

    run_hook_test "mcp-config-guard" \
        "localhost http (safe) in .mcp.json" \
        '{"tool_name":"Write","tool_input":{"file_path":".mcp.json","content":"{\"server\":{\"url\":\"http://127.0.0.1:3000\"}}"}}' \
        "pass"

    run_hook_test "mcp-config-guard" \
        "correct package name @anthropic-ai/ in .mcp.json" \
        '{"tool_name":"Write","tool_input":{"file_path":".mcp.json","content":"{\"packages\":[\"@anthropic-ai/sdk\"]}"}}' \
        "pass"

    run_hook_test "mcp-config-guard" \
        "write to unrelated file (not intercepted)" \
        '{"tool_name":"Write","tool_input":{"file_path":"README.md","content":"# hello"}}' \
        "pass"
}

# ── pre-commit-secrets tests ──────────────────────────────────────────────────

test_pre_commit_secrets() {
    echo -e "\n${CYAN}▶ pre-commit-secrets.sh${NC}"
    echo "  Scans staged git diff for 16 credential patterns before commit"

    # pre-commit-secrets depends on 'git diff --cached' output.
    # We test the pattern-matching logic directly by mocking a git environment.

    local TMPDIR_TEST
    TMPDIR_TEST=$(mktemp -d)
    trap "rm -rf $TMPDIR_TEST" RETURN

    # Initialize a temporary git repo for staging tests
    git -C "$TMPDIR_TEST" init -q
    git -C "$TMPDIR_TEST" config user.email "test@example.com"
    git -C "$TMPDIR_TEST" config user.name "Test"

    run_staged_test() {
        local desc="$1"
        local file_content="$2"
        local expected="$3"
        local fname="test_file.txt"

        echo "$file_content" > "$TMPDIR_TEST/$fname"
        git -C "$TMPDIR_TEST" add "$fname" 2>/dev/null

        local payload
        payload='{"tool_input":{"command":"git commit -m test"}}'
        local exit_code=0
        (cd "$TMPDIR_TEST" && echo "$payload" | bash "$HOOKS_DIR/pre-commit-secrets.sh") 2>/dev/null || exit_code=$?

        git -C "$TMPDIR_TEST" restore --staged "$fname" 2>/dev/null || true

        if [ "$expected" = "block" ] && [ "$exit_code" = "2" ]; then
            echo -e "  ${GREEN}✅ BLOCK${NC}  $desc"
            ((TOTAL_PASS++))
        elif [ "$expected" = "pass" ] && [ "$exit_code" = "0" ]; then
            echo -e "  ${GREEN}✅ PASS${NC}   $desc"
            ((TOTAL_PASS++))
        else
            echo -e "  ${RED}❌ FAIL${NC}   $desc — expected '$expected', got exit $exit_code"
            ((TOTAL_FAIL++))
        fi
    }

    # --- Should BLOCK ---
    run_staged_test \
        "Anthropic API key in staged file" \
        "ANTHROPIC_KEY=sk-ant-abcdefghijklmnopqrstuvwxyz1234" \
        "block"

    run_staged_test \
        "GitHub PAT in staged file" \
        "token=ghp_abcdefghijklmnopqrstuvwxyz123456" \
        "block"

    run_staged_test \
        "AWS Access Key in staged file" \
        "AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE" \
        "block"

    run_staged_test \
        "Private key header in staged file" \
        "-----BEGIN RSA PRIVATE KEY-----" \
        "block"

    # --- Should PASS ---
    run_staged_test \
        "clean file with no secrets" \
        "DATABASE_URL=postgres://localhost/mydb" \
        "pass"

    run_staged_test \
        "env var reference (not a real token)" \
        'API_KEY=${ANTHROPIC_API_KEY}' \
        "pass"

    run_staged_test \
        "allowed secret override comment" \
        "test_key=sk-ant-0000000000000000000000000000test  # allow-secret: test fixture" \
        "pass"

    # --- Non-commit command (should always pass) ---
    run_hook_test "pre-commit-secrets" \
        "non-commit command not intercepted" \
        '{"tool_input":{"command":"git status"}}' \
        "pass"
}

# ── worktree-guard tests ──────────────────────────────────────────────────────

test_worktree_guard() {
    echo -e "\n${CYAN}▶ worktree-guard.sh${NC}"
    echo "  Note: Full block test requires parent repo + main branch context."
    echo "  Testing pass cases and override mechanism only (environment-independent)."

    # --- Should PASS (non-write operations) ---
    run_hook_test "worktree-guard" \
        "git log (read-only, not intercepted)" \
        '{"tool_input":{"command":"git log --oneline"}}' \
        "pass"

    run_hook_test "worktree-guard" \
        "git status (read-only, not intercepted)" \
        '{"tool_input":{"command":"git status"}}' \
        "pass"

    run_hook_test "worktree-guard" \
        "git diff (read-only, not intercepted)" \
        '{"tool_input":{"command":"git diff HEAD"}}' \
        "pass"

    run_hook_test "worktree-guard" \
        "git commit with worktree-guard:allow override" \
        '{"tool_input":{"command":"git commit -m fix  # worktree-guard:allow"}}' \
        "pass"

    run_hook_test "worktree-guard" \
        "non-git command (not intercepted)" \
        '{"tool_input":{"command":"ls -la"}}' \
        "pass"

    echo -e "  ${YELLOW}ℹ️  BLOCK cases require: parent repo cwd + main branch.${NC}"
    echo -e "     See examples/incidents/INC-013-redacted.md for context."
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

if [ "$FILTER" = "all" ] || ([ "$FILTER" = "--hook" ] && [ "${2:-}" = "bash-secret-guard" ]); then
    test_bash_secret_guard
fi

if [ "$FILTER" = "all" ] || ([ "$FILTER" = "--hook" ] && [ "${2:-}" = "npm-install-guard" ]); then
    test_npm_install_guard
fi

if [ "$FILTER" = "all" ] || ([ "$FILTER" = "--hook" ] && [ "${2:-}" = "mcp-config-guard" ]); then
    test_mcp_config_guard
fi

if [ "$FILTER" = "all" ] || ([ "$FILTER" = "--hook" ] && [ "${2:-}" = "pre-commit-secrets" ]); then
    test_pre_commit_secrets
fi

if [ "$FILTER" = "all" ] || ([ "$FILTER" = "--hook" ] && [ "${2:-}" = "worktree-guard" ]); then
    test_worktree_guard
fi

print_summary
