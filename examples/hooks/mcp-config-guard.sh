#!/bin/bash
# mcp-config-guard.sh — Claude Code PreToolUse hook
#
# Purpose: Inspect MCP configuration file writes before they are applied.
#          Blocks changes that introduce:
#            - Non-TLS endpoints (MITM risk)
#            - Hardcoded tokens/credentials
#            - Known typosquatting package names
#
# Trigger: PreToolUse (matcher: Write / Edit tools targeting MCP config files)
# Action:  exit 2 = block + explain issue
#          exit 0 = allow
#
# Target files: .mcp.json, settings.json, settings.local.json

PAYLOAD=$(cat)

PAYLOAD="$PAYLOAD" python3 <<'PYEOF'
import os, sys, json, re

raw = os.environ.get('PAYLOAD', '')
try:
    payload = json.loads(raw)
    tool_name = payload.get('tool_name', '')
    tool_input = payload.get('tool_input', {})
except Exception:
    sys.exit(0)

# Determine target file
target_file = tool_input.get('file_path', '') or tool_input.get('path', '')
content = tool_input.get('content', '') or tool_input.get('new_string', '')

MCP_FILES = ('.mcp.json', 'settings.json', 'settings.local.json')
if not any(target_file.endswith(f) for f in MCP_FILES):
    sys.exit(0)

if not content:
    sys.exit(0)

issues = []

# Check for non-TLS endpoints
if re.search(r'http://(?!localhost|127\.0\.0\.1)', content):
    issues.append('Non-TLS endpoint detected (http:// to external host). Use https:// to prevent MITM.')

# Check for hardcoded credential patterns
CRED_PATTERNS = [
    ('Anthropic API Key',  r'sk-ant-[a-zA-Z0-9\-_]{20,}'),
    ('OpenAI API Key',     r'sk-[a-zA-Z0-9]{20,}'),
    ('GitHub PAT',         r'ghp_[a-zA-Z0-9]{30,}'),
    ('Google API Key',     r'AIzaSy[a-zA-Z0-9\-_]{30,}'),
    ('Bearer Token',       r'"Bearer\s+[A-Za-z0-9]{20,}"'),
    ('1Password SA Token', r'ops_[a-zA-Z0-9.]{50,}'),
]
for name, pattern in CRED_PATTERNS:
    if re.search(pattern, content):
        issues.append(f'Hardcoded {name} detected. Use env var reference: ${{VAR_NAME}} or op://vault/item/field')

# Check for suspicious package names (typosquatting patterns)
TYPOSQUAT = [r'@anthropics/', r'claudes', r'openais', r'langchian']
for pattern in TYPOSQUAT:
    if re.search(pattern, content, re.IGNORECASE):
        issues.append(f'Suspicious package name pattern: {pattern}. Verify the package name carefully.')

if issues:
    sys.stderr.write('\n')
    sys.stderr.write(f'BLOCKED: MCP config change rejected — {len(issues)} issue(s) found.\n\n')
    for i, issue in enumerate(issues, 1):
        sys.stderr.write(f'  {i}. {issue}\n')
    sys.stderr.write('\n')
    sys.stderr.write('Remediation:\n')
    sys.stderr.write('  - Use https:// for all external endpoints\n')
    sys.stderr.write('  - Store credentials in environment variables, not config files\n')
    sys.stderr.write('  - Verify package names against official registries\n')
    sys.exit(2)

sys.exit(0)
PYEOF

exit $?
