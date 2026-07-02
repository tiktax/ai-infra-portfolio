#!/usr/bin/env bash
# governance-healthcheck — 自己検証する不変条件(invariant)エンジン
#
# 思想: 散文のガバナンス台帳は人手同期に律速され「静かに腐る」。
#       判断を「機械が自動執行し、自分が壊れたら大声で叫ぶ assertion」に置換する。
#       敵は「壊れること」でなく「静かに壊れること」。
#
# 設計(Stage-1 敵対検証 + 初回実行の実地検証で硬化):
#   - default-FAIL : check は明示的に RESULT=PASS と言った時だけ PASS。
#                    判定不能・未実行・error は全て FAIL(grep 終了コードに合否を委ねない)。
#   - 2枚カナリア  : 必ず FAIL / 必ず PASS する check を置き、両者が名前通り判定されることで
#                    「検証エンジンが空振りしていない」ことを実行時に自己証明する。
#                    エンジンが途中破綻すればカナリア結果が ABSENT となり exit 3 で叫ぶ。
#   - exec-bit 検査: 非実行ビットの check は silent skip でなく FAIL(INC-020 教訓)。
#   - bash 3.2 互換: 連想配列(declare -A, bash4+)を使わない。初回実行で macOS 標準 bash が
#                    declare -A 非対応のまま exit 0 で silent fail した教訓を反映。
#
# 終了コード: 0=全 gov check PASS / 1=gov check FAIL / 3=エンジン整合性異常(カナリア破綻)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKS_DIR="$HERE/checks"

# check を1つ実行し PASS|FAIL|MISSING|NOTEXEC を echo する(default-FAIL)
run_check() {
  local chk="$1" out verdict
  if [ ! -x "$chk" ]; then echo "NOTEXEC"; return; fi   # INC-020: 黙殺せず FAIL 扱い
  out="$(timeout 30 "$chk" 2>&1)" || true
  verdict="$(printf '%s\n' "$out" | grep -oE 'RESULT=(PASS|FAIL)' | tail -1 | cut -d= -f2 || true)"
  echo "${verdict:-MISSING}"   # 証跡なし = MISSING = FAIL
}

registered=0
gov_pass=0
gov_fail=0
problems=""
canary_fail_result="ABSENT"
canary_pass_result="ABSENT"

for chk in "$CHECKS_DIR"/*.sh; do
  [ -e "$chk" ] || continue
  registered=$((registered + 1))
  name="$(basename "$chk" .sh)"
  status="$(run_check "$chk")"
  case "$name" in
    00-canary-fail) canary_fail_result="$status" ;;
    01-canary-pass) canary_pass_result="$status" ;;
    *)
      if [ "$status" = "PASS" ]; then
        gov_pass=$((gov_pass + 1))
      else
        gov_fail=$((gov_fail + 1))
        problems="$problems $name=$status"
      fi
      ;;
  esac
done

# --- カナリア整合性: 検証エンジン自身の生存証明(無限後退を機械で深さ1で止める) ---
engine_broken=0
[ "$canary_fail_result" = "FAIL" ] || engine_broken=1
[ "$canary_pass_result" = "PASS" ] || engine_broken=1

canary_state="OK"; [ "$engine_broken" -eq 0 ] || canary_state="BROKEN"
echo "governance-healthcheck: registered=$registered canary=$canary_state gov_pass=$gov_pass gov_fail=$gov_fail"
if [ -n "$problems" ]; then
  for p in $problems; do echo "  FAIL: $p"; done
fi

if [ "$engine_broken" -ne 0 ]; then
  echo "  ENGINE-INTEGRITY: カナリア異常(fail=$canary_fail_result pass=$canary_pass_result) — 検証エンジン自体が壊れている。結果を信用するな"
  exit 3
fi
[ "$gov_fail" -eq 0 ] || exit 1
exit 0
