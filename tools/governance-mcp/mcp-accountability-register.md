# MCP Accountability Register

This register documents the MCP (Model Context Protocol) servers connected to the AI harness,
their declared decision boundaries, and the escalation paths when those boundaries are exceeded.

**Purpose**: When an AI agent uses an MCP tool, it must be traceable who authorized that use,
what scope the MCP server was permitted to act within, and how accountability is assigned
if the outcome is disputed.

---

## Registered MCP Servers

| Server ID | Tool(s) | Owner | Decision Scope | Escalation Path | Registered |
|-----------|---------|-------|----------------|-----------------|------------|
| `governance-mcp` | `get_governance_status`, `list_hooks`, `get_role_config`, `get_incident_summary`, `get_slo_metrics`, `get_mcp_accountability` | Repository maintainer | **Read-only** — query governance state only; no writes, no configuration changes | N/A (read-only; no escalation path needed) | 2026-05-27 |
| `(template)` | `route_inference` | Platform team | Cost routing decisions for light/heavy model selection | Human approval required for default model changes | — |

---

## Field Definitions

| Field | Description |
|-------|-------------|
| `Server ID` | Unique identifier matching the `mcp_server` field in audit log entries |
| `Tool(s)` | Comma-separated list of tool names exposed by this server |
| `Owner` | Individual or team accountable for the server's behavior |
| `Decision Scope` | Explicit description of what this server **can** decide autonomously |
| `Escalation Path` | How decisions **outside** the declared scope must be handled |
| `Registered` | ISO date when this server was formally registered |

---

## Accountability Boundary Definition

An MCP server's **decision boundary** is the set of actions it may take without human approval.
Any action outside this boundary requires escalation before execution.

### Example boundaries

```
governance-mcp:
  CAN:   Read governance state, list hooks, report incidents
  CANNOT: Write to any file, modify configurations, approve changes

model-router-mcp (hypothetical):
  CAN:   Route to local (Gemma4) vs cloud (Claude) based on task complexity
  CANNOT: Change the default model, modify routing thresholds, access private endpoints
```

### Audit log fields for MCP entries

When an AI agent calls an MCP tool, the audit log entry **should** include:

```json
{
  "timestamp": "2026-05-27T09:00:00Z",
  "operator_id": "claude_agent_session_abc123",
  "operator_type": "AI",
  "action": "tool_call",
  "mcp_server": "governance-mcp",
  "tool_name": "get_governance_status",
  "instructed_by": "orchestrator_agent_001",
  "decision_boundary": "read-only governance state query — no side effects",
  "signature": "...",
  "key_fingerprint": "..."
}
```

If `decision_boundary` is empty or absent, `audit_report()` will flag the entry as
**"MCP decision boundary not defined"** — this indicates the MCP call was not properly
registered before use.

---

## Escalation Procedures

### Level 1 — Automated flag
`audit_report()` flags entries with empty `decision_boundary`. No human action required
unless the rate exceeds 10% of MCP calls in a reporting period.

### Level 2 — Human review
If an MCP server takes an action outside its declared scope:
1. Log an INC in `examples/incidents/` with tag `incident/mcp-boundary-exceeded`
2. Suspend the MCP server from the harness until RCA is complete
3. Update this register with revised boundaries

### Level 3 — Governance change
If boundary violations are structural (pattern across multiple incidents):
1. Raise a Problem → CIP → Change via `tools/itil5-ai-governance/phase-gate.sh`
2. Require sign-off from a human approver at the jurisdiction-appropriate level

---

## Known Limitations

| Limitation | Current State |
|-----------|--------------|
| Real-time boundary enforcement | Not implemented — boundaries are declared, not technically enforced |
| Inter-server trust chains | Not defined — if MCP-A calls MCP-B, the accountability chain is not captured |
| Key management for MCP agents | Each MCP server does not yet have its own signing key pair |

---

## 日本語版

### MCP 責任台帳

MCP サーバーの責任分界点を定義する台帳です。AI エージェントが MCP ツールを呼び出す際、
そのツール呼び出しが audit log に `mcp_server` + `decision_boundary` フィールドで記録される
ことを保証します。

**`decision_boundary` が空の場合の挙動**: `audit.py` の `audit_report()` が
"MCP decision boundary not defined" として `flagged_entries` に追記します。

### 責任分界点の考え方

```
AI エージェントがツールを呼ぶ
  → MCP サーバーがツールを実行する
  → 誰がその実行を承認したか？
  → そのツールは宣言済みスコープ内か？
  → スコープ外なら人間の承認フローへ
```

現時点では技術的な強制（ランタイム境界チェック）は実装していません。
これは既知の制限（Known Limitation）として記録されています。
