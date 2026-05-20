# ROI Calculator

Estimates the return on investment of deploying the AI harness to your organization.

## Usage

```bash
# Interactive mode — prompts for your values
./tools/roi-calculator/calculate.sh

# Sample values (for quick preview)
./tools/roi-calculator/calculate.sh --defaults
```

## Sample Output (20-person team, $1,000/month AI spend)

```
📊 ROI Summary
────────────────────────────────────────────

Inputs:
  Team size:                          20 users
  Monthly AI spend:                   $1000/month
  Avg engineer rate:                  $80/hour
  Incidents before harness:           2/month
  Avg incident resolution:            8 hours

Estimated Annual Savings:
  API cost reduction (99.5%):         $3,582
  Incident cost reduction (85%):      $13,056
  Productivity (5 min/session):       $88,000
  ─────────────────────────────────────
  Total annual savings:               $104,638

Deployment Cost (one-time):           $1,120
Payback period:                       0.1 months
3-year ROI:                           27,928%
```

## How savings are calculated

| Source | Basis | Measured data |
|--------|-------|---------------|
| **API cost** | 99.5% reduction on subprocess/automation calls | $0.21 → $0.001/call |
| **Incident cost** | 85% reduction in AI-related incidents | INC-011/012/013 post-hook data |
| **Productivity** | 5 min saved per session (SessionStart optimization) | 19 MB → 36 KB context |

See [`docs/achievements.md`](../../docs/achievements.md) for the full measurement basis.

## Adjusting assumptions

Edit `calculate.sh` to change the default reduction rates:

```bash
INCIDENT_REDUCTION_RATE="0.85"   # 85% incident reduction
MINS_SAVED_PER_SESSION=5         # minutes saved per Claude Code session
AUTOMATION_SPEND_RATIO=0.30      # % of monthly spend on automation calls
```
