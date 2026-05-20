#!/usr/bin/env bash
# install.sh — AI Harness automated installer
# Usage: bash install.sh [--role <role>] [--repo-path <path>] [--dry-run]
# Installs security hooks, merges settings.json, configures worktree-guard.
# Based on docs/deployment-playbook.md Steps 1-3 (automated).

set -euo pipefail

# ─────────────────────────────────────────
# Color output helpers
# ─────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { echo -e "${GREEN}[OK]${RESET}  $*"; }
err()  { echo -e "${RED}[ERR]${RESET} $*" >&2; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $*"; }
info() { echo -e "${CYAN}[INFO]${RESET} $*"; }
bold() { echo -e "${BOLD}$*${RESET}"; }

# ─────────────────────────────────────────
# Defaults
# ─────────────────────────────────────────
ROLE=""
REPO_PATH=""
DRY_RUN=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─────────────────────────────────────────
# Argument parsing
# ─────────────────────────────────────────
usage() {
  echo "Usage: bash install.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --role <engineer|analyst|manager>   Role to apply (optional)"
  echo "  --repo-path <path>                  Parent repo path for worktree-guard"
  echo "  --dry-run                           Preview only, no writes"
  echo "  --help                              Show this help"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role)
      ROLE="${2:-}"
      shift 2
      ;;
    --repo-path)
      REPO_PATH="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      usage
      ;;
    *)
      err "Unknown option: $1"
      usage
      ;;
  esac
done

# ─────────────────────────────────────────
# dry-run wrapper
# ─────────────────────────────────────────
dry_run_echo() {
  echo -e "${CYAN}[DRY-RUN]${RESET} would: $*"
}

# ─────────────────────────────────────────
# Pre-flight check
# ─────────────────────────────────────────
check_tool() {
  local tool="$1" required="$2"
  if ! command -v "$tool" &>/dev/null; then
    if [[ "$required" == "required" ]]; then
      err "Required tool not found: $tool"
      exit 1
    else
      warn "Optional tool not found: $tool (some features may be limited)"
    fi
  else
    ok "  $tool: $(command -v "$tool")"
  fi
}

bold "===================================================="
bold " AI Harness Installer"
bold "===================================================="
echo ""
bold "Step 0: Pre-flight check"

for tool in claude bash python3 git; do
  check_tool "$tool" "required"
done
for tool in jq op; do
  check_tool "$tool" "optional"
done

if [[ "$DRY_RUN" == "true" ]]; then
  warn "Running in DRY-RUN mode — no files will be written."
fi
echo ""

# ─────────────────────────────────────────
# Step 1: Hook copy
# ─────────────────────────────────────────
bold "Step 1: Installing hooks"

HOOKS_SRC="${SCRIPT_DIR}/examples/hooks"
HOOKS_DEST="${HOME}/.claude/hooks"

if [[ ! -d "$HOOKS_SRC" ]]; then
  err "Hooks source directory not found: $HOOKS_SRC"
  exit 1
fi

if [[ "$DRY_RUN" == "true" ]]; then
  dry_run_echo "mkdir -p $HOOKS_DEST"
  for f in "$HOOKS_SRC"/*.sh; do
    dry_run_echo "cp $(basename "$f") -> $HOOKS_DEST/$(basename "$f") && chmod +x"
  done
else
  mkdir -p "$HOOKS_DEST"
  for f in "$HOOKS_SRC"/*.sh; do
    dest="$HOOKS_DEST/$(basename "$f")"
    if ! diff -q "$f" "$dest" &>/dev/null 2>&1; then
      cp "$f" "$dest"
      chmod +x "$dest"
      ok "  Installed: $(basename "$f")"
    else
      info "  Up to date: $(basename "$f")"
    fi
  done
fi
echo ""

# ─────────────────────────────────────────
# Step 2: settings.json merge
# ─────────────────────────────────────────
bold "Step 2: Merging hooks into settings.json"

SETTINGS_FILE="${HOME}/.claude/settings.json"

# Hooks definition as a shell variable (for python fallback)
HOOKS_JSON='{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "bash ~/.claude/hooks/bash-secret-guard.sh" },
          { "type": "command", "command": "bash ~/.claude/hooks/worktree-guard.sh" },
          { "type": "command", "command": "bash ~/.claude/hooks/npm-install-guard.sh" },
          { "type": "command", "command": "bash ~/.claude/hooks/pre-commit-secrets.sh" }
        ]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": "bash ~/.claude/hooks/mcp-config-guard.sh" }
        ]
      }
    ]
  }
}'

# Merge function using jq
merge_with_jq() {
  local settings_file="$1"
  local backup="${settings_file}.bak.$(date +%Y%m%d%H%M%S)"

  cp "$settings_file" "$backup"
  info "  Backup created: $backup"

  # Merge strategy:
  # - For each matcher group in our new hooks, check existing commands and skip duplicates
  jq --argjson new_hooks "$HOOKS_JSON" '
    . as $existing |
    $new_hooks.hooks as $nh |

    # Helper: extract all command strings from a hooks array
    # Build merged PreToolUse by combining existing and new, deduplicating by command string
    ($existing.hooks.PreToolUse // []) as $existing_ptu |
    ($nh.PreToolUse // []) as $new_ptu |

    # Collect all existing command strings
    [$existing_ptu[].hooks[].command] as $existing_cmds |

    # For each new matcher group, filter out already-present commands
    ($new_ptu | map(
      . as $group |
      {
        matcher: $group.matcher,
        hooks: ($group.hooks | map(select(.command as $c | $existing_cmds | index($c) == null)))
      } |
      select(.hooks | length > 0)
    )) as $filtered_new |

    # Merge: existing PreToolUse + filtered new groups
    . + {
      hooks: ((.hooks // {}) + {
        PreToolUse: ($existing_ptu + $filtered_new)
      })
    }
  ' "$settings_file" > /tmp/claude-settings-tmp.json && mv /tmp/claude-settings-tmp.json "$settings_file"
}

# Merge function using python3 (fallback when jq is unavailable)
merge_with_python() {
  local settings_file="$1"
  local backup="${settings_file}.bak.$(date +%Y%m%d%H%M%S)"

  cp "$settings_file" "$backup"
  info "  Backup created: $backup"

  python3 - "$settings_file" <<'PYEOF'
import json, sys

settings_path = sys.argv[1]

new_hooks_def = {
    "PreToolUse": [
        {
            "matcher": "Bash",
            "hooks": [
                {"type": "command", "command": "bash ~/.claude/hooks/bash-secret-guard.sh"},
                {"type": "command", "command": "bash ~/.claude/hooks/worktree-guard.sh"},
                {"type": "command", "command": "bash ~/.claude/hooks/npm-install-guard.sh"},
                {"type": "command", "command": "bash ~/.claude/hooks/pre-commit-secrets.sh"},
            ]
        },
        {
            "matcher": "Write|Edit",
            "hooks": [
                {"type": "command", "command": "bash ~/.claude/hooks/mcp-config-guard.sh"},
            ]
        }
    ]
}

with open(settings_path, 'r') as f:
    settings = json.load(f)

existing_hooks = settings.setdefault('hooks', {})
existing_ptu = existing_hooks.setdefault('PreToolUse', [])

# Collect all existing command strings to deduplicate
existing_cmds = set()
for group in existing_ptu:
    for h in group.get('hooks', []):
        if 'command' in h:
            existing_cmds.add(h['command'])

# For each new matcher group, filter out already-present commands
for group in new_hooks_def.get('PreToolUse', []):
    filtered_hooks = [h for h in group.get('hooks', [])
                      if h.get('command') not in existing_cmds]
    if filtered_hooks:
        existing_ptu.append({
            'matcher': group['matcher'],
            'hooks': filtered_hooks
        })

with open(settings_path + '.tmp', 'w') as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write('\n')

import os
os.replace(settings_path + '.tmp', settings_path)
PYEOF
}

if [[ "$DRY_RUN" == "true" ]]; then
  dry_run_echo "ensure $SETTINGS_FILE exists (create from {} if missing)"
  dry_run_echo "merge hooks blocks into $SETTINGS_FILE (deduplication enabled)"
else
  # Ensure settings.json exists
  if [[ ! -f "$SETTINGS_FILE" ]]; then
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    echo '{}' > "$SETTINGS_FILE"
    info "  Created new settings.json"
  fi

  if command -v jq &>/dev/null; then
    info "  Using jq for merge"
    merge_with_jq "$SETTINGS_FILE"
    ok "  settings.json updated via jq"
  else
    info "  jq not found — using python3 fallback"
    merge_with_python "$SETTINGS_FILE"
    ok "  settings.json updated via python3"
  fi
fi
echo ""

# ─────────────────────────────────────────
# Step 3: worktree-guard path configuration
# ─────────────────────────────────────────
bold "Step 3: Configuring worktree-guard"

if [[ -z "$REPO_PATH" ]]; then
  if [[ "$DRY_RUN" == "true" ]]; then
    dry_run_echo "interactive prompt: Enter your parent repo path"
    REPO_PATH="<repo-path-not-provided>"
  else
    read -rp "Enter your parent repo path (e.g. ~/projects/myorg): " REPO_PATH
  fi
fi

# Expand ~ to $HOME
REPO_PATH="${REPO_PATH/#\~/$HOME}"

GUARD_FILE="${HOME}/.claude/hooks/worktree-guard.sh"

if [[ "$DRY_RUN" == "true" ]]; then
  dry_run_echo "sed: update PARENT_REPO in $GUARD_FILE -> '${REPO_PATH}'"
else
  if [[ -f "$GUARD_FILE" ]]; then
    sed -i.bak "s|PARENT_REPO = os.path.expanduser('.*')|PARENT_REPO = os.path.expanduser('${REPO_PATH}')|" \
      "$GUARD_FILE"
    ok "  worktree-guard configured: PARENT_REPO = ${REPO_PATH}"
  else
    warn "  worktree-guard.sh not found at $GUARD_FILE — skipping path update"
  fi
fi
echo ""

# ─────────────────────────────────────────
# Step 4: Run demo.sh
# ─────────────────────────────────────────
bold "Step 4: Running demo"

DEMO_SCRIPT="${SCRIPT_DIR}/demo.sh"

if [[ "$DRY_RUN" == "true" ]]; then
  dry_run_echo "bash $DEMO_SCRIPT (skipped in dry-run)"
else
  if [[ -f "$DEMO_SCRIPT" ]]; then
    bash "$DEMO_SCRIPT"
  else
    info "  demo.sh not found — skipping"
  fi
fi
echo ""

# ─────────────────────────────────────────
# Step 5: Log installation
# ─────────────────────────────────────────
bold "Step 5: Recording installation log"

LOG_FILE="${HOME}/.claude/install-log.jsonl"

if [[ "$DRY_RUN" == "true" ]]; then
  dry_run_echo "append entry to $LOG_FILE"
else
  mkdir -p "$(dirname "$LOG_FILE")"
  python3 -c "
import json, datetime, os, getpass
entry = {
  'installed_at': datetime.datetime.utcnow().isoformat() + 'Z',
  'installed_by': os.environ.get('USER', getpass.getuser()),
  'role': '${ROLE:-none}',
  'repo_path': '${REPO_PATH:-unknown}',
  'dry_run': ${DRY_RUN}
}
print(json.dumps(entry))
" >> "$LOG_FILE"
  ok "  Logged to $LOG_FILE"
fi
echo ""

# ─────────────────────────────────────────
# Completion summary
# ─────────────────────────────────────────
bold "=================================================="
bold " AI Harness installation complete!"
bold "=================================================="
echo "  Hooks:          ~/.claude/hooks/ ($(ls "$HOOKS_SRC"/*.sh 2>/dev/null | wc -l | tr -d ' ') files)"
echo "  Settings:       ~/.claude/settings.json (hooks merged)"
echo "  Worktree guard: configured for ${REPO_PATH:-<not set>}"
if [[ -n "$ROLE" ]]; then
  echo "  Role:           ${ROLE}"
fi
echo ""
echo "  Next: bash tools/claude-config-manager/manage.sh install --role <role>"
bold "=================================================="
