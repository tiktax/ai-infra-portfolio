#!/usr/bin/env bash
# index-integrity check — GOVERNANCE.md manifest セクションのファイル存在を確認
#
# 背景: manifest-driven アプローチ。GOVERNANCE.md が唯一の真実源。
#       パスのハードコード排除。
set -uo pipefail

GOV_DIR="${GOV_DIR:?GOV_DIR env var must point to your governance vault directory (see README)}"
GOV_FILE="$GOV_DIR/GOVERNANCE.md"

if [ ! -f "$GOV_FILE" ]; then
  echo "RESULT=FAIL"
  echo "index-integrity: GOVERNANCE.md が存在しない: $GOV_FILE"
  exit 0
fi

# manifest-start/end 間のパス行を抽出（コメント行と空行除外）
manifest=$(sed -n '/<!-- manifest-start -->/,/<!-- manifest-end -->/p' "$GOV_FILE" \
  | grep -v 'manifest-' | grep -v '^[[:space:]]*$' || true)

if [ -z "$manifest" ]; then
  echo "RESULT=FAIL"
  echo "index-integrity: GOVERNANCE.md に manifest セクションがない"
  exit 0
fi

# 各パスを確認（~/ を $HOME/ に展開）
missing_count=0
# 空白を含むパス(例: iCloud "Mobile Documents")対応のため行単位で読む。
# `for ... in $manifest` は IFS 空白分割でパスを壊す(正本移行 2026-06-12 修正)。
while IFS= read -r raw_path; do
  [ -z "$raw_path" ] && continue
  path="${raw_path/#\~/$HOME}"   # ~/ → $HOME/
  if [ ! -f "$path" ]; then
    echo "  missing: $raw_path"
    missing_count=$((missing_count + 1))
  fi
done <<< "$manifest"

if [ "$missing_count" -gt 0 ]; then
  echo "RESULT=FAIL"
  echo "index-integrity: ${missing_count} 件の governance 文書が存在しない"
else
  echo "RESULT=PASS"
  echo "index-integrity: 全 governance 文書の存在を確認 (manifest より)"
fi
