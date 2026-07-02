#!/usr/bin/env bash
# heartbeat-liveness check — Telegram ハートビート（sentinel）の鮮度を確認
#
# 背景: governance-heartbeat.sh が毎朝 08:00 に実行され、sentinel を更新するはず
#       sentinel が古い or 存在しない = ハートビート層が死んでいる = FAIL
#       相互鮮度監視: healthcheck が Telegram 層の生存を検証する
set -uo pipefail

SENTINEL="${SENTINEL:-$HOME/.claude/governance-heartbeat-last.txt}"
THRESHOLD_HOURS=${THRESHOLD_HOURS:-25}

# sentinel が存在しない → heartbeat 未送信
if [ ! -f "$SENTINEL" ]; then
  echo "RESULT=FAIL"
  echo "heartbeat-liveness: sentinel が存在しない → heartbeat 未送信"
  exit 0
fi

# sentinel の日時パースと経過時間計算
last_ts=$(cat "$SENTINEL" | tr -d '\n' 2>/dev/null || true)
last_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" "+%s" 2>/dev/null || true)
now_epoch=$(date +%s)

if [ -z "$last_epoch" ]; then
  echo "RESULT=FAIL"
  echo "heartbeat-liveness: sentinel のタイムスタンプが不正: $last_ts"
  exit 0
fi

hours_ago=$(( (now_epoch - last_epoch) / 3600 ))

if [ "$hours_ago" -gt "$THRESHOLD_HOURS" ]; then
  echo "RESULT=FAIL"
  echo "heartbeat-liveness: 最終 heartbeat が ${hours_ago}h 前 (閾値: ${THRESHOLD_HOURS}h) last=$last_ts"
else
  echo "RESULT=PASS"
  echo "heartbeat-liveness: 最終 heartbeat ${hours_ago}h 前 last=$last_ts"
fi
