# Governance Status MCP Server

An MCP (Model Context Protocol) server that exposes the AI harness governance
state as queryable tools — allowing Claude Code to inspect its own configuration
at runtime.

---

## Installation

```bash
pip install fastmcp
python tools/governance-mcp/server.py
```

## Register with Claude Code

Add to `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "governance": {
      "command": "python",
      "args": ["/path/to/ai-infra-portfolio/tools/governance-mcp/server.py"]
    }
  }
}
```

---

## Tools

### `get_governance_status`
Complete overview of all governance components.

```
→ hooks.count, role_config, incidents summary, compliance alignment
```

**Example use**: "What is the current governance posture of this AI harness?"

---

### `list_hooks`
All security hooks with trigger type and purpose.

```
→ [{name, trigger, purpose, file}, ...]
→ coverage: {credential_leak, git_safety, supply_chain, config_integrity}
```

**Example use**: "Which hooks are protecting against credential leaks?"

---

### `get_role_config`
Currently installed CLAUDE.md role configuration.

```
→ {role, version, installed_at, installed_by, integrity}
→ history: last 5 installs
```

**Example use**: "Am I running as engineer or analyst? Has my CLAUDE.md been modified?"

---

### `get_incident_summary`
All recorded incidents with severity and status breakdown.

```
→ total, by_severity {P0, P1, P2, P3}, by_status {resolved, open}
→ resolution_rate, itsm_cycle
```

**Example use**: "How many P1 incidents have been resolved this month?"

---

### `get_slo_metrics`
Current SLO metrics: cost, MTTR, CIP completion, security coverage.

```
→ cost_optimization, incident_management, security, improvement_cycle
→ slo_status: green / yellow / red
```

**Example use**: "What is the current MTTR trend? Is SLO green?"

---

## Design Notes

### Why this MCP?

Most teams add MCP servers to integrate *external* tools (Slack, Jira, GitHub).
This server does the opposite: it makes the *AI harness itself* queryable.

This enables:
- **Self-awareness**: Claude Code can inspect its own constraints before acting
- **Audit queries**: "How many incidents have we had?" without reading raw files
- **Governance reporting**: Generate status reports from within Claude Code

### AX (Agent Experience) design

Each tool is designed for agent consumption:
- Structured JSON returns (no prose parsing required)
- Graceful degradation when files are missing
- Clear field names that map to the governance concepts in this repo

### Extending this server

To add a new tool:

```python
@mcp.tool()
def my_new_tool(param: str) -> dict:
    """
    One-line description for Claude.

    Longer explanation of when to use this tool.
    """
    return {"result": "..."}
```

---

## 日本語版

**概要**: AIハーネスのガバナンス状態をMCPツールとして公開するサーバー。Claude Codeが自分の設定・インシデント・メトリクスをリアルタイムで照会できる。

**ツール一覧**:
- `get_governance_status` — 全コンポーネントの概要
- `list_hooks` — インストール済みhookと説明
- `get_role_config` — 現在のロール・バージョン・整合性確認
- `get_incident_summary` — 深刻度別インシデント件数
- `get_slo_metrics` — コスト・MTTR・CIP完了率

**設計思想**: 外部ツールではなく「AI基盤自身」を照会対象とするMCP。Agent Experience（AX）の観点から、エージェントが自分のガバナンス状態を自問できる設計。
