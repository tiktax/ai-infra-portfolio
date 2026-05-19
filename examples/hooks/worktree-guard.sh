#!/bin/bash
# worktree-guard.sh — Claude Code PreToolUse hook
#
# Purpose: Block write-type git operations on the parent (main) repository
#          when Claude Code is running inside a git worktree.
#          Prevents accidental commits directly to main instead of the worktree.
#
# Trigger: PreToolUse (matcher: Bash tool)
# Action:  exit 2 = block + show remediation guidance
#          exit 0 = allow
#
# Override: Add  # worktree-guard:allow  at end of a command to bypass.
# Based on: INC-013 — accidental main branch commit from worktree session.

PAYLOAD=$(cat)

PAYLOAD="$PAYLOAD" python3 <<'PYEOF'
import os, sys, json, re, subprocess

raw = os.environ.get('PAYLOAD', '')
try:
    payload = json.loads(raw)
    cmd = payload.get('tool_input', {}).get('command', '')
except Exception:
    sys.exit(0)

if not cmd:
    sys.exit(0)

# Allow explicit override
if 'worktree-guard:allow' in cmd:
    sys.exit(0)

# Git write operations that should only run inside a worktree
WRITE_OPS = r'\b(git)\b[^|;&\n]*\b(commit|push|merge|reset|cherry-pick|rebase|rm|add|restore|checkout|switch|tag|branch -[dD])\b'
if not re.search(WRITE_OPS, cmd):
    sys.exit(0)

# Detect current working directory and parent repo
try:
    cwd = os.getcwd()
    toplevel = subprocess.check_output(
        ['git', 'rev-parse', '--show-toplevel'],
        stderr=subprocess.DEVNULL, cwd=cwd
    ).decode().strip()
    branch = subprocess.check_output(
        ['git', 'branch', '--show-current'],
        stderr=subprocess.DEVNULL, cwd=cwd
    ).decode().strip()
except Exception:
    sys.exit(0)

# Configure your parent repo path here
PARENT_REPO = os.path.expanduser('~/<your-project-parent>')

is_parent = (toplevel == PARENT_REPO or toplevel.rstrip('/') == PARENT_REPO.rstrip('/'))
is_main_branch = branch in ('main', 'master')

if is_parent and is_main_branch:
    sys.stderr.write('\n')
    sys.stderr.write('BLOCKED: git write operation on parent repo main branch.\n\n')
    sys.stderr.write(f'  CWD:    {cwd}\n')
    sys.stderr.write(f'  Branch: {branch}\n\n')
    sys.stderr.write('This session appears to be running in the parent repo, not a worktree.\n\n')
    sys.stderr.write('Remediation:\n')
    sys.stderr.write('  1. Create or re-enter a worktree for this task\n')
    sys.stderr.write('  2. Run git operations from inside the worktree\n')
    sys.stderr.write('  3. To bypass intentionally: add  # worktree-guard:allow  to the command\n\n')
    sys.exit(2)

sys.exit(0)
PYEOF

exit $?
