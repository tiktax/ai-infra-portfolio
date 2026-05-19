# INC-013: Git Write Operation on Parent Repository Main Branch

**Severity**: P1 (High)
**Status**: ✅ Permanently resolved (→ CIP-006)
**Detected**: 2026-05 (exact date redacted)
**Resolved**: 2026-05 (within 24 hours)

---

## Summary

A `git commit` was executed on the parent repository's `main` branch from a Claude Code session that was intended to be scoped to a git worktree. The commit bypassed the intended isolation boundary.

---

## Timeline

| Time | Event |
|------|-------|
| T+0h | New Claude Code session launched; working directory was parent repo root |
| T+0h | AI agent ran `git add` + `git commit` on `main` branch |
| T+1h | Commit detected in parent repo history during routine review |
| T+2h | Commit reverted; branch history cleaned |
| T+4h | Interim rule added to CLAUDE.md |
| T+24h | Permanent fix deployed (see CIP-006) |

---

## Root Cause Analysis

**Direct cause**: Claude Code session started with `cwd` set to the parent repository root rather than a worktree subdirectory. No guardrail existed to detect this misconfiguration before git operations ran.

**Root cause**: Worktree isolation relied entirely on the user launching sessions from the correct directory. No technical enforcement existed to verify that git write operations were running inside a worktree.

**Contributing factor**: Session startup context did not surface the current git branch or repository root prominently enough to catch the error before the first command.

---

## Impact

- 1 unintended commit on `main` branch
- Successfully reverted; no data loss
- Identified gap in worktree isolation design

---

## Resolution

### Interim (T+4h)
Added to `CLAUDE.md`:
```
Before any git write operation, verify:
  git rev-parse --show-toplevel && git branch --show-current
```

### Permanent (CIP-006 → deployed T+24h)
Deployed `worktree-guard.sh` as a `PreToolUse` hook:
- Intercepts all git write operations (commit, push, merge, reset, etc.)
- Detects if `cwd` is inside the parent repo on `main`/`master`
- Blocks the operation and explains the misconfiguration
- Provides an explicit override escape hatch: `# worktree-guard:allow`

Also deployed `session-start-suggest-worktree.sh` as a `SessionStart` hook:
- At session start, lists existing worktrees for the current base repo
- Prompts user to re-enter an existing worktree rather than starting fresh

See: [`examples/hooks/worktree-guard.sh`](../hooks/worktree-guard.sh)

---

## Verification

```bash
# Simulate the blocked scenario (dry run, no actual git operation):
echo '{"tool_input":{"command":"git commit -m test"}}' \
  | bash examples/hooks/worktree-guard.sh
# → BLOCKED (if run from parent repo main branch)
# → exit 0  (if run from inside a worktree)
```

---

## Lessons Learned

1. **Isolation boundaries need technical enforcement, not just convention.** Worktree discipline documented in CLAUDE.md was not enough to prevent human error.
2. **Session start is the right moment to verify context.** Catching the misconfiguration at launch (via SessionStart hook) is cheaper than recovering from a bad commit.
3. **Escape hatches must be explicit.** The `# worktree-guard:allow` override makes intentional bypasses visible in the transcript.

---

*Details redacted for public disclosure. Internal record maintained in GitHub Issues.*
