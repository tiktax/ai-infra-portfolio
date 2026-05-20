#!/usr/bin/env bash
# onboard.sh — AI Harness automated onboarding pipeline
# Usage: ./onboard.sh --user <email> --role <role> --manager <email> [options]
#
# Steps:
#   1. GitHub org invitation
#   2. 1Password notification (manual prompt)
#   3. Install link generation (SSH or URL)
#   4. manage.sh role apply (Step 3 SSH success only)
#   5. KB list generation
#   6. Welcome email (sendmail or stdout)
#   7. Audit log append
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
RESET="\033[0m"

ok()   { echo -e "${GREEN}[OK]${RESET}  $*"; }
info() { echo -e "${CYAN}[INFO]${RESET} $*"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $*"; }
err()  { echo -e "${RED}[ERR]${RESET}  $*" >&2; }

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
USER_EMAIL=""
ROLE=""
MANAGER_EMAIL=""
GITHUB_ORG=""
DRY_RUN="false"
SKIP_GITHUB="false"
SKIP_EMAIL="false"
FORCE="false"

LOG_FILE="${HOME}/.claude/onboard-log.jsonl"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)      USER_EMAIL="$2";    shift 2 ;;
    --role)      ROLE="$2";          shift 2 ;;
    --manager)   MANAGER_EMAIL="$2"; shift 2 ;;
    --org)       GITHUB_ORG="$2";    shift 2 ;;
    --dry-run)   DRY_RUN="true";     shift ;;
    --skip-github) SKIP_GITHUB="true"; shift ;;
    --skip-email)  SKIP_EMAIL="true";  shift ;;
    --force)     FORCE="true";       shift ;;
    *)
      err "Unknown option: $1"
      echo "Usage: $0 --user <email> --role <role> --manager <email> [--org <github-org>] [--dry-run] [--skip-github] [--skip-email] [--force]"
      exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
if [[ -z "$USER_EMAIL" ]]; then
  err "--user is required"
  exit 1
fi
if [[ -z "$ROLE" ]]; then
  err "--role is required (engineer|analyst|manager)"
  exit 1
fi
if [[ -z "$MANAGER_EMAIL" ]]; then
  err "--manager is required"
  exit 1
fi
if [[ "$ROLE" != "engineer" && "$ROLE" != "analyst" && "$ROLE" != "manager" ]]; then
  err "Invalid role '${ROLE}'. Valid: engineer|analyst|manager"
  exit 1
fi

echo ""
echo "======================================================"
echo " AI Harness Onboarding Pipeline"
echo "======================================================"
info "User:     ${USER_EMAIL}"
info "Role:     ${ROLE}"
info "Manager:  ${MANAGER_EMAIL}"
[[ -n "$GITHUB_ORG" ]] && info "Org:      ${GITHUB_ORG}"
[[ "$DRY_RUN" == "true" ]] && warn "Mode:     DRY-RUN (no changes will be made)"
echo ""

# ---------------------------------------------------------------------------
# Step 0: Idempotency check
# ---------------------------------------------------------------------------
mkdir -p "$(dirname "$LOG_FILE")"

if [[ "$FORCE" != "true" && -f "$LOG_FILE" ]]; then
  if grep -q "\"user\":\"${USER_EMAIL}\"" "$LOG_FILE" 2>/dev/null; then
    warn "User '${USER_EMAIL}' already onboarded. Use --force to re-run."
    exit 0
  fi
fi

# ---------------------------------------------------------------------------
# Tracking variables for summary
# ---------------------------------------------------------------------------
GITHUB_STATUS="skipped"
VAULT_STATUS="manual action required"
INSTALL_STATUS="url-generated"
PERMISSIONS_STATUS="skipped"
EMAIL_STATUS="skipped"
AUDIT_STATUS="pending"
INSTALL_SUCCEEDED=false

# ---------------------------------------------------------------------------
# Step 1: GitHub invitation
# ---------------------------------------------------------------------------
info "--- Step 1: GitHub org invitation ---"
if [[ "$SKIP_GITHUB" != "true" ]] && command -v gh &>/dev/null && [[ -n "$GITHUB_ORG" ]]; then
  if [[ "$DRY_RUN" == "true" ]]; then
    info "[DRY-RUN] Would invite ${USER_EMAIL} to GitHub org: ${GITHUB_ORG}"
    GITHUB_STATUS="dry-run"
  else
    if gh api "orgs/${GITHUB_ORG}/invitations" \
        -f email="${USER_EMAIL}" \
        -f role="direct_member" \
        --silent 2>/dev/null; then
      ok "GitHub invitation sent to ${USER_EMAIL}"
      GITHUB_STATUS="sent"
    else
      warn "GitHub invitation failed (may already be a member)"
      GITHUB_STATUS="failed-or-existing"
    fi
  fi
else
  info "Step 1: GitHub invitation skipped"
  GITHUB_STATUS="skipped"
fi

# ---------------------------------------------------------------------------
# Step 2: 1Password vault notification
# ---------------------------------------------------------------------------
info "--- Step 2: 1Password vault access ---"
warn "  ACTION REQUIRED: Manually grant '${USER_EMAIL}' access to the shared vault."
warn "  Command: op user provision --email '${USER_EMAIL}' (run as vault admin)"
if [[ "$DRY_RUN" != "true" ]]; then
  read -rp "  Press Enter when vault access is granted (or Ctrl+C to abort)..." _
  ok "Step 2: Vault access confirmed by operator"
else
  info "[DRY-RUN] Would wait for vault access confirmation"
fi
VAULT_STATUS="manual action required"

# ---------------------------------------------------------------------------
# Step 3: Install link generation
# ---------------------------------------------------------------------------
info "--- Step 3: Install link generation ---"
if [[ "$DRY_RUN" == "true" ]]; then
  info "[DRY-RUN] Would attempt SSH install or generate install URL"
  INSTALL_SUCCEEDED=true
  INSTALL_STATUS="dry-run"
else
  info "Self-service install URL for ${USER_EMAIL}:"
  info "  git clone https://github.com/tiktax/ai-infra-portfolio && bash ai-infra-portfolio/install.sh --role ${ROLE}"
  INSTALL_SUCCEEDED=false
  INSTALL_STATUS="url-generated"
fi

# ---------------------------------------------------------------------------
# Step 4: manage.sh role apply (SSH success only)
# ---------------------------------------------------------------------------
info "--- Step 4: manage.sh role apply ---"
if [[ "$INSTALL_SUCCEEDED" == "true" && "$DRY_RUN" != "true" ]]; then
  if [[ -f "${SCRIPT_DIR}/tools/claude-config-manager/manage.sh" ]]; then
    bash "${SCRIPT_DIR}/tools/claude-config-manager/manage.sh" install --role "$ROLE"
    ok "Step 4: Role '${ROLE}' applied via manage.sh"
    PERMISSIONS_STATUS="applied"
  else
    warn "Step 4: manage.sh not found at tools/claude-config-manager/manage.sh — skipping"
    PERMISSIONS_STATUS="skipped-missing"
  fi
elif [[ "$DRY_RUN" == "true" ]]; then
  info "[DRY-RUN] Would run: manage.sh install --role ${ROLE}"
  PERMISSIONS_STATUS="dry-run"
else
  info "Step 4: Skipped (install.sh not run on remote machine)"
  PERMISSIONS_STATUS="skipped"
fi

# ---------------------------------------------------------------------------
# Step 5: KB list generation
# ---------------------------------------------------------------------------
info "--- Step 5: KB list generation ---"
KB_LIST=""
if [[ -f "${SCRIPT_DIR}/generate-kb-list.sh" ]]; then
  if KB_LIST="$(bash "${SCRIPT_DIR}/generate-kb-list.sh" --role "$ROLE" 2>/dev/null)"; then
    ok "Step 5: KB list generated"
  else
    warn "Step 5: KB list generation failed (continuing)"
    KB_LIST="See docs/ directory"
  fi
else
  warn "Step 5: generate-kb-list.sh not found — using fallback"
  KB_LIST="See docs/ directory"
fi

# ---------------------------------------------------------------------------
# Step 6: Welcome email
# ---------------------------------------------------------------------------
info "--- Step 6: Welcome email ---"
TEMPLATE="${SCRIPT_DIR}/templates/welcome-email.txt"
if [[ ! -f "$TEMPLATE" ]]; then
  warn "Step 6: Template not found at ${TEMPLATE} — skipping email"
  EMAIL_STATUS="skipped-missing-template"
else
  # Escape KB_LIST for sed (replace newlines with literal \n, escape special chars)
  KB_LIST_ESCAPED="$(printf '%s\n' "$KB_LIST" | sed 's/[&/\]/\\&/g' | tr '\n' '\001')"

  INSTALL_DATE="$(date '+%Y-%m-%d')"
  USER_NAME="${USER_EMAIL%%@*}"

  # Replace all placeholders except KB_LIST first, then substitute KB_LIST via Python
  EMAIL_CONTENT="$(python3 - <<PYEOF2
import sys

with open('${TEMPLATE}', 'r') as f:
    content = f.read()

kb_list = """${KB_LIST}"""

content = content.replace('{{USER_EMAIL}}', '${USER_EMAIL}')
content = content.replace('{{ROLE}}', '${ROLE}')
content = content.replace('{{NAME}}', '${USER_NAME}')
content = content.replace('{{MANAGER_EMAIL}}', '${MANAGER_EMAIL}')
content = content.replace('{{INSTALL_DATE}}', '${INSTALL_DATE}')
content = content.replace('{{KB_LIST}}', kb_list)

print(content, end='')
PYEOF2
  )"

  if [[ "$SKIP_EMAIL" == "true" ]]; then
    info "Step 6: Email skipped (--skip-email)"
    EMAIL_STATUS="skipped"
  elif [[ "$DRY_RUN" == "true" ]]; then
    info "[DRY-RUN] Would send welcome email to ${USER_EMAIL}"
    echo "--- Email preview ---"
    echo "$EMAIL_CONTENT"
    echo "--- End preview ---"
    EMAIL_STATUS="dry-run"
  elif command -v sendmail &>/dev/null; then
    if echo "$EMAIL_CONTENT" | sendmail "$USER_EMAIL" 2>/dev/null; then
      ok "Step 6: Welcome email sent to ${USER_EMAIL}"
      EMAIL_STATUS="sent"
    else
      warn "Step 6: sendmail failed — printing email content to stdout"
      echo "$EMAIL_CONTENT"
      EMAIL_STATUS="sendmail-failed-stdout"
    fi
  else
    warn "Step 6: sendmail not available — displaying email content:"
    echo "$EMAIL_CONTENT"
    EMAIL_STATUS="stdout"
  fi
fi

# ---------------------------------------------------------------------------
# Step 7: Audit log
# ---------------------------------------------------------------------------
info "--- Step 7: Audit log ---"
DRY_RUN_BOOL="False"
[[ "$DRY_RUN" == "true" ]] && DRY_RUN_BOOL="True"
INSTALL_BOOL="False"
[[ "$INSTALL_SUCCEEDED" == "true" ]] && INSTALL_BOOL="True"

python3 - <<PYEOF
import json, datetime, os, getpass

log_file = '${LOG_FILE}'
entry = {
    'event': 'onboard',
    'user': '${USER_EMAIL}',
    'role': '${ROLE}',
    'manager': '${MANAGER_EMAIL}',
    'onboarded_by': os.environ.get('USER', getpass.getuser()),
    'timestamp': datetime.datetime.now(datetime.timezone.utc).isoformat().replace('+00:00', 'Z'),
    'dry_run': ${DRY_RUN_BOOL},
    'github_org': '${GITHUB_ORG:-}',
    'install_succeeded': ${INSTALL_BOOL}
}
with open(log_file, 'a') as f:
    f.write(json.dumps(entry) + '\n')
print('Audit log written.')
PYEOF

ok "Step 7: Audit log written to ${LOG_FILE}"
AUDIT_STATUS="written"

# ---------------------------------------------------------------------------
# Completion summary
# ---------------------------------------------------------------------------
echo ""
echo "======================================================"
echo " Onboarding complete: ${USER_EMAIL} (${ROLE})"
echo "======================================================"
printf "  GitHub invite:    %s\n" "$GITHUB_STATUS"
printf "  1Password:        %s\n" "$VAULT_STATUS"
printf "  Install link:     %s\n" "$INSTALL_STATUS"
printf "  Permissions:      %s\n" "$PERMISSIONS_STATUS"
printf "  Welcome email:    %s\n" "$EMAIL_STATUS"
printf "  Audit log:        %s\n" "$LOG_FILE"
echo "======================================================"
echo ""
