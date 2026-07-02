#!/usr/bin/env bash
# orphan-tokens check — ~/.claude/tokens/ の未消費承認トークンを検出
#
# 背景: トークンは one-time 承認証跡。hook が正常に消費すれば削除されるはず。
#       放置されたトークン = hook 未実行 or 破損 = 承認したのに処理されていない乖離
set -uo pipefail

TOKENS_DIR=${TOKENS_DIR:-$HOME/.claude/tokens}

# ディレクトリが存在しない → 問題なし(PASS)
if [ ! -d "$TOKENS_DIR" ]; then
  echo "RESULT=PASS"
  echo "orphan-tokens: トークンディレクトリが存在しない(問題なし): $TOKENS_DIR"
  exit 0
fi

# ファイル一覧を収集
orphans=""
for f in "$TOKENS_DIR"/*; do
  [ -f "$f" ] && orphans="$orphans $(basename "$f")"
done
orphans="${orphans# }"  # 先頭スペース除去

if [ -n "$orphans" ]; then
  echo "RESULT=FAIL"
  echo "orphan-tokens: 未消費トークンを検出 → hook が消費していない可能性"
  for t in $orphans; do echo "  orphan: $t"; done
else
  echo "RESULT=PASS"
  echo "orphan-tokens: 未消費トークンなし"
fi
