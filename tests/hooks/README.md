# Hook Test Suite

Automated regression tests for the AI harness security hooks.

## Usage

```bash
# Run all hook tests
./tests/hooks/run-tests.sh

# Run tests for a specific hook
./tests/hooks/run-tests.sh --hook bash-secret-guard

# Quick demo (human-readable output)
./demo.sh
```

## Test Structure

Each hook is tested against:
- **Block cases**: Commands that MUST be intercepted (credential leak patterns)
- **Pass cases**: Commands that MUST be allowed (safe equivalents)
- **Edge cases**: Boundary conditions and potential bypass attempts

## Adding Tests

To add test cases for a new hook:

1. Add a `test_<hookname>()` function to `run-tests.sh`
2. Use `run_hook_test` with:
   - Hook name (without `.sh`)
   - Test description
   - JSON payload (PreToolUse format)
   - Expected result: `"block"` or `"pass"`

```bash
run_hook_test "my-hook" \
    "Description of what is tested" \
    '{"tool_input":{"command":"the command being tested"}}' \
    "block"
```

## CI Integration

Tests run automatically on every push via GitHub Actions (`.github/workflows/secrets-scan.yml`). To add hook tests to CI, extend the workflow to call `./tests/hooks/run-tests.sh`.

## Coverage

| Hook | Block cases | Pass cases | Status |
|------|------------|------------|--------|
| `bash-secret-guard` | 9 | 7 | ✅ |
| `npm-install-guard` | 1 | 2 | ✅ |
| `mcp-config-guard` | 4 | 5 | ✅ |
| `pre-commit-secrets` | 4 | 3 | ✅ |
| `worktree-guard` | 0* | 5 | ✅ |

*worktree-guard block cases require a specific git environment (parent repo + main branch).
Pass cases and override mechanism are fully tested. See `INC-013-redacted.md` for context.
