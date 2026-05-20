# CLAUDE.md — Base Security & Behavior Guidelines
# Version: 1.0.0
# Maintained by: claude-config-manager
# DO NOT EDIT MANUALLY — managed via tools/claude-config-manager/

All Claude Code sessions apply these rules. Role-specific rules extend this base.

## Core Security (Non-negotiable)

- **Never paste tokens/passwords/API keys in chat.** Use: `echo "..." > file` in terminal
- **1Password CLI is the only credential source.** Reference: `op://vault/item/field`
- **No secrets in markdown files.** Use dummy values: `ntn_XXXXXXXXXXXXXXXXXXXXX`
- **No credentials in git history.** Run `pre-commit-secrets.sh` before every commit
- **`.env*` / `*.key` / `*.pem` files are read-forbidden.** Use `wc -l` for metadata only

## Before Any Production Change

1. Verify AI-generated code with tests before deploying
2. Run `git diff --cached` to confirm no credentials in staged changes
3. Get explicit user approval for irreversible actions (delete / merge / publish)

## Incident Reporting

When a security or reliability incident occurs:
1. **Pause all work** — open a GitHub Issue immediately
2. **Document root cause** — list 3 hypotheses, test each before acting
3. **Rotate credentials** if exposed — before any other remediation
4. **File post-incident review** in project incident log

## Git & Worktree Discipline

- Verify branch before any write: `git rev-parse --show-toplevel && git branch --show-current`
- No direct writes to main/master from a worktree session
- Hook `worktree-guard.sh` blocks parent-repo writes automatically
- Hook `pre-commit-secrets.sh` scans staged diff for 16 credential patterns

## Response Standards

- No filler phrases ("Great question!", "Of course!"). Match length to task complexity
- Uncertain information: state "uncertain" before answering
- Provide time estimate before any significant task
- Report actual vs. planned time on completion

## 日本語補足

- APIキー・トークン: チャットに貼らない
- 秘密情報: `op://` 参照のみ
- `.env` ファイル: 読取禁止（`wc -l` でメタデータのみ確認可）
- インシデント: 即座に GitHub Issues に記録 → 根本原因分析 → 恒久解消
