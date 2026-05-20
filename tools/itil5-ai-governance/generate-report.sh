#!/usr/bin/env bash
# generate-report.sh — ITIL 5 Financial Governance Report Generator
# ITIL 5 Practice: Service Financial Management (Outcome-based)
# Based on ITIL 5 preview spec (PeopleCert, 2026); will align to final release.

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPROVALS_LOG="${SCRIPT_DIR}/approvals.log"
FEATURE_GATES_DIR="${SCRIPT_DIR}/feature-gates"
COST_TEMPLATE="${SCRIPT_DIR}/cost-template.md"

# ---------------------------------------------------------------------------
# All 8 ITIL 5 lifecycle activities
# ---------------------------------------------------------------------------
ALL_ACTIVITIES=(discover design build deploy operate observe improve retire)

# ---------------------------------------------------------------------------
# CLI argument defaults
# ---------------------------------------------------------------------------
FORMAT="text"
ACTIVITY_FILTER=""
CHECK_ESCALATION_ONLY=false
USE_DEFAULTS=false

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --defaults)
      USE_DEFAULTS=true
      shift
      ;;
    --format)
      FORMAT="${2:-text}"
      shift 2
      ;;
    --activity)
      ACTIVITY_FILTER="${2:-}"
      shift 2
      ;;
    --check-escalation)
      CHECK_ESCALATION_ONLY=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 [--defaults] [--format text|html] [--activity <name>] [--check-escalation]" >&2
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# HTML escape helper
# ---------------------------------------------------------------------------
html_escape() { printf '%s' "$1" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g;s/"/\&quot;/g'; }

# ---------------------------------------------------------------------------
# Timestamps (BSD date — macOS compatible)
# ---------------------------------------------------------------------------
NOW="$(date "+%Y-%m-%d %H:%M:%S")"
TIMESTAMP_FILE="$(date "+%Y%m%d-%H%M%S")"

# ---------------------------------------------------------------------------
# Load approvals data
# ---------------------------------------------------------------------------
# Returns associative-array-like data stored in indexed arrays
declare -a APPROVED_ACTIVITIES=()
declare -a APPROVED_BY_LIST=()
declare -a JURISDICTION_LIST=()
declare -a REQUIRED_LEVEL_LIST=()
declare -a APPROVAL_DATE_LIST=()

load_approvals() {
  if [[ -f "${APPROVALS_LOG}" ]]; then
    while IFS= read -r line; do
      [[ -z "${line}" ]] && continue
      # Parse JSONL with python3 (no jq dependency)
      # Fields are output one per line to preserve spaces in values
      local parsed
      parsed="$(python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    print(d.get('activity',''))
    print(d.get('approved_by',''))
    print(d.get('jurisdiction',''))
    print(d.get('required_level',''))
    print(d.get('date','')[:10])
except:
    print('')
    print('')
    print('')
    print('')
    print('')
" <<< "${line}")"
      local activity approved_by jurisdiction required_level date_val
      activity="$(sed -n '1p' <<< "${parsed}")"
      approved_by="$(sed -n '2p' <<< "${parsed}")"
      jurisdiction="$(sed -n '3p' <<< "${parsed}")"
      required_level="$(sed -n '4p' <<< "${parsed}")"
      date_val="$(sed -n '5p' <<< "${parsed}")"
      if [[ -n "${activity}" ]]; then
        APPROVED_ACTIVITIES+=("${activity}")
        APPROVED_BY_LIST+=("${approved_by}")
        JURISDICTION_LIST+=("${jurisdiction}")
        REQUIRED_LEVEL_LIST+=("${required_level}")
        APPROVAL_DATE_LIST+=("${date_val}")
      fi
    done < "${APPROVALS_LOG}"
  else
    # Fallback sample data when --defaults and no log exists
    APPROVED_ACTIVITIES=("discover")
    APPROVED_BY_LIST+=("manager@example.com")
    JURISDICTION_LIST+=("JP")
    REQUIRED_LEVEL_LIST+=("Manager")
    APPROVAL_DATE_LIST+=("$(date "+%Y-%m-%d")")
  fi
}

# ---------------------------------------------------------------------------
# Lookup helpers
# ---------------------------------------------------------------------------
is_approved() {
  local act="$1"
  for a in "${APPROVED_ACTIVITIES[@]:-}"; do
    [[ "${a}" == "${act}" ]] && return 0
  done
  return 1
}

get_approval_field() {
  local act="$1"
  local field="$2"  # by / jurisdiction / level / date
  for i in "${!APPROVED_ACTIVITIES[@]}"; do
    if [[ "${APPROVED_ACTIVITIES[$i]}" == "${act}" ]]; then
      case "${field}" in
        by)         echo "${APPROVED_BY_LIST[$i]}" ;;
        jurisdiction) echo "${JURISDICTION_LIST[$i]}" ;;
        level)      echo "${REQUIRED_LEVEL_LIST[$i]}" ;;
        date)       echo "${APPROVAL_DATE_LIST[$i]}" ;;
      esac
      return
    fi
  done
  echo "—"
}

# ---------------------------------------------------------------------------
# Determine which activities to report on
# ---------------------------------------------------------------------------
get_target_activities() {
  if [[ -n "${ACTIVITY_FILTER}" ]]; then
    echo "${ACTIVITY_FILTER}"
  else
    echo "${ALL_ACTIVITIES[@]}"
  fi
}

# ---------------------------------------------------------------------------
# Feature-gate completion count (English table only, before 日本語版 heading)
# ---------------------------------------------------------------------------
count_feature_gate() {
  local activity="$1"
  # Map activity name to file prefix number
  local prefix
  case "${activity}" in
    discover) prefix="01" ;;
    design)   prefix="02" ;;
    build)    prefix="03" ;;
    deploy)   prefix="04" ;;
    operate)  prefix="05" ;;
    observe)  prefix="06" ;;
    improve)  prefix="07" ;;
    retire)   prefix="08" ;;
    *)        echo "0 0"; return ;;
  esac

  local gate_file="${FEATURE_GATES_DIR}/${prefix}-${activity}.md"
  if [[ ! -f "${gate_file}" ]]; then
    echo "0 0"
    return
  fi

  # Extract only the English section (before 日本語版)
  local english_section
  english_section="$(python3 -c "
import sys
lines = sys.stdin.read().split('\n')
out = []
for l in lines:
    if '日本語版' in l:
        break
    out.append(l)
print('\n'.join(out))
" < "${gate_file}")"

  local total checked
  # Count rows with ☐ (unchecked) or ☑/✓/✗ (checked)
  total="$(printf '%s\n' "${english_section}" | grep -c '☐\|☑\|✓\|✗' || true)"
  checked="$(printf '%s\n' "${english_section}" | grep -c '☑\|✓' || true)"
  echo "${checked} ${total}"
}

# ---------------------------------------------------------------------------
# Escalation check logic
# Returns lines of escalation messages (empty = none required)
# ---------------------------------------------------------------------------
compute_escalations() {
  local -a msgs=()

  # EU High-Risk: deploy not approved
  local eu_deploy_approved=false
  for i in "${!APPROVED_ACTIVITIES[@]}"; do
    if [[ "${APPROVED_ACTIVITIES[$i]:-}" == "deploy" && "${JURISDICTION_LIST[$i]:-}" == "EU" ]]; then
      eu_deploy_approved=true
      break
    fi
  done
  if ! "${eu_deploy_approved}"; then
    msgs+=("ESCALATION REQUIRED: Board-level review needed (EU High-Risk AI Act — deploy gate not approved)")
  fi

  # JP deploy not approved
  local jp_deploy_approved=false
  for i in "${!APPROVED_ACTIVITIES[@]}"; do
    if [[ "${APPROVED_ACTIVITIES[$i]:-}" == "deploy" && "${JURISDICTION_LIST[$i]:-}" == "JP" ]]; then
      jp_deploy_approved=true
      break
    fi
  done
  if ! "${jp_deploy_approved}"; then
    msgs+=("ESCALATION REQUIRED: Director approval pending (JP — deploy gate not approved)")
  fi

  # US deploy not approved
  local us_deploy_approved=false
  for i in "${!APPROVED_ACTIVITIES[@]}"; do
    if [[ "${APPROVED_ACTIVITIES[$i]:-}" == "deploy" && "${JURISDICTION_LIST[$i]:-}" == "US" ]]; then
      us_deploy_approved=true
      break
    fi
  done
  if ! "${us_deploy_approved}"; then
    msgs+=("ESCALATION REQUIRED: CRO/Model Risk Officer sign-off pending (US SR 11-7 — deploy gate not approved)")
  fi

  printf '%s\n' "${msgs[@]:-}"
}

# ---------------------------------------------------------------------------
# Count approved activities (all 8)
# ---------------------------------------------------------------------------
count_approved() {
  local count=0
  for act in "${ALL_ACTIVITIES[@]}"; do
    is_approved "${act}" && (( count++ )) || true
  done
  echo "${count}"
}

# ---------------------------------------------------------------------------
# TEXT REPORT
# ---------------------------------------------------------------------------
print_text_report() {
  local target_activities
  read -ra target_activities <<< "$(get_target_activities)"

  local approved_count
  approved_count="$(count_approved)"
  local total_count="${#ALL_ACTIVITIES[@]}"

  echo "========================================================================"
  echo " ITIL 5 AI Governance Financial Report — Generated: ${NOW}"
  echo "========================================================================"
  echo ""

  # --- Executive Summary ---
  echo "## Executive Summary"
  echo "  Approved activities : ${approved_count} / ${total_count}"
  # EU High-Risk status
  local eu_deploy_ok=false
  for i in "${!APPROVED_ACTIVITIES[@]}"; do
    [[ "${APPROVED_ACTIVITIES[$i]:-}" == "deploy" && "${JURISDICTION_LIST[$i]:-}" == "EU" ]] && eu_deploy_ok=true
  done
  if "${eu_deploy_ok}"; then
    echo "  EU High-Risk (deploy): APPROVED"
  else
    echo "  EU High-Risk (deploy): NOT APPROVED"
  fi
  local escalations
  escalations="$(compute_escalations)"
  if [[ -z "${escalations}" ]]; then
    echo "  Escalation required : No"
  else
    echo "  Escalation required : YES"
  fi
  echo ""

  # --- Activity Status Table ---
  echo "## Activity Status Table"
  printf "  %-12s %-10s %-30s %-14s %-22s %-12s\n" \
    "Activity" "Approved" "Approver" "Jurisdiction" "Required Level" "Date"
  printf "  %-12s %-10s %-30s %-14s %-22s %-12s\n" \
    "------------" "----------" "------------------------------" \
    "--------------" "----------------------" "------------"
  for act in "${target_activities[@]}"; do
    if is_approved "${act}"; then
      local by jur lvl dt
      by="$(get_approval_field "${act}" by)"
      jur="$(get_approval_field "${act}" jurisdiction)"
      lvl="$(get_approval_field "${act}" level)"
      dt="$(get_approval_field "${act}" date)"
      printf "  %-12s %-10s %-30s %-14s %-22s %-12s\n" \
        "${act}" "YES" "${by}" "${jur}" "${lvl}" "${dt}"
    else
      printf "  %-12s %-10s %-30s %-14s %-22s %-12s\n" \
        "${act}" "NO" "—" "—" "—" "—"
    fi
  done
  echo ""

  # --- Feature Catalog Completion ---
  echo "## Feature Catalog Completion"
  printf "  %-12s %-10s %-8s %-12s\n" "Activity" "Checked" "Total" "Completion%"
  printf "  %-12s %-10s %-8s %-12s\n" "------------" "----------" "--------" "------------"
  for act in "${target_activities[@]}"; do
    read -r chk tot <<< "$(count_feature_gate "${act}")"
    local pct
    if [[ "${tot}" -gt 0 ]]; then
      pct="$(python3 -c "print(f'{${chk}/${tot}*100:.0f}%')")"
    else
      pct="N/A"
    fi
    printf "  %-12s %-10s %-8s %-12s\n" "${act}" "${chk}" "${tot}" "${pct}"
  done
  echo ""

  # --- Financial Governance Escalation Check ---
  echo "## Financial Governance Escalation Check"
  if [[ -z "${escalations}" ]]; then
    echo "  ✓ No escalation required"
  else
    while IFS= read -r msg; do
      echo "  ⚠ ${msg}"
    done <<< "${escalations}"
  fi
  echo ""

  echo "------------------------------------------------------------------------"
  echo " ITIL 5 Practice: Service Financial Management | Based on ITIL 5 preview spec"
  echo "========================================================================"
}

# ---------------------------------------------------------------------------
# HTML REPORT
# ---------------------------------------------------------------------------
print_html_report() {
  local target_activities
  read -ra target_activities <<< "$(get_target_activities)"

  local approved_count
  approved_count="$(count_approved)"
  local total_count="${#ALL_ACTIVITIES[@]}"
  local out_file="${SCRIPT_DIR}/report-${TIMESTAMP_FILE}.html"

  local eu_deploy_ok=false
  for i in "${!APPROVED_ACTIVITIES[@]}"; do
    [[ "${APPROVED_ACTIVITIES[$i]:-}" == "deploy" && "${JURISDICTION_LIST[$i]:-}" == "EU" ]] && eu_deploy_ok=true
  done

  local escalations
  escalations="$(compute_escalations)"
  local escalation_flag="No"
  [[ -n "${escalations}" ]] && escalation_flag="YES"

  {
    cat <<HTMLHEAD
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>ITIL 5 AI Governance Financial Report</title>
<style>
  body{font-family:Arial,sans-serif;margin:2em;color:#222;background:#f9f9f9;}
  h1{color:#1a3a5c;border-bottom:2px solid #1a3a5c;padding-bottom:0.3em;}
  h2{color:#2c5282;margin-top:1.5em;}
  table{border-collapse:collapse;width:100%;margin-top:0.5em;}
  th{background:#1a3a5c;color:#fff;padding:8px 12px;text-align:left;}
  td{padding:7px 12px;border:1px solid #ccc;}
  tr:nth-child(even){background:#eef2f7;}
  .approved{color:#276749;font-weight:bold;}
  .not-approved{color:#c53030;font-weight:bold;}
  .warning{color:#c05621;font-weight:bold;}
  .ok{color:#276749;}
  .summary-box{background:#eef2f7;border:1px solid #bee3f8;border-radius:6px;padding:1em 1.5em;margin-bottom:1em;}
  .escalation-box{background:#fff5f5;border:1px solid #fc8181;border-radius:6px;padding:1em 1.5em;margin-top:0.5em;}
  .no-escalation{background:#f0fff4;border:1px solid #9ae6b4;border-radius:6px;padding:0.8em 1.5em;}
  footer{margin-top:2em;border-top:1px solid #ccc;padding-top:0.8em;font-size:0.85em;color:#555;}
</style>
</head>
<body>
<h1>ITIL 5 AI Governance Financial Report</h1>
<p><strong>Generated:</strong> $(html_escape "${NOW}")</p>

<h2>Executive Summary</h2>
<div class="summary-box">
  <p><strong>Approved activities:</strong> $(html_escape "${approved_count}") / $(html_escape "${total_count}")</p>
HTMLHEAD

    if "${eu_deploy_ok}"; then
      echo "  <p><strong>EU High-Risk (deploy):</strong> <span class=\"approved\">APPROVED</span></p>"
    else
      echo "  <p><strong>EU High-Risk (deploy):</strong> <span class=\"not-approved\">NOT APPROVED</span></p>"
    fi

    if [[ -z "${escalations}" ]]; then
      echo "  <p><strong>Escalation required:</strong> <span class=\"ok\">No</span></p>"
    else
      echo "  <p><strong>Escalation required:</strong> <span class=\"not-approved\">YES</span></p>"
    fi

    echo "</div>"

    # --- Activity Status Table ---
    cat <<'ACTTABLE'
<h2>Activity Status Table</h2>
<table>
  <thead>
    <tr>
      <th>Activity</th><th>Approved</th><th>Approver</th>
      <th>Jurisdiction</th><th>Required Level</th><th>Date</th>
    </tr>
  </thead>
  <tbody>
ACTTABLE

    for act in "${target_activities[@]}"; do
      if is_approved "${act}"; then
        local by jur lvl dt
        by="$(get_approval_field "${act}" by)"
        jur="$(get_approval_field "${act}" jurisdiction)"
        lvl="$(get_approval_field "${act}" level)"
        dt="$(get_approval_field "${act}" date)"
        echo "    <tr>"
        echo "      <td>$(html_escape "${act}")</td>"
        echo "      <td class=\"approved\">YES</td>"
        echo "      <td>$(html_escape "${by}")</td>"
        echo "      <td>$(html_escape "${jur}")</td>"
        echo "      <td>$(html_escape "${lvl}")</td>"
        echo "      <td>$(html_escape "${dt}")</td>"
        echo "    </tr>"
      else
        echo "    <tr>"
        echo "      <td>$(html_escape "${act}")</td>"
        echo "      <td class=\"not-approved\">NO</td>"
        echo "      <td>—</td><td>—</td><td>—</td><td>—</td>"
        echo "    </tr>"
      fi
    done

    echo "  </tbody>"
    echo "</table>"

    # --- Feature Catalog Completion ---
    cat <<'FEATTABLE'
<h2>Feature Catalog Completion</h2>
<table>
  <thead>
    <tr><th>Activity</th><th>Checked</th><th>Total</th><th>Completion%</th></tr>
  </thead>
  <tbody>
FEATTABLE

    for act in "${target_activities[@]}"; do
      read -r chk tot <<< "$(count_feature_gate "${act}")"
      local pct color_class
      if [[ "${tot}" -gt 0 ]]; then
        pct="$(python3 -c "print(f'{${chk}/${tot}*100:.0f}%')")"
        local pct_num
        pct_num="$(python3 -c "print(int(${chk}/${tot}*100))")"
        if   [[ "${pct_num}" -ge 80 ]]; then color_class="approved"
        elif [[ "${pct_num}" -ge 50 ]]; then color_class="warning"
        else color_class="not-approved"
        fi
      else
        pct="N/A"
        color_class="warning"
      fi
      echo "    <tr>"
      echo "      <td>$(html_escape "${act}")</td>"
      echo "      <td>${chk}</td>"
      echo "      <td>${tot}</td>"
      echo "      <td class=\"${color_class}\">${pct}</td>"
      echo "    </tr>"
    done

    echo "  </tbody>"
    echo "</table>"

    # --- Financial Governance Escalation Check ---
    echo "<h2>Financial Governance Escalation Check</h2>"
    if [[ -z "${escalations}" ]]; then
      echo "<div class=\"no-escalation\">&#10003; No escalation required</div>"
    else
      echo "<div class=\"escalation-box\">"
      while IFS= read -r msg; do
        echo "  <p class=\"warning\">&#9888; $(html_escape "${msg}")</p>"
      done <<< "${escalations}"
      echo "</div>"
    fi

    cat <<HTMLFOOT

<footer>
  ITIL 5 Practice: Service Financial Management | Based on ITIL 5 preview spec (PeopleCert, 2026)
</footer>
</body>
</html>
HTMLFOOT

  } > "${out_file}"

  echo "HTML report written to: ${out_file}"
}

# ---------------------------------------------------------------------------
# --check-escalation only mode
# ---------------------------------------------------------------------------
run_check_escalation() {
  local escalations
  escalations="$(compute_escalations)"
  if [[ -z "${escalations}" ]]; then
    echo "✓ No escalation required"
    exit 0
  else
    while IFS= read -r msg; do
      echo "⚠ ${msg}"
    done <<< "${escalations}"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
load_approvals

if "${CHECK_ESCALATION_ONLY}"; then
  run_check_escalation
elif [[ "${FORMAT}" == "html" ]]; then
  print_html_report
else
  print_text_report
fi
