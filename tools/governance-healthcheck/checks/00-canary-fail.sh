#!/usr/bin/env bash
# カナリア(必ず FAIL): 検証エンジンが「FAIL を正しく判定する」ことを毎回証明する。
# この check が FAIL にならなくなった日 = エンジンが空振り(全部 vacuous PASS)している日。
# 煙感知器のテストボタン。撤去禁止。
set -euo pipefail
echo "RESULT=FAIL"
echo "canary: 意図的に必ず FAIL。エンジンが FAIL を検出できることの証明。"
