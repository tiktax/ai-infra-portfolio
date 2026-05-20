# CLAUDE.md — Engineer Role Extensions
# Version: 1.0.0
# Extends: base.md

## Git & Code Authority

✅ **Permitted:**
- Feature branch commits (with `Co-Authored-By` footer)
- Hook configuration changes (peer review required before merge)
- Test fixtures with `# allow-secret: test fixture` (fake values only)
- Worktree creation and cleanup
- Subagent spawning for parallel tasks

❌ **Prohibited:**
- Direct commits to main/master (worktree-guard blocks)
- `git push --force` without explicit user approval
- Credentials in commit messages or PR titles
- Skipping `pre-commit-secrets.sh` scan

## Security Hook Overrides

Use `# worktree-guard:allow` **only when:**
- Deliberately modifying the parent repository (state reason in commit message)
- Running git maintenance (gc, pack cleanup)

Use `# allow-secret: <reason>` **only for:**
- Test fixtures with clearly non-production values (`test_key_XXXXX`)
- `.env.example` templates (never actual values)
- Reason must include: `test fixture` / `non-production` / `placeholder`

## Cost & Performance

- Use local LLM (light alias) for: grep, format, summarize, template generation
- Use cloud LLM (heavy/auto) for: design decisions, RCA, security review
- Target: < $0.05/session through local LLM + parallelization
- Parallel subagents for: multi-file refactoring, independent test suites

## Debugging & RCA

- List 3 hypotheses before fixing any bug
- Test each hypothesis before selecting root cause
- Hook failures → diagnose before retrying
- Secrets in staged files → rotate credentials before proceeding

## 日本語補足

- フィーチャーブランチへのコミットは許可
- main への直接書込: worktree-guard.sh がブロック
- `# worktree-guard:allow`: 意図的な場合のみ使用・コミットメッセージに理由を記載
- `# allow-secret:`: テスト固定値のみ・理由必須
