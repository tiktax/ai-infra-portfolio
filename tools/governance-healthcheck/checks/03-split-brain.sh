#!/usr/bin/env bash
# split-brain check — git worktree 台帳と実ディレクトリの乖離を検出
#
# 背景: stale worktree（ディレクトリ削除済みだが git に台帳が残ったもの）が蓄積すると
#       git台帳と現実が乖離。git worktree prune --dry-run で検出可能。
set -uo pipefail

GIT_REPO=${GIT_REPO:-$HOME/ClaudeCode}

if [ ! -d "$GIT_REPO/.git" ]; then
  echo "RESULT=FAIL"
  echo "split-brain: GIT_REPO が git リポジトリでない: $GIT_REPO"
  exit 0
fi

# INV-1: git worktree prune --dry-run で stale 台帳を検出 (--dry-run なので副作用なし)
stale=$(git -C "$GIT_REPO" worktree prune --dry-run 2>&1 || true)

# INV-2: ネスト独立 repo による governance 二重追跡を検出 (INC-023 2026-06-12 追加)
# 正本は Obsidian。~/ClaudeCode/Project 配下の内側 repo が governance を追跡していたら
# cwd 次第で別 repo に誤 commit される split-brain。submodule でない生 .git を問題視する。
INNER_REPO=${INNER_REPO:-$HOME/ClaudeCode/Project}
inner_gov=0
if { [ -d "$INNER_REPO/.git" ] || [ -f "$INNER_REPO/.git" ]; } \
   && [ "$(cd "$INNER_REPO" && git rev-parse --show-toplevel 2>/dev/null)" = "$INNER_REPO" ]; then
  inner_gov=$(git -C "$INNER_REPO" ls-files governance/ 2>/dev/null | wc -l | tr -d ' ')
fi

if [ -n "$stale" ]; then
  echo "RESULT=FAIL"
  echo "split-brain: stale worktree を検出 → git worktree prune が必要"
  printf '%s\n' "$stale"
elif [ "${inner_gov:-0}" -gt 0 ]; then
  echo "RESULT=FAIL"
  echo "split-brain: 内側 repo $INNER_REPO が governance を ${inner_gov} 件二重追跡 (INC-023)。正本は Obsidian、内側で追跡解除せよ"
else
  echo "RESULT=PASS"
  echo "split-brain: worktree 台帳一致 + 内側 repo の governance 二重追跡なし (INC-023 解消済)"
fi
