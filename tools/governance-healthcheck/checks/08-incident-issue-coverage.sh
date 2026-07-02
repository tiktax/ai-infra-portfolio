#!/usr/bin/env bash
# incident-issue-coverage — INCIDENTS.md の GitHub Issue 未起票を検出
#
# 背景: incident-lifecycle-guard は「クローズ時」のみ GitHub Issue を要求するが、
#       起票時の強制が欠如し INC-008 以降でも未起票が蓄積した（2026-06-23 実証）。
#       本チェックは台帳の完全性を毎セッション監視する（04-orphan-tokens の補完）。
# 免除: INC-001〜007 は guard 導入前(legacy)のため除外。
set -uo pipefail

INCIDENTS="${INCIDENTS_MD:?INCIDENTS_MD env var must point to your incidents log file (see README)}"

if [ ! -f "$INCIDENTS" ]; then
  echo "RESULT=FAIL"
  echo "incident-issue-coverage: INCIDENTS.md が見つかりません: $INCIDENTS"
  exit 0
fi

python3 - "$INCIDENTS" <<'PYEOF'
import re, sys

path = sys.argv[1]
with open(path) as f:
    rows = [l for l in f if re.match(r'\| 20\d\d', l)]

missing = []
for row in rows:
    cols = [c.strip() for c in row.split('|')]
    if len(cols) < 4:
        continue
    inc_id = cols[2].strip()
    m = re.search(r'INC-(\d+)', inc_id)
    if not m:
        continue
    if int(m.group(1)) <= 7:
        continue  # INC-001〜007: legacy（guard 導入前）
    gh_col = cols[-2].strip()
    if gh_col in ('—', '-', '', '─', '–'):
        missing.append(inc_id)

if missing:
    print(f"RESULT=FAIL")
    print(f"incident-issue-coverage: {len(missing)} 件の INC に GitHub Issue リンクなし (INC-008+)")
    for m in missing:
        print(f"  missing: {m}")
else:
    print("RESULT=PASS")
    print(f"incident-issue-coverage: 全 INC (INC-008+) に GitHub Issue リンクあり ({len(rows)} 件確認)")
PYEOF
