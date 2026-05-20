# AI Harness Deployment Playbook

A step-by-step guide for deploying the AI harness to a team of 10 or more.

> **Scope**: This playbook covers deploying the security hooks, CLAUDE.md behavioral spec,
> and governance framework from this repository to a multi-person team.
> Estimated deployment time: **2–4 hours** for a team of 10.

---

## 1. Prerequisites

### Required on each machine

| Requirement | Version | Check |
|-------------|---------|-------|
| Claude Code CLI | Latest | `claude --version` |
| bash | 3.2+ | `bash --version` |
| Python 3 | 3.8+ | `python3 --version` |
| git | 2.x+ | `git --version` |
| 1Password CLI | 2.x+ | `op --version` |

### Required access

- [ ] GitHub repository access (to clone this repo)
- [ ] 1Password vault access (for secret management)
- [ ] Claude Code account / API key (via 1Password, not plaintext)

### Pre-flight check

```bash
git clone https://github.com/tiktax/ai-infra-portfolio
cd ai-infra-portfolio
./demo.sh   # should show 16 passed, 0 failed
```

---

## 2. Installation

Run the automated installer — it handles hook copy, settings.json merge, and worktree-guard configuration in one command.

```bash
# Basic install (configure role separately via manage.sh)
bash install.sh --repo-path ~/your-project-directory

# Install with role-based permissions applied immediately
bash install.sh --role engineer --repo-path ~/your-project-directory

# Preview all steps without executing
bash install.sh --dry-run
```

**What `install.sh` does automatically:**

| Step | Action |
|------|--------|
| Pre-flight | Checks claude, bash, python3, git (required); jq, op (recommended) |
| Hooks | Copies `examples/hooks/*.sh` → `~/.claude/hooks/` + chmod +x (idempotent) |
| Settings | Merges hooks block into `~/.claude/settings.json` (no duplicates; backup created) |
| Worktree guard | Configures `PARENT_REPO` path in `worktree-guard.sh` |
| Verify | Runs `demo.sh` to confirm hooks are working |
| Log | Records install event to `~/.claude/install-log.jsonl` |

> **Note**: If you need to apply role-based access controls (permissions.allow/deny), run `install.sh` first, then `manage.sh install --role <role>`. Both scripts write to `~/.claude/settings.json` — run them sequentially, not in parallel.

### Manual installation (fallback)

If `install.sh` cannot run (e.g., restricted environment), follow these steps manually:

<details>
<summary>Manual steps (click to expand)</summary>

**Step 1 — Copy hooks**
```bash
HOOKS_DIR="${HOME}/.claude/hooks"
mkdir -p "$HOOKS_DIR"
cp examples/hooks/*.sh "$HOOKS_DIR/"
chmod +x "$HOOKS_DIR"/*.sh
```

**Step 2 — Register hooks in settings.json**

Add to `~/.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [
          { "type": "command", "command": "bash ~/.claude/hooks/bash-secret-guard.sh" },
          { "type": "command", "command": "bash ~/.claude/hooks/worktree-guard.sh" },
          { "type": "command", "command": "bash ~/.claude/hooks/npm-install-guard.sh" },
          { "type": "command", "command": "bash ~/.claude/hooks/pre-commit-secrets.sh" }
      ]},
      { "matcher": "Write|Edit", "hooks": [
          { "type": "command", "command": "bash ~/.claude/hooks/mcp-config-guard.sh" }
      ]}
    ]
  }
}
```

**Step 3 — Configure worktree-guard**
Edit `~/.claude/hooks/worktree-guard.sh` and set:
```bash
PARENT_REPO = os.path.expanduser('~/your-project-parent')
```

**Verify**
```bash
./demo.sh
./tests/hooks/run-tests.sh
```
</details>

---

## 3. CLAUDE.md Distribution Strategy

### Option A — Centralized (recommended for 10–30 people)

Maintain a single `CLAUDE.md` in a shared repository. Each team member symlinks it:

```bash
# On each team member's machine:
ln -sf /path/to/shared-repo/CLAUDE.md ~/.claude/CLAUDE.md
```

**Pros**: Single source of truth. Changes propagate automatically on `git pull`.
**Cons**: No per-user customization.

### Option B — Role-based (recommended for 30+ people)

Maintain role-specific CLAUDE.md files in a shared repository:

```
shared-repo/
├── claude-configs/
│   ├── CLAUDE-engineer.md
│   ├── CLAUDE-analyst.md
│   └── CLAUDE-manager.md
└── CLAUDE-base.md   ← shared baseline
```

Each role's file includes the base via a header comment and adds role-specific rules.

### Versioning

- Store CLAUDE.md in git with semantic versioning in the header: `# CLAUDE.md v1.2.0`
- Use GitHub releases to announce breaking changes
- Add a `CHANGELOG` section at the bottom of CLAUDE.md

---

## 4. Role-based Configuration

### Permission matrix

| Capability | Engineer | Analyst | Manager |
|-----------|---------|---------|---------|
| Run hook bypass (`worktree-guard:allow`) | ✅ | ❌ | ❌ |
| Commit to feature branches | ✅ | ✅ | ❌ |
| Modify hook configuration | ✅ (review required) | ❌ | ❌ |
| Access to incident records | ✅ | Read-only | ✅ |
| Override secret scan (`allow-secret:`) | ✅ (justified only) | ❌ | ❌ |

### Applying permissions to settings.json

The permission matrix above is enforced in `~/.claude/settings.json` via the config manager.
Run after `install.sh`:

```bash
# Apply role-based permissions (merges allow/deny into settings.json)
./tools/claude-config-manager/manage.sh install --role engineer

# Verify permissions have not been tampered with since install
./tools/claude-config-manager/manage.sh verify

# Escalate a user's role (requires second approver)
./tools/claude-config-manager/manage.sh escalate \
  --from analyst --to engineer --approver manager@example.com
```

### Engineer CLAUDE.md additions

```markdown
# Role: Engineer
# Permitted: worktree-guard:allow, allow-secret: with justification
# Prohibited: pushing directly to main without PR
```

### Analyst CLAUDE.md additions

```markdown
# Role: Analyst
# Permitted: read-only git operations, file creation in /reports/
# Prohibited: git commit, git push, modifying hooks or settings
```

### Manager CLAUDE.md additions

```markdown
# Role: Manager
# Permitted: read-only across all areas, incident review
# Prohibited: all write operations, code changes
```

---

## 5. Onboarding Checklist

For each new team member, complete the following:

### Before Day 1 (admin)
- [ ] Grant GitHub repository access
- [ ] Add to 1Password vault (relevant items only)
- [ ] Assign role (Engineer / Analyst / Manager)
- [ ] Share role-specific CLAUDE.md

### Day 1 — Installation
- [ ] Clone this repository
- [ ] Run `./demo.sh` — confirm 16 passed, 0 failed
- [ ] Install hooks (`cp examples/hooks/*.sh ~/.claude/hooks/`)
- [ ] Register hooks in `~/.claude/settings.json`
- [ ] Configure `worktree-guard.sh` with correct parent repo path
- [ ] Run `./tests/hooks/run-tests.sh` — confirm all passed

### Day 2 — Orientation
- [ ] Read `docs/ai-usage-policy-draft.md` (AI usage rules)
- [ ] Read `examples/incidents/INC-011-redacted.md` (why credential hooks exist)
- [ ] Read `examples/incidents/INC-013-redacted.md` (why worktree-guard exists)
- [ ] Complete first task using Claude Code — confirm hooks activate correctly

### Week 1 — Validation
- [ ] No hook violations triggered unintentionally
- [ ] Understands `worktree-guard:allow` override and when to use it
- [ ] Knows how to report a new incident (GitHub Issues template)
- [ ] Added to monthly SLO review calendar

---

## 6. Automated Onboarding

For onboarding new team members end-to-end with a single command:

```bash
# Full onboarding pipeline (GitHub invite + 1Password prompt + install link + welcome email + audit log)
bash onboard.sh \
  --user alice@example.com \
  --role engineer \
  --manager bob@example.com \
  --org your-github-org

# Preview all steps without executing
bash onboard.sh --user alice@example.com --role engineer --manager bob@example.com --dry-run
```

**What `onboard.sh` automates:**

| Step | Action | Fallback |
|------|--------|---------|
| 1 | GitHub org invitation | warn + continue (use `--skip-github` to skip) |
| 2 | 1Password vault access | Manual prompt (no public API) |
| 3 | Install link generation | Self-service URL printed for user to run |
| 4 | Role permissions apply | Skipped if Step 3 is URL-only mode |
| 5 | KB reading list | `generate-kb-list.sh --role <role>` |
| 6 | Welcome email | stdout if sendmail unavailable |
| 7 | Audit log | `~/.claude/onboard-log.jsonl` (required) |

> **Cannot be automated**: 1Password vault approval (admin must confirm), Claude Code account provisioning (Anthropic console).

---

## 7. Troubleshooting

### Hook not activating

**Symptom**: Dangerous command runs without being blocked.

```bash
# Verify hook is registered
cat ~/.claude/settings.json | grep hooks

# Verify hook file exists and is executable
ls -la ~/.claude/hooks/bash-secret-guard.sh

# Test manually
echo '{"tool_input":{"command":"cat .env"}}' | bash ~/.claude/hooks/bash-secret-guard.sh
# Should exit 2 and print BLOCKED message
```

---

### False positive — safe command blocked

**Symptom**: A legitimate command is blocked.

```bash
# Check which pattern triggered it
echo '{"tool_input":{"command":"your command here"}}' \
  | bash ~/.claude/hooks/bash-secret-guard.sh 2>&1

# If it's a known false positive, use the safe alternative:
# Instead of: cat .env
# Use:        wc -l .env  (for line count)
#             [ -f .env ] && echo exists  (for existence check)
```

---

### Worktree-guard blocking intended operation

**Symptom**: `git commit` blocked when intentionally working in parent repo.

```bash
# Add override comment to the command:
git commit -m "chore: update config"  # worktree-guard:allow
```

---

### Pre-commit scan blocking test fixtures

**Symptom**: Test file with fake credentials is blocked on commit.

Add `# allow-secret: test fixture` to the end of the flagged line:
```
FAKE_KEY=sk-ant-0000000000test  # allow-secret: test fixture
```

---

### Hook crashes with Python error

```bash
python3 --version   # must be 3.8+
which python3       # verify it's in PATH

# If using pyenv or conda, ensure the correct env is active
python3 -c "import json, re, subprocess; print('OK')"
```

---

## 8. Change Management

### Common resistance patterns and responses

| Resistance | Response |
|-----------|----------|
| "It slows me down" | Show MTTR data: blocked commands take 2s; credential leaks take 3+ days to recover |
| "I know what I'm doing" | "So did everyone who triggered INC-011. The hook takes 2ms." |
| "Too many false positives" | Review false positive log together; tune patterns collaboratively |
| "I don't need the worktree rule" | Share INC-013: one accidental main commit cost 4 hours to recover |

### Rollout strategy (recommended)

```
Week 1: Pilot with 2–3 volunteer engineers (early adopters)
Week 2: Gather feedback, tune false positive patterns
Week 3: Expand to full engineering team
Week 4: Expand to analysts and managers (read-only config)
Week 5: First monthly SLO review with full team
```

### Metrics to track adoption

- Hook installation rate: `N of M team members with hooks active`
- False positive rate: `unintended blocks / total blocks`
- MTTR trend: improving after adoption?
- Incident recurrence: zero after hook deployment?

---

---

## 日本語版

> 以下は日本語での概要です。英語版と同等の内容を含みます。

チーム10名以上へのAIハーネス展開のStep-by-Stepガイドです。

---

### 1. 前提条件

各メンバーのマシンに必要なもの: Claude Code CLI・bash・Python 3.8+・git・1Password CLI

事前確認:
```bash
git clone https://github.com/tiktax/ai-infra-portfolio
cd ai-infra-portfolio
./demo.sh   # 16 passed, 0 failed を確認
```

---

### 2. インストール（3ステップ）

**Step 1**: hookファイルをコピー
```bash
cp examples/hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

**Step 2**: `~/.claude/settings.json` にhookを登録（英語版セクション2参照）

**Step 3**: `worktree-guard.sh` の `PARENT_REPO` パスを自チームのリポジトリパスに変更

---

### 3. CLAUDE.md配布戦略

- **集中型（10〜30名推奨）**: 共有リポでCLAUDE.mdを管理 → 各メンバーがシンボリックリンクで参照
- **ロール別（30名以上推奨）**: エンジニア・アナリスト・管理職ごとに異なるCLAUDE.mdを配布

---

### 4. ロール別設定

| 権限 | エンジニア | アナリスト | 管理職 |
|------|-----------|-----------|-------|
| hookバイパス（`worktree-guard:allow`）| ✅ | ❌ | ❌ |
| フィーチャーブランチへのコミット | ✅ | ✅ | ❌ |
| hook設定の変更 | ✅（レビュー必須）| ❌ | ❌ |
| インシデント記録へのアクセス | ✅ | 読取のみ | ✅ |

---

### 5. オンボーディングチェックリスト

**Day 1**: リポクローン → `./demo.sh` 確認 → hook インストール → テスト実行

**Day 2**: ポリシー文書を読む → インシデント例（INC-011・013）を読む → 初回Claude Code利用

**Week 1**: hook誤検知がないことを確認 → バイパスの使い方を理解 → 月次SLOレビューに参加

---

### 6. 自動オンボーディング

`onboard.sh` で新メンバーのエンドツーエンドオンボーディングを1コマンドで実行。
GitHub招待 → 1Passwordプロンプト → インストールリンク生成 → ウェルカムメール → 監査ログ記録。

---

### 7. トラブルシューティング（5件）

1. **hookが起動しない** → `settings.json` の登録確認 → ファイルの実行権限確認
2. **安全なコマンドがブロックされる** → 安全な代替コマンドを使用（`wc -l` 等）
3. **worktree-guardが意図した操作をブロック** → `# worktree-guard:allow` を末尾に追加
4. **テストファイルがcommit前スキャンでブロック** → `# allow-secret: test fixture` を追加
5. **PythonエラーでhookがCrash** → `python3 --version` で3.8+を確認

---

### 8. 変更管理

**よくある抵抗と対応**:
- 「遅くなる」 → MTTRデータで示す（ブロック2秒 vs 漏洩回復3日以上）
- 「自分は分かってる」 → 「INC-011を起こした全員も同じことを言っていた」
- 「誤検知が多い」 → 誤検知ログを一緒に見てパターンを調整

**展開スケジュール**:
1週目: パイロット（2〜3名）→ 2週目: フィードバック収集 → 3週目: エンジニア全体 → 4週目: アナリスト・管理職 → 5週目: 初回SLOレビュー
