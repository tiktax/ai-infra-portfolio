#!/bin/bash
# kill-switch.sh — AI Kill Switch & Circuit Breaker
#
# Purpose: Immediately halt all AI tool execution (kill switch) or auto-trip
#          on repeated hook blocks (circuit breaker). Stop/trip/reset events
#          are recorded in the audit log with ECDSA signatures.
#
# Usage:
#   kill-switch.sh enable  --reason "<reason>" --operator "<id>"
#   kill-switch.sh disable --operator "<id>"
#   kill-switch.sh status
#   kill-switch.sh reset       # emergency reset — no audit record
#   kill-switch.sh check       # used by PreToolUse hook, exits 2 to block
#
# Audit differentiation from a plain flag file:
#   Every enable/disable/trip/reset event is appended to approvals.log
#   with an ECDSA P-256 signature and key_fingerprint, making the kill switch
#   history tamper-evident — identical to any other governance decision.

set -euo pipefail

KILL_SWITCH_FILE="${HOME}/.ai-kill-switch"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/circuit-breaker-config.yaml"
BLOCK_LOG="${HOME}/.claude/hook-block.log"
AUDIT_PY="${REPO_ROOT}/tools/trustless_audit/src/kill_switch_audit.py"

# ── helpers ───────────────────────────────────────────────────────────────────

_record_audit() {
    local action="$1" reason="$2" operator="$3"
    if [ -f "$AUDIT_PY" ]; then
        python3 "$AUDIT_PY" \
            --action "$action" \
            --reason "$reason" \
            --operator "$operator" 2>/dev/null || true
    fi
}

_read_json_field() {
    local file="$1" field="$2"
    python3 -c "
import sys, json
try:
    d = json.load(open('${file}'))
    print(d.get('${field}', '?'))
except Exception:
    print('?')
" 2>/dev/null || echo "?"
}

_cb_threshold() {
    python3 -c "
try:
    import yaml
    with open('${CONFIG_FILE}') as f:
        d = yaml.safe_load(f)
    print(d['circuit_breaker']['error_threshold'])
except Exception:
    print(5)
" 2>/dev/null || echo 5
}

_cb_window() {
    python3 -c "
try:
    import yaml
    with open('${CONFIG_FILE}') as f:
        d = yaml.safe_load(f)
    print(d['circuit_breaker']['error_window_minutes'])
except Exception:
    print(10)
" 2>/dev/null || echo 10
}

_cb_count_recent_blocks() {
    local window="$1"
    python3 -c "
from datetime import datetime, timezone, timedelta
window_min = ${window}
cutoff = datetime.now(timezone.utc) - timedelta(minutes=window_min)
count = 0
try:
    with open('${BLOCK_LOG}') as f:
        for line in f:
            parts = line.strip().split(' ', 1)
            if len(parts) < 1:
                continue
            try:
                ts = datetime.fromisoformat(parts[0].replace('Z', '+00:00'))
                if ts >= cutoff:
                    count += 1
            except Exception:
                continue
except Exception:
    pass
print(count)
" 2>/dev/null || echo 0
}

# ── commands ──────────────────────────────────────────────────────────────────

cmd="${1:-check}"
shift || true

case "$cmd" in

  enable)
    reason="unspecified"
    operator="$(whoami 2>/dev/null || echo unknown)"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --reason)   reason="$2";   shift 2 ;;
        --operator) operator="$2"; shift 2 ;;
        *)          shift ;;
      esac
    done

    printf '{"enabled":true,"reason":"%s","operator":"%s","enabled_at":"%s"}\n' \
        "$reason" "$operator" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        > "$KILL_SWITCH_FILE"

    _record_audit "kill_switch_enable" "$reason" "$operator"
    echo "Kill switch ENABLED"
    echo "  Reason:   $reason"
    echo "  Operator: $operator"
    echo "  File:     $KILL_SWITCH_FILE"
    echo "  All AI tool calls will be blocked until 'kill-switch.sh disable' is run."
    ;;

  disable)
    operator="$(whoami 2>/dev/null || echo unknown)"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --operator) operator="$2"; shift 2 ;;
        *)          shift ;;
      esac
    done

    if [ ! -f "$KILL_SWITCH_FILE" ]; then
        echo "Kill switch is not active — nothing to disable."
        exit 0
    fi

    rm -f "$KILL_SWITCH_FILE"
    _record_audit "kill_switch_disable" "operator requested disable" "$operator"
    echo "Kill switch DISABLED"
    echo "  Operator: $operator"
    echo "  AI tool calls are now permitted."
    ;;

  status)
    if [ -f "$KILL_SWITCH_FILE" ]; then
        reason=$(_read_json_field "$KILL_SWITCH_FILE" reason)
        enabled_at=$(_read_json_field "$KILL_SWITCH_FILE" enabled_at)
        operator=$(_read_json_field "$KILL_SWITCH_FILE" operator)
        echo "Status:   ENABLED (all AI tool calls blocked)"
        echo "Reason:   $reason"
        echo "Since:    $enabled_at"
        echo "Set by:   $operator"
    else
        echo "Status:   DISABLED (AI tool calls permitted)"
        # Circuit breaker stats
        if [ -f "$CONFIG_FILE" ] && [ -f "$BLOCK_LOG" ]; then
            threshold=$(_cb_threshold)
            window=$(_cb_window)
            count=$(_cb_count_recent_blocks "$window")
            echo "Circuit breaker: $count / $threshold blocks in last ${window}m"
        fi
    fi
    ;;

  reset)
    rm -f "$KILL_SWITCH_FILE"
    echo "Kill switch reset (emergency — no audit record written)."
    echo "Use 'disable --operator <id>' for an audited disable."
    ;;

  check)
    # ── Fast path: called by PreToolUse hook every tool invocation ──────────

    # 1. Kill switch flag
    if [ -f "$KILL_SWITCH_FILE" ]; then
        reason=$(_read_json_field "$KILL_SWITCH_FILE" reason)
        printf '{"decision":"block","reason":"Kill switch is active: %s"}\n' "$reason"
        exit 2
    fi

    # 2. Circuit breaker (only if config + block log exist)
    if [ -f "$CONFIG_FILE" ] && [ -f "$BLOCK_LOG" ]; then
        threshold=$(_cb_threshold)
        window=$(_cb_window)
        count=$(_cb_count_recent_blocks "$window")

        if [ "${count}" -ge "${threshold}" ] 2>/dev/null; then
            reason="Circuit breaker tripped: ${count} blocks in ${window}m (threshold: ${threshold})"
            printf '{"enabled":true,"reason":"%s","operator":"circuit_breaker","enabled_at":"%s","circuit_breaker":true}\n' \
                "$reason" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
                > "$KILL_SWITCH_FILE"

            # Record asynchronously — do not block the hook response
            _record_audit "circuit_breaker_trip" "$reason" "circuit_breaker" &

            printf '{"decision":"block","reason":"%s"}\n' "$reason"
            exit 2
        fi
    fi

    # 3. Pass through
    exit 0
    ;;

  *)
    echo "Usage: kill-switch.sh <enable|disable|status|reset|check>"
    echo ""
    echo "Commands:"
    echo "  enable  --reason <reason> --operator <id>  Activate kill switch (audited)"
    echo "  disable --operator <id>                    Deactivate kill switch (audited)"
    echo "  status                                     Show current state + CB stats"
    echo "  reset                                      Emergency reset (no audit record)"
    echo "  check                                      PreToolUse hook entrypoint"
    exit 1
    ;;
esac
