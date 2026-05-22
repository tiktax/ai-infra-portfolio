#!/usr/bin/env bash
# phase-gate.sh — ITIL 5 AI Governance Phase Gate CLI
# ITIL 5 Practices: Product/Service Lifecycle, AI Governance (6C), Change Enablement
# Jurisdiction support: JP (金融庁) | US (SR 11-7) | EU (AI Act)
# Based on ITIL 5 preview spec (PeopleCert, 2026); will align to final release.

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURE_GATES_DIR="${SCRIPT_DIR}/feature-gates"
APPROVALS_LOG="${SCRIPT_DIR}/approvals.log"

ACTIVITIES=(discover design build deploy operate observe improve retire)

# Lookup function replacing associative array (bash 3.2 compat)
activity_num() {
  case "$1" in
    discover) echo "01" ;;
    design)   echo "02" ;;
    build)    echo "03" ;;
    deploy)   echo "04" ;;
    operate)  echo "05" ;;
    observe)  echo "06" ;;
    improve)  echo "07" ;;
    retire)   echo "08" ;;
    *)        echo "" ;;
  esac
}

# ---------------------------------------------------------------------------
# Color output
# ---------------------------------------------------------------------------
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { printf "${GREEN}%s${RESET}\n" "$*"; }
err()  { printf "${RED}%s${RESET}\n" "$*" >&2; }
warn() { printf "${YELLOW}%s${RESET}\n" "$*"; }
info() { printf "${CYAN}%s${RESET}\n" "$*"; }
bold() { printf "${BOLD}%s${RESET}\n" "$*"; }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
gate_file() {
  local activity="$1"
  local num
  num="$(activity_num "$activity")"
  if [[ -z "$num" ]]; then
    echo ""
    return
  fi
  echo "${FEATURE_GATES_DIR}/${num}-${activity}.md"
}

validate_activity() {
  local activity="$1"
  local num
  num="$(activity_num "$activity")"
  if [[ -z "$num" ]]; then
    err "Error: unknown activity '${activity}'"
    err "Valid activities: ${ACTIVITIES[*]}"
    exit 1
  fi
}

ensure_feature_gates_dir() {
  if [[ ! -d "$FEATURE_GATES_DIR" ]]; then
    err "Error: feature-gates/ directory not found at ${FEATURE_GATES_DIR}"
    err "Please create the directory and add activity gate files."
    exit 1
  fi
}

ensure_approvals_log() {
  if [[ ! -f "$APPROVALS_LOG" ]]; then
    touch "$APPROVALS_LOG"
  fi
}

count_checks() {
  local file="$1"
  local checked=0
  local unchecked=0
  local in_japanese=0
  while IFS= read -r line; do
    # Stop counting at Japanese version section
    if [[ "$line" =~ ^##[[:space:]]日本語版 ]]; then
      in_japanese=1
    fi
    [[ $in_japanese -eq 1 ]] && continue
    local c_checked
    c_checked=$(echo "$line" | grep -o '☑' | wc -l | tr -d ' ')
    local c_unchecked
    c_unchecked=$(echo "$line" | grep -o '☐' | wc -l | tr -d ' ')
    checked=$(( checked + c_checked ))
    unchecked=$(( unchecked + c_unchecked ))
  done < "$file"
  echo "${checked} ${unchecked}"
}

is_approved() {
  local activity="$1"
  ensure_approvals_log
  if grep -q "\"activity\":\"${activity}\"" "$APPROVALS_LOG" 2>/dev/null; then
    return 0
  fi
  return 1
}

hash_gate_file() {
  local file="$1"
  shasum -a 256 "$file" | awk '{print $1}'
}

# ---------------------------------------------------------------------------
# Subcommand: status
# ---------------------------------------------------------------------------
cmd_status() {
  ensure_feature_gates_dir

  bold "ITIL 5 AI Governance — Phase Gate Status"
  printf "%-12s %-8s %-8s %-8s %s\n" "Activity" "Checked" "Total" "Done%" "Approval"
  printf '%0.s-' {1..60}; echo

  local total_checked=0
  local total_items=0

  for activity in "${ACTIVITIES[@]}"; do
    local file
    file="$(gate_file "$activity")"
    local checked=0 unchecked=0 total=0 pct="N/A" approval_str=""

    if [[ -f "$file" ]]; then
      read -r checked unchecked <<< "$(count_checks "$file")"
      total=$(( checked + unchecked ))
      if [[ $total -gt 0 ]]; then
        pct=$(( checked * 100 / total ))
      else
        pct=0
      fi
      total_checked=$(( total_checked + checked ))
      total_items=$(( total_items + total ))
    else
      checked="—"
      total="—"
      pct="—"
    fi

    if is_approved "$activity"; then
      approval_str="${GREEN}✓ Approved${RESET}"
    else
      approval_str="${YELLOW}(pending)${RESET}"
    fi

    local pct_display
    if [[ "$pct" == "—" ]]; then
      pct_display="—%"
    else
      pct_display="${pct}%"
    fi

    printf "%-12s %-8s %-8s %-8s " "$activity" "$checked" "$total" "$pct_display"
    printf "${approval_str}\n"
  done

  printf '%0.s-' {1..60}; echo

  local overall=0
  if [[ $total_items -gt 0 ]]; then
    overall=$(( total_checked * 100 / total_items ))
  fi
  printf "${BOLD}%-12s %-8s %-8s %s%%${RESET}\n" "TOTAL" "$total_checked" "$total_items" "$overall"
}

# ---------------------------------------------------------------------------
# Subcommand: check
# ---------------------------------------------------------------------------
cmd_check() {
  local activity=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --activity) activity="$2"; shift 2 ;;
      *) err "Unknown option: $1"; exit 1 ;;
    esac
  done

  if [[ -z "$activity" ]]; then
    err "Error: --activity is required"
    exit 1
  fi

  validate_activity "$activity"
  ensure_feature_gates_dir

  local file
  file="$(gate_file "$activity")"

  if [[ ! -f "$file" ]]; then
    err "Error: gate file not found: ${file}"
    exit 1
  fi

  info "Checking activity: ${activity}"
  echo ""

  local incomplete=()
  local in_japanese=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^##[[:space:]]日本語版 ]]; then
      in_japanese=1
    fi
    [[ $in_japanese -eq 1 ]] && continue
    if [[ "$line" =~ ^## ]]; then
      continue
    fi
    if echo "$line" | grep -q '☐'; then
      incomplete+=("$line")
    fi
  done < "$file"

  if [[ ${#incomplete[@]} -gt 0 ]]; then
    warn "Incomplete items:"
    for item in "${incomplete[@]}"; do
      echo "  $item"
    done
    echo ""
  else
    ok "All items completed!"
    echo ""
  fi

  local checked unchecked total pct
  read -r checked unchecked <<< "$(count_checks "$file")"
  total=$(( checked + unchecked ))
  if [[ $total -gt 0 ]]; then
    pct=$(( checked * 100 / total ))
  else
    pct=0
  fi

  printf "Completion: ${checked}/${total} (${pct}%%)\n"

  if [[ ${#incomplete[@]} -gt 0 ]]; then
    warn "Gate check INCOMPLETE — ${#incomplete[@]} item(s) remaining"
    exit 1
  else
    ok "Gate check PASSED"
  fi
}

# ---------------------------------------------------------------------------
# Subcommand: approve
# ---------------------------------------------------------------------------
determine_required_level() {
  local activity="$1"
  local jurisdiction="$2"

  case "${jurisdiction}+${activity}" in
    JP+deploy)
      echo "Director (金融庁AIリスク管理ガイドライン)"
      ;;
    US+deploy)
      echo "CRO/Independent Model Risk (SR 11-7, financial sector)"
      ;;
    EU+*)
      echo "Third-party Conformity Assessment Body (EU AI Act Art.43)"
      ;;
    *)
      echo "Manager"
      ;;
  esac
}

cmd_approve() {
  local activity=""
  local approver=""
  local jurisdiction=""
  local notes=""
  local co_approver=""
  local expires_months=12

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --activity)       activity="$2";       shift 2 ;;
      --approver)       approver="$2";       shift 2 ;;
      --jurisdiction)   jurisdiction="$2";   shift 2 ;;
      --notes)          notes="$2";          shift 2 ;;
      --co-approver)    co_approver="$2";    shift 2 ;;
      --expires-months) expires_months="$2"; shift 2 ;;
      *) err "Unknown option: $1"; exit 1 ;;
    esac
  done

  if [[ -z "$activity" || -z "$approver" || -z "$jurisdiction" ]]; then
    err "Error: --activity, --approver, and --jurisdiction are required"
    exit 1
  fi

  case "$jurisdiction" in
    JP|US|EU) ;;
    *) err "Error: --jurisdiction must be JP, US, or EU"; exit 1 ;;
  esac

  validate_activity "$activity"
  ensure_feature_gates_dir
  ensure_approvals_log

  local file
  file="$(gate_file "$activity")"

  if [[ ! -f "$file" ]]; then
    err "Error: gate file not found: ${file}"
    exit 1
  fi

  local evidence_hash
  evidence_hash="$(hash_gate_file "$file")"

  local date_iso
  date_iso="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  # Calculate expiry date (macOS BSD date)
  local expires_at
  expires_at="$(date -u -v "+${expires_months}m" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
    || date -u -d "+${expires_months} months" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
    || echo "")"

  local required_level
  required_level="$(determine_required_level "$activity" "$jurisdiction")"

  # Build JSON entry (single line, append-only)
  local json_entry
  if [[ -n "$co_approver" ]]; then
    json_entry=$(printf '{"activity":"%s","approved_by":"%s","co_approver":"%s","date":"%s","expires_at":"%s","evidence_hash":"%s","jurisdiction":"%s","required_level":"%s","itil5_practice":"Change Enablement","notes":"%s"}' \
      "$activity" "$approver" "$co_approver" "$date_iso" "$expires_at" "$evidence_hash" "$jurisdiction" "$required_level" "${notes:-}")
  else
    json_entry=$(printf '{"activity":"%s","approved_by":"%s","date":"%s","expires_at":"%s","evidence_hash":"%s","jurisdiction":"%s","required_level":"%s","itil5_practice":"Change Enablement","notes":"%s"}' \
      "$activity" "$approver" "$date_iso" "$expires_at" "$evidence_hash" "$jurisdiction" "$required_level" "${notes:-}")
  fi

  echo "$json_entry" >> "$APPROVALS_LOG"

  echo ""
  ok "Approval recorded successfully."
  echo ""
  printf "  %-18s %s\n" "Activity:"        "$activity"
  printf "  %-18s %s\n" "Approved by:"     "$approver"
  [[ -n "$co_approver" ]] && printf "  %-18s %s\n" "Co-approver:"   "$co_approver"
  printf "  %-18s %s\n" "Date:"            "$date_iso"
  printf "  %-18s %s\n" "Expires at:"      "${expires_at:-N/A}"
  printf "  %-18s %s\n" "Jurisdiction:"    "$jurisdiction"
  printf "  %-18s %s\n" "Required level:"  "$required_level"
  printf "  %-18s %s\n" "ITIL 5 Practice:" "Change Enablement"
  printf "  %-18s %s\n" "Evidence hash:"   "$evidence_hash"
  echo ""
}

# ---------------------------------------------------------------------------
# Subcommand: audit
# ---------------------------------------------------------------------------
cmd_audit() {
  ensure_approvals_log
  ensure_feature_gates_dir

  if [[ ! -s "$APPROVALS_LOG" ]]; then
    warn "No approval entries found in approvals.log"
    exit 0
  fi

  bold "ITIL 5 AI Governance — Audit Report"
  echo ""

  local pass_count=0
  local fail_count=0
  local expire_count=0
  local entry_num=0

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    entry_num=$(( entry_num + 1 ))

    local activity approved_by date_val evidence_hash jurisdiction required_level itil5_practice
    activity=$(echo "$line"       | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('activity',''))" 2>/dev/null || echo "")
    approved_by=$(echo "$line"    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('approved_by',''))" 2>/dev/null || echo "")
    date_val=$(echo "$line"       | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('date',''))" 2>/dev/null || echo "")
    evidence_hash=$(echo "$line"  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('evidence_hash',''))" 2>/dev/null || echo "")
    jurisdiction=$(echo "$line"   | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('jurisdiction',''))" 2>/dev/null || echo "")
    required_level=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('required_level',''))" 2>/dev/null || echo "")
    itil5_practice=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('itil5_practice',''))" 2>/dev/null || echo "")

    printf "${BOLD}Entry #%d${RESET}\n" "$entry_num"
    printf "  %-18s %s\n" "Activity:"       "$activity"
    printf "  %-18s %s\n" "Approved by:"    "$approved_by"
    printf "  %-18s %s\n" "Date:"           "$date_val"
    printf "  %-18s %s\n" "Jurisdiction:"   "$jurisdiction"
    printf "  %-18s %s\n" "Required level:" "$required_level"
    printf "  %-18s %s\n" "ITIL 5 Practice:" "$itil5_practice"
    printf "  %-18s %s\n" "Evidence hash:"  "$evidence_hash"

    # Verify hash
    local file
    file="$(gate_file "$activity")"
    if [[ -f "$file" ]]; then
      local current_hash
      current_hash="$(hash_gate_file "$file")"
      if [[ "$evidence_hash" == "$current_hash" ]]; then
        ok "  Hash verification: ✓ PASS"
        pass_count=$(( pass_count + 1 ))
      else
        err "  Hash verification: ✗ FAIL (tampered or file changed)"
        printf "    Stored:  %s\n" "$evidence_hash"
        printf "    Current: %s\n" "$current_hash"
        fail_count=$(( fail_count + 1 ))
      fi
    else
      warn "  Hash verification: ⚠ SKIP (gate file not found: ${file})"
    fi

    # Check expiry
    local expires_at
    expires_at="$(python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('expires_at',''))" 2>/dev/null <<< "$line" || true)"
    if [[ -n "$expires_at" && "$expires_at" != "null" ]]; then
      local now_ts expires_ts
      now_ts="$(date -u +%s)"
      expires_ts="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$expires_at" +%s 2>/dev/null \
        || date -u -d "$expires_at" +%s 2>/dev/null || echo 0)"
      if [[ $expires_ts -gt 0 && $now_ts -gt $expires_ts ]]; then
        warn "  Approval EXPIRED: was valid until ${expires_at}"
        expire_count=$(( expire_count + 1 ))
      else
        ok "  Expiry: valid until ${expires_at}"
      fi
    fi

    echo ""
  done < "$APPROVALS_LOG"

  printf '%0.s-' {1..60}; echo
  bold "Audit Summary"
  ok  "  PASS: ${pass_count}"
  if [[ $fail_count -gt 0 ]]; then
    err "  FAIL: ${fail_count}"
  else
    printf "  FAIL: ${fail_count}\n"
  fi
  if [[ $expire_count -gt 0 ]]; then
    warn "  EXPIRED: ${expire_count} approval(s) require renewal"
  fi
  echo ""

  if [[ $fail_count -gt 0 ]]; then
    err "Integrity check FAILED — ${fail_count} entry(ies) could not be verified."
    exit 1
  else
    ok "Integrity check PASSED — all entries verified."
  fi
}

# ---------------------------------------------------------------------------
# Subcommand: check-expiry
# ---------------------------------------------------------------------------
cmd_check_expiry() {
  ensure_approvals_log

  bold "ITIL 5 AI Governance — Approval Expiry Check"
  echo ""

  local now_ts
  now_ts="$(date -u +%s)"
  local expired=0
  local expiring_soon=0  # within 30 days
  local valid=0

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    local activity expires_at approved_by
    activity="$(python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('activity','?'))" 2>/dev/null <<< "$line" || echo '?')"
    expires_at="$(python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('expires_at',''))" 2>/dev/null <<< "$line" || echo '')"
    approved_by="$(python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('approved_by','?'))" 2>/dev/null <<< "$line" || echo '?')"

    if [[ -z "$expires_at" || "$expires_at" == "null" ]]; then
      printf "  %-12s %-30s %s\n" "$activity" "$approved_by" "(no expiry set)"
      continue
    fi

    local expires_ts
    expires_ts="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$expires_at" +%s 2>/dev/null \
      || date -u -d "$expires_at" +%s 2>/dev/null || echo 0)"

    if [[ $expires_ts -eq 0 ]]; then
      printf "  %-12s %-30s %s\n" "$activity" "$approved_by" "(could not parse expiry)"
      continue
    fi

    local days_left
    days_left=$(( (expires_ts - now_ts) / 86400 ))

    if [[ $now_ts -gt $expires_ts ]]; then
      err "  ✗ EXPIRED  $(printf '%-12s' "$activity") $(printf '%-30s' "$approved_by") expired: ${expires_at}"
      expired=$(( expired + 1 ))
    elif [[ $days_left -le 30 ]]; then
      warn "  ⚠ EXPIRING $(printf '%-12s' "$activity") $(printf '%-30s' "$approved_by") expires in ${days_left}d: ${expires_at}"
      expiring_soon=$(( expiring_soon + 1 ))
    else
      ok "  ✓ VALID    $(printf '%-12s' "$activity") $(printf '%-30s' "$approved_by") valid for ${days_left}d"
      valid=$(( valid + 1 ))
    fi
  done < "$APPROVALS_LOG"

  echo ""
  printf '%0.s-' {1..60}; echo
  bold "Summary"
  ok  "  Valid:         ${valid}"
  warn "  Expiring soon: ${expiring_soon} (within 30 days)"
  if [[ $expired -gt 0 ]]; then
    err "  Expired:       ${expired} — re-approval required"
    echo ""
    err "Run: ./phase-gate.sh approve --activity <name> --approver <email> --jurisdiction <JP|US|EU>"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Subcommand: risk-tier
# ---------------------------------------------------------------------------
cmd_risk_tier() {
  local jurisdiction=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --jurisdiction) jurisdiction="$2"; shift 2 ;;
      *) err "Unknown option: $1"; exit 1 ;;
    esac
  done

  if [[ -z "$jurisdiction" ]]; then
    err "Error: --jurisdiction is required (EU|JP|US)"
    exit 1
  fi

  case "$jurisdiction" in
    JP|US|EU) ;;
    *) err "Error: --jurisdiction must be JP, US, or EU"; exit 1 ;;
  esac

  bold "ITIL 5 AI Governance — Risk Tier Assessment"
  info "Jurisdiction: ${jurisdiction}"
  echo ""

  local score=0

  local q1 q2 q3
  read -r -p "$(printf "${CYAN}1. Does the AI make decisions affecting people's rights or access to services? (y/n): ${RESET}")" q1
  read -r -p "$(printf "${CYAN}2. Does the AI operate in a regulated sector (finance/healthcare/law)? (y/n): ${RESET}")" q2
  read -r -p "$(printf "${CYAN}3. Does the AI use biometric/behavioral data? (y/n): ${RESET}")" q3

  [[ "$q1" == "y" || "$q1" == "Y" ]] && score=$(( score + 1 ))
  [[ "$q2" == "y" || "$q2" == "Y" ]] && score=$(( score + 1 ))
  [[ "$q3" == "y" || "$q3" == "Y" ]] && score=$(( score + 1 ))

  echo ""

  case "$jurisdiction" in
    EU)
      case "$score" in
        3)
          err "Risk Tier: PROHIBITED or HIGH-RISK"
          err "→ Third-party assessment required (EU AI Act Art.43)"
          err "Implementation must stop until conformity assessment is complete."
          exit 1
          ;;
        2)
          err "Risk Tier: HIGH-RISK (Annex III)"
          err "→ Article 12 logging mandatory, conformity assessment required"
          err "Implementation must stop until conformity assessment is complete."
          exit 1
          ;;
        1)
          warn "Risk Tier: LIMITED"
          warn "→ Transparency disclosure required (EU AI Act Art.13)"
          ;;
        0)
          ok "Risk Tier: MINIMAL"
          ok "→ Standard gates only"
          ;;
      esac
      ;;
    JP)
      if [[ $score -ge 1 ]]; then
        warn "Risk Tier: HIGH-RISK"
        warn "→ Director-level approval required (金融庁AIリスク管理ガイドライン)"
      else
        ok "Risk Tier: STANDARD"
        ok "→ Standard gates only"
      fi
      ;;
    US)
      if [[ $score -ge 1 ]]; then
        warn "Risk Tier: HIGH-RISK"
        warn "→ CRO/Independent Model Risk approval required (SR 11-7, financial sector)"
      else
        ok "Risk Tier: STANDARD"
        ok "→ Standard gates only"
      fi
      ;;
  esac

  echo ""
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF
$(printf "${BOLD}phase-gate.sh${RESET}") — ITIL 5 AI Governance Phase Gate CLI

$(printf "${BOLD}Usage:${RESET}")
  ./phase-gate.sh <subcommand> [options]

$(printf "${BOLD}Subcommands:${RESET}")
  status
      Show progress for all 8 ITIL 5 activities.

  check --activity <name>
      Check catalog completeness for the given activity.
      Show uncompleted items and completion percentage.

  approve --activity <name> --approver <email> --jurisdiction <JP|US|EU>
          [--co-approver <email>] [--expires-months <N>] [--notes <text>]
      Record a human approval (default expiry: 12 months).
      Use --co-approver for High-Risk activities requiring dual sign-off.

  audit
      Verify all approval log entries against current gate file hashes.

  check-expiry
      List all approvals with expiry status (valid / expiring soon / expired).
      Exits non-zero if any approval is expired.

  risk-tier --jurisdiction <EU|JP|US>
      Interactive risk assessment questionnaire.

$(printf "${BOLD}Activities:${RESET}")
  discover, design, build, deploy, operate, observe, improve, retire

$(printf "${BOLD}Jurisdictions:${RESET}")
  JP — 金融庁 AIリスク管理ガイドライン
  US — SR 11-7 (Federal Reserve, financial sector)
  EU — EU AI Act (Regulation 2024/1689)

$(printf "${BOLD}Examples:${RESET}")
  ./phase-gate.sh status
  ./phase-gate.sh check --activity deploy
  ./phase-gate.sh approve --activity deploy --approver ciso@example.com --jurisdiction EU
  ./phase-gate.sh audit
  ./phase-gate.sh risk-tier --jurisdiction EU
EOF
}

# ---------------------------------------------------------------------------
# Main dispatch
# ---------------------------------------------------------------------------
main() {
  if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
    usage
    exit 0
  fi

  local subcommand="$1"
  shift

  case "$subcommand" in
    status)       cmd_status       "$@" ;;
    check)        cmd_check        "$@" ;;
    approve)      cmd_approve      "$@" ;;
    audit)        cmd_audit        "$@" ;;
    check-expiry) cmd_check_expiry "$@" ;;
    risk-tier)    cmd_risk_tier    "$@" ;;
    *)
      err "Error: unknown subcommand '${subcommand}'"
      echo ""
      usage
      exit 1
      ;;
  esac
}

main "$@"
