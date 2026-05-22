#!/usr/bin/env bash
# monitor.sh — ITIL 5 Automated Post-deployment Monitoring
# ITIL 5 Practices: AI Governance (6C: Cognition, Curation), Change Enablement
# Based on ITIL 5 preview spec (PeopleCert, 2026); will align to final release.
#
# Reads feature-gates/05-operate.md and 06-observe.md, checks that
# evidence files exist and are sufficiently recent, and reports SLO status.
#
# Usage:
#   ./monitor.sh                          # full report
#   ./monitor.sh --alert                  # exit 1 if any SLO breach
#   ./monitor.sh --activity operate       # single activity
#   ./monitor.sh --max-age-days 14        # override freshness threshold (default: 7)
#   ./monitor.sh --format json            # JSON output
#
# Cron example (weekly, every Monday 08:00 UTC):
#   0 8 * * 1 cd /path/to/ai-infra-portfolio && \
#     bash tools/itil5-ai-governance/monitor.sh --alert >> /var/log/itil5-monitor.log 2>&1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURE_GATES_DIR="${SCRIPT_DIR}/feature-gates"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

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
# Defaults
# ---------------------------------------------------------------------------
ALERT_MODE=false
FORMAT="text"
MAX_AGE_DAYS=7
TARGET_ACTIVITY=""  # empty = all

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --alert)          ALERT_MODE=true;       shift ;;
    --format)         FORMAT="$2";           shift 2 ;;
    --max-age-days)   MAX_AGE_DAYS="$2";     shift 2 ;;
    --activity)       TARGET_ACTIVITY="$2";  shift 2 ;;
    --help|-h)        usage; exit 0 ;;
    *) err "Unknown option: $1"; exit 1 ;;
  esac
done

usage() {
  cat <<EOF
$(printf "${BOLD}monitor.sh${RESET}") — ITIL 5 Automated Post-deployment Monitoring

$(printf "${BOLD}Usage:${RESET}")
  ./monitor.sh [options]

$(printf "${BOLD}Options:${RESET}")
  --alert               Exit 1 if any SLO breach detected (for cron/CI use)
  --activity <name>     Check single activity only (operate|observe)
  --max-age-days <N>    Evidence file freshness threshold in days (default: 7)
  --format text|json    Output format (default: text)

$(printf "${BOLD}Examples:${RESET}")
  ./monitor.sh
  ./monitor.sh --alert
  ./monitor.sh --activity operate --max-age-days 3
  ./monitor.sh --format json | jq '.breaches'

$(printf "${BOLD}Cron example${RESET} (weekly Monday 08:00 UTC):${RESET}")
  0 8 * * 1 cd /path/to/ai-infra-portfolio && \\
    bash tools/itil5-ai-governance/monitor.sh --alert >> /var/log/itil5-monitor.log 2>&1
EOF
}

# ---------------------------------------------------------------------------
# Extract evidence file paths from a feature-gate markdown file
# Reads only the English section (stops at ## 日本語版)
# ---------------------------------------------------------------------------
extract_evidence_files() {
  local gate_file="$1"
  local in_japanese=0
  local in_table=0

  while IFS= read -r line; do
    # Stop at Japanese section
    if [[ "$line" =~ ^##[[:space:]]日本語版 ]]; then
      break
    fi
    # Detect feature table header
    if [[ "$line" =~ "| Feature |" ]]; then
      in_table=1
      continue
    fi
    # Skip table separator
    if [[ $in_table -eq 1 && "$line" =~ ^\|[-\ \|]+\|$ ]]; then
      continue
    fi
    # Extract evidence file from table rows: | Feature | Criteria | evidence/path | ☐ |
    if [[ $in_table -eq 1 && "$line" =~ ^\| ]]; then
      # Extract 3rd column (evidence file)
      local evidence_col
      evidence_col="$(echo "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4); print $4}')"
      if [[ -n "$evidence_col" && "$evidence_col" != "Evidence File" && "$evidence_col" != "Evidence" ]]; then
        echo "$evidence_col"
      fi
    elif [[ $in_table -eq 1 && ! "$line" =~ ^\| ]]; then
      in_table=0
    fi
  done < "$gate_file"
}

# ---------------------------------------------------------------------------
# Check a single evidence file
# Returns: "pass", "missing", or "stale:<days_old>"
# ---------------------------------------------------------------------------
check_evidence_file() {
  local rel_path="$1"
  local full_path="${REPO_ROOT}/${rel_path}"

  if [[ ! -f "$full_path" ]]; then
    echo "missing"
    return
  fi

  # Get file age in days (macOS BSD stat / GNU stat)
  local mtime_s now_s age_days
  now_s="$(date +%s)"
  mtime_s="$(stat -f '%m' "$full_path" 2>/dev/null || stat -c '%Y' "$full_path" 2>/dev/null || echo 0)"

  if [[ $mtime_s -eq 0 ]]; then
    echo "pass"  # can't determine age, assume OK
    return
  fi

  age_days=$(( (now_s - mtime_s) / 86400 ))

  if [[ $age_days -gt $MAX_AGE_DAYS ]]; then
    echo "stale:${age_days}"
  else
    echo "pass"
  fi
}

# ---------------------------------------------------------------------------
# Monitor a single activity
# ---------------------------------------------------------------------------
monitor_activity() {
  local activity="$1"
  local gate_file="${FEATURE_GATES_DIR}/$(activity_num "$activity")-${activity}.md"

  local pass=0 missing=0 stale=0
  local breach_details=()

  if [[ ! -f "$gate_file" ]]; then
    err "  Gate file not found: ${gate_file}"
    return 1
  fi

  while IFS= read -r evidence_file; do
    [[ -z "$evidence_file" ]] && continue
    local result
    result="$(check_evidence_file "$evidence_file")"
    case "$result" in
      pass)
        pass=$(( pass + 1 ))
        ;;
      missing)
        missing=$(( missing + 1 ))
        breach_details+=("MISSING: ${evidence_file}")
        ;;
      stale:*)
        local days="${result#stale:}"
        stale=$(( stale + 1 ))
        breach_details+=("STALE (${days}d > ${MAX_AGE_DAYS}d): ${evidence_file}")
        ;;
    esac
  done < <(extract_evidence_files "$gate_file")

  local total=$(( pass + missing + stale ))
  local breaches=$(( missing + stale ))

  if [[ "$FORMAT" == "json" ]]; then
    printf '{"activity":"%s","total":%d,"pass":%d,"missing":%d,"stale":%d,"breaches":[' \
      "$activity" "$total" "$pass" "$missing" "$stale"
    local first=true
    for detail in "${breach_details[@]}"; do
      $first && first=false || printf ','
      printf '"%s"' "$detail"
    done
    printf ']}'
    return
  fi

  # Text output
  printf "\n"
  bold "  Activity: ${activity}"
  printf "  Evidence files checked: %d\n" "$total"

  if [[ $breaches -eq 0 ]]; then
    ok "  Status: ✓ ALL PASS (${pass}/${total} evidence files present and fresh)"
  else
    err "  Status: ✗ ${breaches} SLO BREACH(ES)"
    for detail in "${breach_details[@]}"; do
      err "    → ${detail}"
    done
    warn "  Action: update evidence files or adjust --max-age-days threshold"
  fi

  return $breaches
}

# Lookup activity number (shared with phase-gate.sh pattern)
activity_num() {
  case "$1" in
    discover) echo "01" ;; design)  echo "02" ;;
    build)    echo "03" ;; deploy)  echo "04" ;;
    operate)  echo "05" ;; observe) echo "06" ;;
    improve)  echo "07" ;; retire)  echo "08" ;;
    *)        echo "" ;;
  esac
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  local monitored_activities=()

  if [[ -n "$TARGET_ACTIVITY" ]]; then
    monitored_activities=("$TARGET_ACTIVITY")
  else
    # Default: activities with operational evidence requirements
    monitored_activities=(operate observe)
  fi

  local total_breaches=0
  local json_parts=()

  if [[ "$FORMAT" == "text" ]]; then
    echo ""
    bold "============================================================"
    bold " ITIL 5 Post-deployment Monitor"
    bold " $(date -u '+%Y-%m-%d %H:%M:%S UTC') | Freshness threshold: ${MAX_AGE_DAYS} days"
    bold "============================================================"
  fi

  for activity in "${monitored_activities[@]}"; do
    local num
    num="$(activity_num "$activity")"
    if [[ -z "$num" ]]; then
      err "Unknown activity: ${activity}"
      continue
    fi

    if [[ "$FORMAT" == "json" ]]; then
      local part
      part="$(monitor_activity "$activity" 2>/dev/null || true)"
      json_parts+=("$part")
      # Count breaches from JSON
      local b
      b="$(echo "$part" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['missing']+d['stale'])" 2>/dev/null || echo 0)"
      total_breaches=$(( total_breaches + b ))
    else
      local breach_count=0
      monitor_activity "$activity" || breach_count=$?
      total_breaches=$(( total_breaches + breach_count ))
    fi
  done

  if [[ "$FORMAT" == "json" ]]; then
    printf '{"timestamp":"%s","max_age_days":%d,"total_breaches":%d,"results":[' \
      "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$MAX_AGE_DAYS" "$total_breaches"
    local first=true
    for part in "${json_parts[@]}"; do
      $first && first=false || printf ','
      printf '%s' "$part"
    done
    printf ']}\n'
  else
    echo ""
    printf '%0.s-' {1..60}; echo
    bold "Summary"
    printf "  Activities checked: %s\n" "${monitored_activities[*]}"
    printf "  Freshness threshold: %d days\n" "$MAX_AGE_DAYS"
    if [[ $total_breaches -eq 0 ]]; then
      ok "  Overall status: ✓ ALL PASS"
    else
      err "  Overall status: ✗ ${total_breaches} BREACH(ES) — action required"
    fi
    echo ""
    info "  Note: Evidence files are expected at paths listed in feature-gates/05-operate.md"
    info "        and feature-gates/06-observe.md relative to the repository root."
    info "        Create these files as your AI system generates monitoring data."
    echo ""
  fi

  if [[ "$ALERT_MODE" == "true" && $total_breaches -gt 0 ]]; then
    exit 1
  fi
}

main
