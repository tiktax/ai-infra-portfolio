# INC-011: Credential Exposed via AI Tool Output

**Severity**: P1 (High)
**Status**: ✅ Permanently resolved (→ CIP-005)
**Detected**: 2026-04 (exact date redacted)
**Resolved**: 2026-04 (within 3 days)

---

## Summary

An API credential was captured in the Claude Code session transcript after the AI agent executed a Bash command that read a `.env` file. The credential appeared in plain text in the session log, which is persisted to disk.

---

## Timeline

| Time | Event |
|------|-------|
| T+0h | AI agent executed `grep` against `.env` to verify a variable name |
| T+0h | Credential value appeared in terminal output and session transcript |
| T+1h | Session transcript scanned; credential exposure confirmed |
| T+2h | Credential revoked and rotated via secret manager |
| T+4h | Interim fix: manual rule added to CLAUDE.md prohibiting `.env` reads |
| T+72h | Permanent fix deployed (see CIP-005) |

---

## Root Cause Analysis

**Direct cause**: AI agent used `grep` on `.env` to check a field name — a task that does not require reading the value, only the key.

**Root cause**: No technical control existed to distinguish "read metadata" (safe) from "read content" (unsafe) for credential files. CLAUDE.md policy alone was insufficient — the AI could still issue the command.

**Contributing factor**: Session transcripts are persisted to disk in plaintext. Any command output containing credentials becomes a durable record.

---

## Impact

- 1 API credential exposed in session transcript
- Credential rotated; no evidence of external access
- Transcript file quarantined

---

## Resolution

### Interim (T+4h)
Added explicit prohibition to `CLAUDE.md`:
```
❌ Never use cat/grep/awk/sed on .env or *.key files
✅ Use wc -l for line count; [ -f ] for existence checks
```

### Permanent (CIP-005 → deployed T+72h)
Deployed `bash-secret-guard.sh` as a `PreToolUse` hook:
- Intercepts all Bash commands before execution
- Blocks content-reading commands targeting `.env`, `*.key`, `*.pem`, `tokens.json`, etc.
- Template files (`.env.example`, `.env.1password`) are explicitly excluded
- Provides remediation guidance on block

See: [`examples/hooks/bash-secret-guard.sh`](../hooks/bash-secret-guard.sh)

---

## Verification

Post-deployment test:
```bash
# This is now blocked automatically:
echo '{"tool_input":{"command":"grep API_KEY .env"}}' | bash examples/hooks/bash-secret-guard.sh
# → BLOCKED: .env/.key/.pem file content access detected

# This passes (metadata only):
echo '{"tool_input":{"command":"wc -l .env"}}' | bash examples/hooks/bash-secret-guard.sh
# → exit 0 (allowed)
```

Verified via `demo.sh` and `tests/hooks/run-tests.sh`.

---

## Lessons Learned

1. **Policy without enforcement is insufficient.** CLAUDE.md rules are advisory; PreToolUse hooks provide technical enforcement.
2. **Distinguish metadata access from content access.** `wc -l .env` and `cat .env` look similar but have very different risk profiles.
3. **Session transcripts are a persistence risk.** Any command output is durable. Treat transcript-visible output as potentially audited.

---

*Details redacted for public disclosure. Internal record maintained in GitHub Issues.*
