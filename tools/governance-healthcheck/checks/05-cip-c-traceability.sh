#!/usr/bin/env bash
# CIP-C traceability check — 完了 CIP が CHANGES.md に記録されているか確認
#
# 背景: CIP（改善提案）が実装されたら必ず CHANGES.md に C-ID + 起源:CIP-XXX で記録すべき
#       記録なし = 実装したが変更管理に台帳化されていない乖離
set -uo pipefail

GOV_DIR="${GOV_DIR:?GOV_DIR env var must point to your governance vault directory (see README)}"
CIP_FILE="$GOV_DIR/CIP.md"
CHANGES_FILE="$GOV_DIR/CHANGES.md"

# ファイル存在確認
if [ ! -f "$CIP_FILE" ]; then
  echo "RESULT=FAIL"
  echo "cip-c-traceability: CIP.md が存在しない: $CIP_FILE"
  exit 0
fi

if [ ! -f "$CHANGES_FILE" ]; then
  echo "RESULT=FAIL"
  echo "cip-c-traceability: CHANGES.md が存在しない: $CHANGES_FILE"
  exit 0
fi

# 完了/実装済み CIP の ID を抽出 (bash 3.2 互換)
# CIP.md テーブル行: | 日付 | CIP-XXX | ... | 完了|実装済み | ...
done_cips=$(grep -E '\|\s*CIP-[0-9]+\s*\|' "$CIP_FILE" \
  | grep -E '完了|実装済み' \
  | grep -oE 'CIP-[0-9]+' || true)

if [ -z "$done_cips" ]; then
  echo "RESULT=PASS"
  echo "cip-c-traceability: 完了 CIP なし(チェック対象なし)"
  exit 0
fi

# 各完了 CIP が CHANGES.md に記録されているか確認
missing=""
for cip_id in $done_cips; do
  if ! grep -q "$cip_id" "$CHANGES_FILE"; then
    missing="$missing $cip_id"
  fi
done
missing="${missing# }"

if [ -n "$missing" ]; then
  echo "RESULT=FAIL"
  echo "cip-c-traceability: CHANGES.md に記録のない完了 CIP を検出"
  for m in $missing; do echo "  missing: $m"; done
else
  echo "RESULT=PASS"
  echo "cip-c-traceability: 完了 CIP はすべて CHANGES.md に記録済み"
fi
