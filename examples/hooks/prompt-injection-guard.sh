#!/usr/bin/env bash
# prompt-injection-guard.sh — PreToolUse hook: detect goal hijacking / prompt injection
#
# Purpose: Detect ASI01 (Goal Hijacking) — attempts to override the AI's instructions
#          via crafted input in Bash commands or file write content.
# Trigger: PreToolUse (Bash, Write, Edit)
# Action:  exit 2 = block + show remediation
#
# Detected patterns (case-insensitive, designed to catch common injection templates):
#   - "ignore previous instructions" / "disregard your system prompt"
#   - "you are now" / "forget your instructions" / "new persona"
#   - "act as" / "pretend you are" / "your new instructions are"
#   - "override your" / "bypass your" / "remove all restrictions"
#   - "unrestricted mode" / "developer mode" / "DAN mode"
#   - CLAUDE.md / system prompt file write with dangerous override keywords
#
# Override: append  # injection-guard:allow  to the command line to bypass
# (requires manual review — creates a permanent record in the block log)
#
# OWASP Agentic AI Top 10: ASI01 — Goal Hijacking
#
# Test:
#   echo '{"tool_name":"Bash","tool_input":{"command":"echo ignore previous instructions"}}' | bash prompt-injection-guard.sh
#   echo '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' | bash prompt-injection-guard.sh

set -euo pipefail

PAYLOAD=$(cat)

PAYLOAD="$PAYLOAD" python3 <<'PYEOF'
import os, sys, json, re

INJECTION_PATTERNS = [
    # Classic instruction override
    (re.compile(r'ignore\s+(all\s+)?previous\s+instructions?', re.I), 'instruction_override'),
    (re.compile(r'disregard\s+(your\s+)?(system\s+)?prompt', re.I), 'system_prompt_override'),
    (re.compile(r'forget\s+(all\s+)?(your\s+)?instructions?', re.I), 'instruction_erasure'),
    # Persona hijacking
    (re.compile(r'\byou\s+are\s+now\b', re.I), 'persona_hijack'),
    (re.compile(r'\bnew\s+persona\b', re.I), 'persona_hijack'),
    (re.compile(r'\bact\s+as\s+(?!a\s+(?:developer|user|reviewer))', re.I), 'persona_hijack'),
    (re.compile(r'\bpretend\s+you\s+are\b', re.I), 'persona_hijack'),
    # Instruction injection
    (re.compile(r'\byour\s+new\s+instructions?\s+are\b', re.I), 'instruction_injection'),
    (re.compile(r'\boverride\s+your\b', re.I), 'constraint_bypass'),
    (re.compile(r'\bbypass\s+your\b', re.I), 'constraint_bypass'),
    (re.compile(r'\bremove\s+all\s+restrictions?\b', re.I), 'constraint_bypass'),
    # Mode switching attacks
    (re.compile(r'\bunrestricted\s+mode\b', re.I), 'mode_switch'),
    (re.compile(r'\bdeveloper\s+mode\b', re.I), 'mode_switch'),
    (re.compile(r'\bdan\s+mode\b', re.I), 'mode_switch'),
    (re.compile(r'\bjailbreak\b', re.I), 'mode_switch'),
]

# File paths that are especially sensitive (system prompt / memory files)
SENSITIVE_PATHS = re.compile(
    r'CLAUDE\.md$|\.claude/|system[-_]?prompt|governance.*\.md$',
    re.I
)

BYPASS_MARKER = '# injection-guard:allow'

raw = os.environ.get('PAYLOAD', '')
try:
    payload = json.loads(raw)
except Exception:
    sys.exit(0)

tool_name = payload.get('tool_name', '')
tool_input = payload.get('tool_input', {})

# Determine target(s) to inspect
targets = []

if tool_name == 'Bash':
    cmd = tool_input.get('command', '')
    # Respect bypass marker — must appear at end of command (trailing whitespace ignored)
    if cmd.rstrip().endswith(BYPASS_MARKER):
        sys.exit(0)
    targets.append(('command', cmd))

elif tool_name in ('Write', 'Edit'):
    file_path = tool_input.get('file_path', '')
    content = tool_input.get('content', tool_input.get('new_string', ''))
    # Always inspect content going into sensitive files
    targets.append(('content', content))
    # Also flag if the file path itself is a sensitive governance file
    if SENSITIVE_PATHS.search(file_path):
        targets.append(('file_path', file_path))

else:
    sys.exit(0)

# Run pattern matching
for target_type, text in targets:
    if not text:
        continue
    for pattern, category in INJECTION_PATTERNS:
        match = pattern.search(text)
        if match:
            matched_text = match.group(0)
            sys.stderr.write(
                f'\n🚫 [ASI01] Prompt injection detected — {category}\n'
                f'   Pattern: "{matched_text}" in {tool_name} {target_type}\n'
                f'   This input matches a known goal-hijacking template.\n'
                f'   If this is a legitimate test/documentation, append: {BYPASS_MARKER}\n'
            )
            # Write structured block log entry for circuit breaker
            import datetime
            block_log = os.path.expanduser('~/.claude/hook-block.log')
            ts = datetime.datetime.now(datetime.timezone.utc).isoformat().replace('+00:00', 'Z')
            try:
                with open(block_log, 'a') as f:
                    f.write(f'{ts} BLOCKED prompt_injection category={category}\n')
            except Exception:
                pass
            sys.exit(2)

sys.exit(0)
PYEOF

exit $?
