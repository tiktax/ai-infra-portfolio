#!/usr/bin/env bash
# SLO-log.csv liveness check — scheduled-task が発火したのに結果を書かない乖離を検出
#
# 検出対象: 週次 scheduled-task が SLO-log に行を追加していない(stale)状態
# 対策: SLO-log.csv が直近 STALENESS_THRESHOLD_DAYS 日以内に更新されているかチェック
set -uo pipefail

GOV_DIR="${GOV_DIR:?GOV_DIR env var must point to your governance vault directory (see README)}"
SLO_LOG="$GOV_DIR/SLO-log.csv"
STALENESS_THRESHOLD_DAYS=${STALENESS_THRESHOLD_DAYS:-7}

# ファイル不存在 → FAIL
if [ ! -f "$SLO_LOG" ]; then
  echo "RESULT=FAIL"
  echo "liveness: SLO-log.csv が存在しない: $SLO_LOG"
  exit 0
fi

# 最新日付行を取得（ヘッダ行 "Date,..." を除いて YYYY-MM-DD 形式の最終行）
last_date=$(grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2},' "$SLO_LOG" | tail -1 | cut -d, -f1 || true)

if [ -z "$last_date" ]; then
  echo "RESULT=FAIL"
  echo "liveness: SLO-log.csv にデータ行がない"
  exit 0
fi

# macOS date で日付差を計算 (bash 3.2 / macOS 互換)
today=$(date +%Y-%m-%d)
last_epoch=$(date -j -f "%Y-%m-%d" "$last_date" "+%s" 2>/dev/null || true)
today_epoch=$(date -j -f "%Y-%m-%d" "$today" "+%s" 2>/dev/null || true)

if [ -z "$last_epoch" ] || [ -z "$today_epoch" ]; then
  echo "RESULT=FAIL"
  echo "liveness: 日付パース失敗 last=$last_date today=$today"
  exit 0
fi

days_stale=$(( (today_epoch - last_epoch) / 86400 ))

if [ "$days_stale" -gt "$STALENESS_THRESHOLD_DAYS" ]; then
  echo "RESULT=FAIL"
  echo "liveness: SLO-log.csv が ${days_stale}日 stale (閾値: ${STALENESS_THRESHOLD_DAYS}日) last=$last_date"
else
  echo "RESULT=PASS"
  echo "liveness: SLO-log.csv は ${days_stale}日前に更新済み last=$last_date"
fi
