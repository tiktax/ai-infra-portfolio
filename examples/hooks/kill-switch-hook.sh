#!/bin/bash
# kill-switch-hook.sh — PreToolUse hook (thin wrapper)
#
# Purpose: Block all AI tool calls when kill switch is active or circuit breaker trips.
# Trigger: PreToolUse (all tools — no matcher filter needed)
# Delegates to: tools/kill-switch/kill-switch.sh check
#
# To activate kill switch: tools/kill-switch/kill-switch.sh enable --reason "..." --operator "..."
# To deactivate:           tools/kill-switch/kill-switch.sh disable --operator "..."
# To view status:          tools/kill-switch/kill-switch.sh status

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "${SCRIPT_DIR}/../../tools/kill-switch/kill-switch.sh" check
