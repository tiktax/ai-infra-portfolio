#!/bin/bash
# npm-install-guard.sh — Claude Code PreToolUse hook
#
# Purpose: Inspect npm/pip/npx install commands before execution.
#          Blocks known typosquatting patterns and suspicious packages.
#
# Trigger: PreToolUse (matcher: Bash tool)
# Action:  exit 2 = block
#          exit 0 = allow

PAYLOAD=$(cat)

PAYLOAD="$PAYLOAD" python3 <<'PYEOF'
import os, sys, json, re

raw = os.environ.get('PAYLOAD', '')
try:
    payload = json.loads(raw)
    cmd = payload.get('tool_input', {}).get('command', '')
except Exception:
    sys.exit(0)

if not cmd:
    sys.exit(0)

# Only inspect install commands
if not re.search(r'\b(npm|yarn|pnpm|npx)\b[^|;&\n]*\b(install|add|dlx|exec)\b', cmd):
    sys.exit(0)

issues = []

# Typosquatting patterns (common AI/infra package mistakes)
TYPOSQUATS = [
    (r'\bexpresss\b',     'expresss → did you mean: express'),
    (r'\breacts\b',       'reacts → did you mean: react'),
    (r'\bnodemon\b.*\bfake', 'suspicious nodemon variant'),
    (r'\bcross-envs\b',   'cross-envs → did you mean: cross-env'),
    (r'\bmoment\.js\b',   'moment.js → package name is: moment'),
    (r'\blodash\.js\b',   'lodash.js → package name is: lodash'),
    (r'@anthropics/',     '@anthropics/ → did you mean: @anthropic-ai/'),
    (r'langchian',        'langchian → did you mean: langchain'),
]
for pattern, suggestion in TYPOSQUATS:
    if re.search(pattern, cmd, re.IGNORECASE):
        issues.append(f'Possible typosquatting: {suggestion}')

# Custom registry warning
if re.search(r'--registry\s+https?://(?!registry\.npmjs\.org|registry\.yarnpkg\.com)', cmd):
    issues.append('Custom npm registry detected. Verify the registry URL is trusted.')

# Deprecated flags that indicate old/copied code
if '--legacy-peer-deps' in cmd:
    issues.append('--legacy-peer-deps detected. Consider resolving peer dependency conflicts properly.')

if issues:
    sys.stderr.write('\n')
    sys.stderr.write(f'WARNING: Package install flagged — {len(issues)} issue(s).\n\n')
    for issue in issues:
        sys.stderr.write(f'  ⚠️  {issue}\n')
    sys.stderr.write('\n')
    sys.stderr.write('Verify the package name before proceeding.\n')
    sys.exit(2)

sys.exit(0)
PYEOF

exit $?
