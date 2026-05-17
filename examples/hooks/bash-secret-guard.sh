#!/bin/bash
# bash-secret-guard.sh — Claude Code PreToolUse hook
#
# Purpose: Detect and block credential leak patterns in Bash commands
#          before Claude Code executes them.
# Trigger: PreToolUse (matcher: Bash tool)
# Action:  exit 2 = block execution + show remediation guidance
#
# Detected patterns:
#   - Reading .env / *.key / *.pem file contents (cat, grep, awk, sed, etc.)
#   - Displaying credential env vars via echo/printf ($TOKEN, $SECRET, etc.)
#   - Full environment dumps (printenv, env)
#   - Credentials in URL query parameters
#
# Template files (.env.1password, .env.example, etc.) are excluded from blocking.

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

reasons = []

# Template suffixes excluded from blocking (.env.1password, .env.example, etc.)
TEMPLATE_SUFFIX = r'(?!\.(?:1password|example|template|sample|tmpl|dist))'

# Commands that can dump file contents
DUMP_CMDS = r'cat|less|more|head|tail|xxd|hexdump|od|grep|egrep|fgrep|rg|awk|gawk|mawk|sed|strings|file|cut'

dump_pattern = (
    r'\b(' + DUMP_CMDS + r')\b'
    r'[^|;&]*'
    r'\.(env|key|pem|p12|pfx|crt)'
    + TEMPLATE_SUFFIX +
    r'(\s|$|[^a-zA-Z0-9])'
)
if re.search(dump_pattern, cmd):
    reasons.append('  - .env/.key/.pem file content access detected (cat/grep/awk/sed etc.)')

# Credential-specific files
SECRET_FILES = r'tokens\.json|credentials\.json|secrets\.(?:json|yaml|yml|toml|env)|service[_-]account.*\.json|client[_-]secret.*\.json'
secret_file_pattern = (
    r'\b(' + DUMP_CMDS + r')\b'
    r'[^|;&]*\b(' + SECRET_FILES + r')\b'
)
if re.search(secret_file_pattern, cmd):
    reasons.append('  - Direct access to tokens.json / credentials.json / secrets.* detected')

# echo/printf of credential env vars
env_echo_pattern = r'\b(echo|printf)\b[^|;&]*\$\{?[A-Z_]*(?:TOKEN|SECRET|KEY|PASSWORD|PASSWD|API[_-]?KEY|CREDENTIAL|AUTH)[A-Z_]*\}?'
if re.search(env_echo_pattern, cmd):
    reasons.append('  - echo/printf of credential environment variable detected')

# echo of actual token strings
if re.search(r'(echo|printf)\s+["\']?[^"\']*\b(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{30,}|AIzaSy[a-zA-Z0-9_-]{30,}|Bearer\s+[A-Za-z0-9._-]{30,})', cmd):
    reasons.append('  - echo/printf of actual token string detected')

# Full env dump
stripped = cmd.strip()
if re.search(r'\b(printenv|env)\b\s*(\||;|&)', cmd) or re.fullmatch(r'(printenv|env)', stripped):
    reasons.append('  - Full environment variable dump detected (printenv/env)')

# Credentials in URL parameters
if re.search(r'\b(curl|wget)\b[^|;&]*[?&](api[_-]?key|token|password|secret)=[A-Za-z0-9._-]{10,}', cmd):
    reasons.append('  - Credentials embedded in URL query parameters')

if reasons:
    sys.stderr.write('\n')
    sys.stderr.write('BLOCKED: Credential leak risk detected in Bash command.\n\n')
    sys.stderr.write('Detected:\n')
    sys.stderr.write('\n'.join(reasons) + '\n\n')
    sys.stderr.write('Command (first 120 chars):\n  ' + cmd[:120] + '\n\n')
    sys.stderr.write('Remediation:\n')
    sys.stderr.write('- Use secret manager CLI: op run --env-file=.env.template -- <cmd>\n')
    sys.stderr.write('- Read secrets via: op read op://vault/item/field\n')
    sys.stderr.write('- Check line count only: wc -l <file>\n')
    sys.stderr.write('- Check existence only: [ -f <file> ] && echo exists\n')
    sys.exit(2)

sys.exit(0)
PYEOF

exit $?
