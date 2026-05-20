# CLAUDE.md — Analyst Role Extensions
# Version: 1.0.0
# Extends: base.md

## Read-Only Data Access

✅ **Permitted:**
- Reading code, logs, configs (no modification)
- Running analysis scripts (read-only operations only)
- Creating reports in `/reports/` directory
- Querying metrics and dashboards (no write operations)
- `git clone`, `git log`, `git diff`, `git show` (read-only git)

❌ **Prohibited:**
- `git add`, `git commit`, `git push` (any git write operation)
- Modifying source code, configs, or environment files
- Bypassing security hooks or override comments
- Publishing reports without manager review

## Report Output Standards

- Save analysis to: `/reports/YYYYMMDD-<name>.md`
- Data exports: `/reports/data/` (anonymized only)
- Cite all data sources (file path + line range, not content)
- Include confidence level per finding: High / Medium / Low
- Sensitive findings → escalate to manager, do not publish directly

## Data Handling

- Strip PII before including in reports (IPs → REDACTED, emails → user@DOMAIN)
- Never access `.env`, credential files, or secret manager directly
- If sensitive data appears in logs: stop, notify engineer/manager immediately
- All analysis must be reproducible from cited sources

## Escalation Path

Finding → Report to manager via GitHub Issues → Manager decides action.
Do not implement fixes based on findings — always escalate.

## 日本語補足

- git 書込操作（commit/push等）: 禁止
- レポート出力先: `/reports/` のみ
- 機密データ発見時: 即座にエンジニア/管理職に通知
- 個人情報: レポートに含める前に匿名化
- 修正実装: 禁止（エスカレーションのみ）
