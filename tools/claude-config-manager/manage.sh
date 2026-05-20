#!/bin/bash
# manage.sh — Multi-user CLAUDE.md Manager
#
# Installs role-specific CLAUDE.md configurations for team members.
# Combines a shared base policy with role-specific rules and records
# an audit trail of installations.
#
# Usage:
#   ./manage.sh install --role engineer   # install engineer config
#   ./manage.sh list                      # show current role and version
#   ./manage.sh verify                    # check if config is up to date
#   ./manage.sh audit                     # show installation history
#   ./manage.sh roles                     # list available roles
#
# Roles: engineer | analyst | manager

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/configs"
CLAUDE_DIR="${HOME}/.claude"
TARGET="$CLAUDE_DIR/CLAUDE.md"
META_FILE="$CLAUDE_DIR/.config-meta.json"

VALID_ROLES="engineer analyst manager"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Convenience wrappers used by merge_permissions / cmd_escalate
ok()   { echo -e "${GREEN}✅ $*${NC}"; }
info() { echo -e "${CYAN}ℹ  $*${NC}"; }
warn() { echo -e "${YELLOW}⚠  $*${NC}"; }
err()  { echo -e "${RED}❌ $*${NC}"; }
bold() { echo -e "${BOLD}$*${NC}"; }
DRY_RUN="${DRY_RUN:-false}"

# ── Helpers ──────────────────────────────────────────────────────────────────

version_of() {
    local file="$1"
    # Extract version from header comment: # Version: 1.0.0
    grep -m1 '^# Version:' "$file" 2>/dev/null | awk '{print $3}' || echo "unversioned"
}

hash_of() {
    local file="$1"
    if command -v md5sum &>/dev/null; then
        md5sum "$file" | awk '{print $1}'
    else
        md5 -q "$file"
    fi
}

read_meta() {
    local key="$1"
    if [ -f "$META_FILE" ]; then
        python3 -c "
import json, sys
data = json.load(open('$META_FILE'))
history = data.get('history', [])
latest = history[-1] if history else {}
print(latest.get('$key', 'unknown'))
" 2>/dev/null || echo "unknown"
    else
        echo "not installed"
    fi
}

write_meta() {
    local role="$1"
    local version="$2"
    local hash="$3"
    local installed_by
    installed_by="$(git config user.name 2>/dev/null || echo "$USER")"

    python3 - <<PYEOF
import json, os
from datetime import datetime, timezone

meta_file = '$META_FILE'
data = {}
if os.path.exists(meta_file):
    try:
        data = json.load(open(meta_file))
    except Exception:
        data = {}

history = data.get('history', [])
history.append({
    'role': '$role',
    'version': '$version',
    'hash': '$hash',
    'installed_at': datetime.now(timezone.utc).isoformat(),
    'installed_by': '$installed_by'
})

data['history'] = history
data['current'] = history[-1]

with open(meta_file, 'w') as f:
    json.dump(data, f, indent=2)
PYEOF
}

# ---------------------------------------------------------------------------
# Merge role-specific permissions into ~/.claude/settings.json
# ---------------------------------------------------------------------------
merge_permissions() {
  local role="$1"
  local perms_file="${CONFIGS_DIR}/${role}-permissions.json"
  local settings_file="${CLAUDE_DIR}/settings.json"

  if [[ ! -f "$perms_file" ]]; then
    warn "No permissions file for role '${role}': ${perms_file}"
    return 0
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[DRY-RUN] Would merge permissions from ${perms_file} into ${settings_file}"
    return 0
  fi

  # Backup settings.json
  local backup="${settings_file}.bak.$(date +%Y%m%d%H%M%S)"
  if [[ -f "$settings_file" ]]; then
    cp "$settings_file" "$backup"
  else
    echo '{}' > "$settings_file"
  fi

  # Merge permissions using python3 (jq-independent)
  python3 - <<PYEOF
import json, sys

with open('${settings_file}') as f:
    settings = json.load(f)

with open('${perms_file}') as f:
    role_perms = json.load(f).get('permissions', {})

if 'permissions' not in settings:
    settings['permissions'] = {}

# Merge allow (union, no duplicates)
existing_allow = settings['permissions'].get('allow', [])
new_allow = role_perms.get('allow', [])
settings['permissions']['allow'] = list(dict.fromkeys(existing_allow + new_allow))

# Merge deny (union, no duplicates)
existing_deny = settings['permissions'].get('deny', [])
new_deny = role_perms.get('deny', [])
settings['permissions']['deny'] = list(dict.fromkeys(existing_deny + new_deny))

# Merge additionalDirectories (union, no duplicates)
existing_dirs = settings['permissions'].get('additionalDirectories', [])
new_dirs = role_perms.get('additionalDirectories', [])
settings['permissions']['additionalDirectories'] = list(dict.fromkeys(existing_dirs + new_dirs))

with open('${settings_file}', 'w') as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write('\n')

print(f"Permissions merged for role: ${role}")
PYEOF

  ok "Permissions applied: ${role} → ${settings_file}"
  ok "Backup: ${backup}"

  # Record permissions_hash in meta
  local perms_hash
  perms_hash="$(md5sum "${perms_file}" 2>/dev/null | awk '{print $1}' || md5 -q "${perms_file}" 2>/dev/null)"
  write_permissions_meta "${role}" "${perms_hash}"
}

write_permissions_meta() {
  local role="$1"
  local perms_hash="$2"
  local meta_file="${CLAUDE_DIR}/.config-meta.json"

  python3 - <<PYEOF
import json, datetime

try:
    with open('${meta_file}') as f:
        meta = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    meta = {'history': [], 'current': {}}

if meta['history']:
    meta['history'][-1]['permissions_hash'] = '${perms_hash}'
    meta['history'][-1]['permissions_role'] = '${role}'
    meta['current']['permissions_hash'] = '${perms_hash}'
    meta['current']['permissions_role'] = '${role}'

with open('${meta_file}', 'w') as f:
    json.dump(meta, f, indent=2)
PYEOF
}

# ── Commands ─────────────────────────────────────────────────────────────────

cmd_install() {
    local role=""
    local dry_run=false
    local force=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --role) role="$2"; shift 2 ;;
            --dry-run) dry_run=true; shift ;;
            --force) force=true; shift ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
    done

    if [ -z "$role" ]; then
        echo -e "${RED}Error: --role is required${NC}"
        echo "Usage: ./manage.sh install --role <engineer|analyst|manager>"
        exit 1
    fi

    if ! echo "$VALID_ROLES" | grep -qw "$role"; then
        echo -e "${RED}Error: unknown role '$role'${NC}"
        echo "Available roles: $VALID_ROLES"
        exit 1
    fi

    local base_file="$CONFIGS_DIR/base.md"
    local role_file="$CONFIGS_DIR/${role}.md"

    if [ ! -f "$base_file" ]; then
        echo -e "${RED}Error: base.md not found at $base_file${NC}"
        exit 1
    fi

    if [ ! -f "$role_file" ]; then
        echo -e "${RED}Error: role config not found at $role_file${NC}"
        exit 1
    fi

    local base_version; base_version=$(version_of "$base_file")
    local role_version; role_version=$(version_of "$role_file")
    local combined_version="${base_version}+${role_version}"

    # Check if already installed with same version
    if [ "$force" = false ] && [ -f "$TARGET" ]; then
        local current_role; current_role=$(read_meta "role")
        local current_version; current_version=$(read_meta "version")
        if [ "$current_role" = "$role" ] && [ "$current_version" = "$combined_version" ]; then
            echo -e "${YELLOW}Already up to date:${NC} role=$role version=$combined_version"
            echo "Use --force to reinstall."
            exit 0
        fi
    fi

    echo -e "${CYAN}Installing CLAUDE.md...${NC}"
    echo "  Role:    $role"
    echo "  Version: $combined_version"
    echo "  Target:  $TARGET"
    echo ""

    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}[DRY RUN] Would write:${NC}"
        echo "──────────────────────────────────"
        {
            echo "# CLAUDE.md — Role: ${role} | Version: ${combined_version}"
            echo "# Generated by claude-config-manager on $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
            echo "# DO NOT EDIT MANUALLY — changes will be overwritten on next install"
            echo ""
            cat "$base_file"
            echo ""
            echo "---"
            echo ""
            cat "$role_file"
        } | head -30
        echo "... (truncated)"
        echo "──────────────────────────────────"
        echo -e "${YELLOW}[DRY RUN] No changes made.${NC}"
        exit 0
    fi

    # Backup existing
    if [ -f "$TARGET" ]; then
        local backup="${TARGET}.bak.$(date +%Y%m%d%H%M%S)"
        cp "$TARGET" "$backup"
        echo -e "  Backup:  $(basename "$backup")"
    fi

    # Combine base + role → target
    mkdir -p "$CLAUDE_DIR"
    {
        echo "# CLAUDE.md — Role: ${role} | Version: ${combined_version}"
        echo "# Generated by claude-config-manager on $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        echo "# DO NOT EDIT MANUALLY — run './manage.sh install --role ${role}' to update"
        echo ""
        cat "$base_file"
        echo ""
        echo "---"
        echo ""
        cat "$role_file"
    } > "$TARGET"

    local installed_hash; installed_hash=$(hash_of "$TARGET")
    write_meta "$role" "$combined_version" "$installed_hash"

    # Apply role-based permissions to settings.json
    info "Applying role-based permissions..."
    merge_permissions "$role"

    echo -e "${GREEN}✅ Installed successfully.${NC}"
    echo ""
    echo "Next steps:"
    echo "  Restart Claude Code to apply the new configuration."
    echo "  Run './manage.sh verify' to confirm the installation."
}

cmd_list() {
    echo -e "${BOLD}Current CLAUDE.md Configuration${NC}"
    echo "────────────────────────────────"

    if [ ! -f "$TARGET" ]; then
        echo -e "${YELLOW}Not installed.${NC} Run: ./manage.sh install --role <role>"
        exit 0
    fi

    local role; role=$(read_meta "role")
    local version; version=$(read_meta "version")
    local installed_at; installed_at=$(read_meta "installed_at")
    local installed_by; installed_by=$(read_meta "installed_by")

    printf "  %-20s %s\n" "Role:" "$role"
    printf "  %-20s %s\n" "Version:" "$version"
    printf "  %-20s %s\n" "Installed at:" "$installed_at"
    printf "  %-20s %s\n" "Installed by:" "$installed_by"
    printf "  %-20s %s\n" "Target:" "$TARGET"
}

cmd_verify() {
    echo -e "${BOLD}Verifying CLAUDE.md...${NC}"

    if [ ! -f "$TARGET" ]; then
        echo -e "${RED}❌ Not installed.${NC}"
        exit 1
    fi

    local current_hash; current_hash=$(hash_of "$TARGET")
    local stored_hash; stored_hash=$(read_meta "hash")

    if [ "$current_hash" = "$stored_hash" ]; then
        echo -e "${GREEN}✅ CLAUDE.md matches installed version.${NC}"
        local role; role=$(read_meta "role")
        local version; version=$(read_meta "version")
        echo "   Role: $role | Version: $version"
    else
        echo -e "${RED}❌ CLAUDE.md has been modified since installation.${NC}"
        echo "   Expected hash: $stored_hash"
        echo "   Current hash:  $current_hash"
        echo ""
        echo "   To restore: ./manage.sh install --role $(read_meta 'role') --force"
        exit 1
    fi

  # Check permissions hash
  local stored_perms_hash current_perms_hash perms_role
  stored_perms_hash="$(read_meta permissions_hash 2>/dev/null || echo '')"
  perms_role="$(read_meta permissions_role 2>/dev/null || echo '')"

  if [[ -n "$stored_perms_hash" && -n "$perms_role" ]]; then
    local perms_file="${CONFIGS_DIR}/${perms_role}-permissions.json"
    if [[ -f "$perms_file" ]]; then
      current_perms_hash="$(md5sum "${perms_file}" 2>/dev/null | awk '{print $1}' || md5 -q "${perms_file}" 2>/dev/null)"
      if [[ "$stored_perms_hash" == "$current_perms_hash" ]]; then
        ok "Permissions file: unchanged (${perms_role})"
      else
        err "Permissions file modified since install! Role: ${perms_role}"
      fi
    fi
  fi
}

cmd_audit() {
    echo -e "${BOLD}Installation History${NC}"
    echo "────────────────────────────────"

    if [ ! -f "$META_FILE" ]; then
        echo "No installation history found."
        exit 0
    fi

    python3 - <<PYEOF
import json
data = json.load(open('$META_FILE'))
history = data.get('history', [])
if not history:
    print("No history.")
else:
    for i, entry in enumerate(reversed(history), 1):
        marker = "→ current" if i == 1 else ""
        print(f"  [{len(history)-i+1}] {entry.get('installed_at','?')[:19]}  "
              f"role={entry.get('role','?')}  "
              f"version={entry.get('version','?')}  "
              f"by={entry.get('installed_by','?')}  {marker}")
PYEOF
}

# ---------------------------------------------------------------------------
# Subcommand: escalate
# ---------------------------------------------------------------------------
cmd_escalate() {
  local from_role="" to_role="" approver="" dry_run="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from)     from_role="$2";  shift 2 ;;
      --to)       to_role="$2";    shift 2 ;;
      --approver) approver="$2";   shift 2 ;;
      --dry-run)  dry_run="true";  shift ;;
      *) err "Unknown option: $1"; exit 1 ;;
    esac
  done

  [[ -z "$from_role" || -z "$to_role" || -z "$approver" ]] && {
    err "Usage: manage.sh escalate --from <role> --to <role> --approver <email> [--dry-run]"
    exit 1
  }

  local current_role
  current_role="$(read_meta role 2>/dev/null || echo 'unknown')"

  if [[ "$current_role" != "$from_role" ]]; then
    err "Current role is '${current_role}', not '${from_role}'. Escalation aborted."
    exit 1
  fi

  bold "Role Escalation Request"
  info "  From:     ${from_role}"
  info "  To:       ${to_role}"
  info "  Approver: ${approver}"

  if [[ "$dry_run" == "true" ]]; then
    warn "[DRY-RUN] Would record escalation approval and install role '${to_role}'"
    return 0
  fi

  # Record approval in meta
  python3 - <<PYEOF
import json, datetime

meta_file = '${CLAUDE_DIR}/.config-meta.json'
try:
    with open(meta_file) as f:
        meta = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    meta = {'history': [], 'current': {}}

escalation = {
    'event': 'escalation_approved',
    'from_role': '${from_role}',
    'to_role': '${to_role}',
    'approver': '${approver}',
    'approved_at': datetime.datetime.utcnow().isoformat() + 'Z',
    'requested_by': '$(git config user.name 2>/dev/null || echo $USER)'
}
meta.setdefault('escalations', []).append(escalation)

with open(meta_file, 'w') as f:
    json.dump(meta, f, indent=2)
print('Escalation recorded.')
PYEOF

  ok "Escalation approved by ${approver}. Installing role '${to_role}'..."
  cmd_install --role "$to_role"
}

cmd_roles() {
    echo -e "${BOLD}Available Roles${NC}"
    echo "────────────────────────────────"
    for role in $VALID_ROLES; do
        local role_file="$CONFIGS_DIR/${role}.md"
        local version="(file not found)"
        if [ -f "$role_file" ]; then
            version=$(version_of "$role_file")
        fi
        printf "  %-12s %s\n" "$role" "v$version"
    done
    echo ""
    echo "Install: ./manage.sh install --role <role>"
}

# ── Main ─────────────────────────────────────────────────────────────────────

if [ $# -eq 0 ]; then
    echo "Usage: ./manage.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  install --role <role>   Install role-specific CLAUDE.md"
    echo "  list                    Show current configuration"
    echo "  verify                  Check if CLAUDE.md is unmodified"
    echo "  audit                   Show installation history"
    echo "  roles                   List available roles"
    echo ""
    echo "Options for install:"
    echo "  --dry-run               Preview without writing"
    echo "  --force                 Reinstall even if up to date"
    exit 0
fi

case "$1" in
    install)  shift; cmd_install "$@" ;;
    list)     cmd_list ;;
    verify)   cmd_verify ;;
    audit)    cmd_audit ;;
    roles)    cmd_roles ;;
    escalate) shift; cmd_escalate "$@" ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo "Run './manage.sh' for usage."
        exit 1
        ;;
esac
