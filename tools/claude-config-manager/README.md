# Claude Config Manager

A CLI tool for distributing and versioning role-specific `CLAUDE.md` configurations across a team.

Each team member gets a `CLAUDE.md` tailored to their role — combining a shared security baseline with role-specific permissions and constraints.

---

## Quick Start

```bash
# Install for an engineer
./tools/claude-config-manager/manage.sh install --role engineer

# Verify installation
./tools/claude-config-manager/manage.sh verify

# Show current config
./tools/claude-config-manager/manage.sh list
```

---

## Commands

| Command | Description |
|---------|-------------|
| `install --role <role>` | Install role-specific CLAUDE.md to `~/.claude/CLAUDE.md` |
| `list` | Show current role, version, and install date |
| `verify` | Check CLAUDE.md has not been modified since installation |
| `audit` | Show full installation history |
| `roles` | List available roles and their versions |

### Install options

```bash
./manage.sh install --role engineer          # standard install
./manage.sh install --role analyst --dry-run # preview without writing
./manage.sh install --role manager --force   # reinstall even if current
```

---

## Roles

### `engineer` — Full development permissions

- Feature branch commits ✅
- Hook override (`worktree-guard:allow`) with justification ✅
- Test fixture secrets (`allow-secret:`) with reason ✅
- Direct main branch commits ❌

### `analyst` — Read-only + reporting

- Read all code, logs, configs ✅
- Create reports in `/reports/` ✅
- Any git write operation ❌
- Security hook bypass ❌

### `manager` — Review and approval only

- Read all code and configs ✅
- Approve incident responses ✅
- Any code or config modification ❌
- Off-the-record approvals ❌

---

## How It Works

`install` combines two files and writes to `~/.claude/CLAUDE.md`:

```
configs/base.md          (shared security baseline, all roles)
    +
configs/<role>.md        (role-specific permissions)
    ↓
~/.claude/CLAUDE.md      (installed, hash-verified)
```

An audit record is saved to `~/.claude/.config-meta.json`:

```json
{
  "current": {
    "role": "engineer",
    "version": "1.0.0+1.0.0",
    "installed_at": "2026-05-20T10:00:00Z",
    "installed_by": "Take"
  },
  "history": [...]
}
```

---

## Team Deployment

To deploy to a team of 10+, see:
[`docs/deployment-playbook.md`](../../docs/deployment-playbook.md)

### Recommended workflow

```bash
# 1. Admin: clone this repo on each machine (or use shared network path)
# 2. Each member: run install with their role
./manage.sh install --role engineer   # developers
./manage.sh install --role analyst    # data/security analysts
./manage.sh install --role manager    # team leads

# 3. Verify across team (run on each machine)
./manage.sh verify

# 4. Update after policy changes: bump version in configs/*.md, reinstall
./manage.sh install --role engineer --force
```

### Versioning

Each config file has a `# Version: x.y.z` header.
Bump the version when making changes — `manage.sh verify` will detect drift.

---

## Adding a New Role

1. Copy `configs/engineer.md` → `configs/<new-role>.md`
2. Update permissions and constraints
3. Add the role name to `VALID_ROLES` in `manage.sh`
4. Test: `./manage.sh install --role <new-role> --dry-run`

---

## 日本語版

**概要**: チームメンバーにロール別の `CLAUDE.md` を配布・バージョン管理するCLIツール。

**使い方**:
```bash
./manage.sh install --role engineer   # エンジニア向けにインストール
./manage.sh verify                    # インストール済みと一致するか確認
./manage.sh audit                     # インストール履歴を表示
```

**ロール**:
- `engineer`: フィーチャーブランチのコミット可・hookオーバーライド条件付き許可
- `analyst`: 読取専用・`/reports/` への書込のみ許可
- `manager`: レビュー・承認のみ・コード変更禁止

**仕組み**: `base.md`（共通ベースライン）+ `<role>.md`（ロール固有ルール）を結合して `~/.claude/CLAUDE.md` に書き込む。インストール履歴は `~/.claude/.config-meta.json` に記録。
