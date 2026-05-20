#!/bin/bash
# calculate.sh — AI Harness ROI Calculator
#
# Estimates the return on investment of deploying this AI harness
# to an organization, based on team size, AI spend, and incident rate.
#
# Usage:
#   ./tools/roi-calculator/calculate.sh              # interactive mode
#   ./tools/roi-calculator/calculate.sh --defaults   # run with sample values
#
# No external dependencies required.

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ── Helpers ──────────────────────────────────────────────────────────────────

ask() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    printf "%s [default: %s]: " "$prompt" "$default"
    read -r input
    eval "$var_name=\"${input:-$default}\""
}

hr() { echo "────────────────────────────────────────────"; }

# ── Inputs ───────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}🧮 AI Harness ROI Calculator${NC}"
hr
echo "Estimates annual savings and risk reduction from deploying"
echo "the AI harness to your organization."
echo ""

if [ "${1:-}" = "--defaults" ]; then
    TEAM_SIZE=20
    MONTHLY_AI_SPEND=1000
    AVG_HOURLY_RATE=80
    INCIDENTS_PER_MONTH=2
    AVG_INCIDENT_HOURS=8
    echo -e "${YELLOW}Running with sample values (--defaults mode)${NC}"
    echo ""
else
    ask "Team size (number of Claude Code users)" "10" TEAM_SIZE
    ask "Monthly AI API spend per team, USD" "500" MONTHLY_AI_SPEND
    ask "Average hourly rate per engineer, USD" "80" AVG_HOURLY_RATE
    ask "AI-related incidents per month (before harness)" "2" INCIDENTS_PER_MONTH
    ask "Average hours to resolve one incident" "6" AVG_INCIDENT_HOURS
fi

# ── Calculations ─────────────────────────────────────────────────────────────

# 1. API cost savings (99.5% reduction on subprocess calls)
#    Assumes 30% of monthly spend is on subprocess/automation calls
AUTOMATION_SPEND=$(echo "$MONTHLY_AI_SPEND * 0.30" | bc)
ANNUAL_AUTOMATION_SPEND=$(echo "$AUTOMATION_SPEND * 12" | bc)
ANNUAL_API_SAVINGS=$(echo "$ANNUAL_AUTOMATION_SPEND * 0.995" | bc)

# 2. Incident cost savings
#    Before harness: N incidents/month × hours × hourly rate
#    After harness: ~85% reduction (based on INC-011/012/013 pattern)
MONTHLY_INCIDENT_COST=$(echo "$INCIDENTS_PER_MONTH * $AVG_INCIDENT_HOURS * $AVG_HOURLY_RATE" | bc)
ANNUAL_INCIDENT_COST=$(echo "$MONTHLY_INCIDENT_COST * 12" | bc)
INCIDENT_REDUCTION_RATE="0.85"
ANNUAL_INCIDENT_SAVINGS=$(echo "$ANNUAL_INCIDENT_COST * $INCIDENT_REDUCTION_RATE" | bc)

# 3. Context / productivity savings
#    SessionStart optimization: saves ~5 min/session, assume 3 sessions/day/person
#    Value: team_size × 3 sessions × 5 min × working days × hourly_rate / 60
WORKING_DAYS=220
SESSIONS_PER_DAY=3
MINS_SAVED_PER_SESSION=5
ANNUAL_PRODUCTIVITY_SAVINGS=$(echo "scale=2; $TEAM_SIZE * $SESSIONS_PER_DAY * $MINS_SAVED_PER_SESSION * $WORKING_DAYS * $AVG_HOURLY_RATE / 60" | bc)

# 4. Total savings
TOTAL_ANNUAL_SAVINGS=$(echo "scale=2; $ANNUAL_API_SAVINGS + $ANNUAL_INCIDENT_SAVINGS + $ANNUAL_PRODUCTIVITY_SAVINGS" | bc)

# 5. Deployment cost estimate
#    One-time: 4h setup × team_size × 0.5h onboarding × hourly_rate
SETUP_HOURS=4
ONBOARDING_HOURS_PER_PERSON="0.5"
DEPLOYMENT_COST=$(echo "scale=2; ($SETUP_HOURS + $TEAM_SIZE * $ONBOARDING_HOURS_PER_PERSON) * $AVG_HOURLY_RATE" | bc)

# 6. Payback period (months)
MONTHLY_SAVINGS=$(echo "scale=2; $TOTAL_ANNUAL_SAVINGS / 12" | bc)
PAYBACK_MONTHS=$(echo "scale=1; $DEPLOYMENT_COST / $MONTHLY_SAVINGS" | bc)

# 7. 3-year ROI
THREE_YEAR_SAVINGS=$(echo "scale=2; $TOTAL_ANNUAL_SAVINGS * 3" | bc)
THREE_YEAR_ROI=$(echo "scale=0; ($THREE_YEAR_SAVINGS - $DEPLOYMENT_COST) * 100 / $DEPLOYMENT_COST" | bc)

# ── Output ───────────────────────────────────────────────────────────────────

echo ""
hr
echo -e "${BOLD}📊 ROI Summary${NC}"
hr
echo ""
echo -e "${CYAN}Inputs:${NC}"
printf "  %-35s %s\n" "Team size:"                   "$TEAM_SIZE users"
printf "  %-35s \$%s/month\n" "Monthly AI spend:"    "$MONTHLY_AI_SPEND"
printf "  %-35s \$%s/hour\n" "Avg engineer rate:"    "$AVG_HOURLY_RATE"
printf "  %-35s %s/month\n" "Incidents before harness:" "$INCIDENTS_PER_MONTH"
printf "  %-35s %s hours\n" "Avg incident resolution:"  "$AVG_INCIDENT_HOURS"

echo ""
echo -e "${CYAN}Estimated Annual Savings:${NC}"
printf "  %-35s ${GREEN}\$%'.0f${NC}\n" "API cost reduction (99.5%):"        "${ANNUAL_API_SAVINGS%.*}"
printf "  %-35s ${GREEN}\$%'.0f${NC}\n" "Incident cost reduction (85%):"     "${ANNUAL_INCIDENT_SAVINGS%.*}"
printf "  %-35s ${GREEN}\$%'.0f${NC}\n" "Productivity (5 min/session):"      "${ANNUAL_PRODUCTIVITY_SAVINGS%.*}"
echo "  ─────────────────────────────────────"
printf "  %-35s ${GREEN}${BOLD}\$%'.0f${NC}\n" "Total annual savings:"          "${TOTAL_ANNUAL_SAVINGS%.*}"

echo ""
echo -e "${CYAN}Deployment Cost (one-time):${NC}"
printf "  %-35s \$%'.0f\n" "Setup + onboarding:"             "${DEPLOYMENT_COST%.*}"

echo ""
echo -e "${CYAN}Return on Investment:${NC}"
printf "  %-35s %s months\n" "Payback period:"              "$PAYBACK_MONTHS"
printf "  %-35s %s%%\n" "3-year ROI:"                       "$THREE_YEAR_ROI"

echo ""
hr
echo -e "${YELLOW}Assumptions:${NC}"
echo "  - API savings based on 99.5% reduction on automation/subprocess calls"
echo "    (measured: \$0.21 → \$0.001/call with --setting-sources '' --tools '')"
echo "  - Incident reduction: 85% (based on INC-011/012/013 post-hook data)"
echo "  - Productivity: 5 min saved/session via SessionStart optimization"
echo "    (measured: 19 MB → 36 KB context, ~99.8% reduction)"
echo "  - Deployment: 4h admin setup + 0.5h onboarding per person"
echo ""
echo "  All figures are estimates. Actual results depend on team usage patterns."
echo "  See docs/achievements.md for measured baseline data."
hr
echo ""
