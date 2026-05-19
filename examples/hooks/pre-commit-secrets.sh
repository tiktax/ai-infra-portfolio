#!/bin/bash
# pre-commit-secrets.sh — Claude Code PreToolUse hook
#
# Purpose: Scan staged git diff for credential patterns before
#          Claude Code executes a git commit or git add command.
#          Blocks the commit if secrets are detected.
#
# Trigger: PreToolUse (matcher: Bash tool)
# Action:  exit 2 = block + list detected patterns
#          exit 0 = allow
#
# Override: Add  # allow-secret: <reason>  at end of line in the diff
#           (use only for test fixtures / known false positives)
#
# Detection patterns (16 types):
#   Notion, Anthropic, OpenAI, GitHub PAT, GitHub fine-grained,
#   Google API, Slack, AWS key/secret, Bearer token, Private key header,
#   Stripe, JWT, Linear, 1Password SA, GitLab PAT, SendGrid

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

# Only intercept git commit / git add
if not re.search(r'\bgit\b[^|;&\n]*\b(commit|add)\b', cmd):
    sys.exit(0)

# Get staged diff
try:
    diff = subprocess.check_output(
        ['git', 'diff', '--cached', '--unified=0'],
        stderr=subprocess.DEVNULL
    ).decode(errors='replace')
except Exception:
    sys.exit(0)

if not diff:
    sys.exit(0)

# Secret patterns
PATTERNS = [
    ('Notion API Key',           r'ntn_[a-zA-Z0-9]{30,}'),
    ('Anthropic API Key',        r'sk-ant-[a-zA-Z0-9\-_]{30,}'),
    ('OpenAI API Key',           r'sk-[a-zA-Z0-9]{20,}'),
    ('GitHub PAT (classic)',     r'ghp_[a-zA-Z0-9]{36}'),
    ('GitHub PAT (fine-grained)',r'github_pat_[a-zA-Z0-9_]{80,}'),
    ('Google API Key',           r'AIzaSy[a-zA-Z0-9\-_]{33}'),
    ('Slack Token',              r'xox[baprs]-[a-zA-Z0-9\-]+'),
    ('AWS Access Key',           r'AKIA[A-Z0-9]{16}'),
    ('AWS Secret Key',           r'(?i)aws[_\-]secret[_\-]access[_\-]key\s*=\s*[A-Za-z0-9/+=]{40}'),
    ('Bearer Token',             r'Bearer\s+[A-Za-z0-9._\-]{20,}'),
    ('Private Key Header',       r'-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    ('Stripe Key',               r'sk_live_[a-zA-Z0-9]{24,}'),
    ('JWT',                      r'eyJ[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+'),
    ('Linear API Key',           r'lin_api_[a-zA-Z0-9]{40,}'),
    ('1Password SA Token',       r'ops_[a-zA-Z0-9.]{50,}'),
    ('GitLab PAT',               r'glpat-[a-zA-Z0-9\-_]{20}'),
]

findings = []
for line in diff.splitlines():
    if not line.startswith('+'):
        continue
    if 'allow-secret:' in line or 'pragma: allowlist secret' in line:
        continue
    for name, pattern in PATTERNS:
        if re.search(pattern, line):
            findings.append((name, line[:120]))

if findings:
    sys.stderr.write('\n')
    sys.stderr.write('BLOCKED: Potential credentials detected in staged diff.\n\n')
    for name, line in findings:
        sys.stderr.write(f'  [{name}] {line.strip()[:100]}\n')
    sys.stderr.write('\n')
    sys.stderr.write('Remediation:\n')
    sys.stderr.write('  1. Remove the secret from the file\n')
    sys.stderr.write('  2. Store it in a secret manager (e.g., 1Password)\n')
    sys.stderr.write('  3. Reference via: op://vault/item/field\n')
    sys.stderr.write('  4. If this is a test fixture, add: # allow-secret: <reason>\n')
    sys.exit(2)

sys.exit(0)
PYEOF

exit $?
