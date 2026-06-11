#!/usr/bin/env bash
# カナリア(必ず PASS): 検証エンジンが「PASS を正しく判定する」ことを毎回証明する。
# always-FAIL カナリアと対で、エンジンが PASS/FAIL を区別できることを示す。撤去禁止。
set -euo pipefail
echo "RESULT=PASS"
echo "canary: 意図的に必ず PASS。エンジンが PASS を検出できることの証明。"
