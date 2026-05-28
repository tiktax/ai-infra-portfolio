"""
governance-mcp — AI Harness Governance Status MCP Server

Exposes the state of this AI harness as MCP tools, allowing Claude Code
to query its own governance configuration at runtime.

Tools:
  get_governance_status   Complete overview of all governance components
  list_hooks              Installed security hooks with descriptions
  get_role_config         Current CLAUDE.md role, version, install date
  get_incident_summary    Incident counts by severity and status
  get_slo_metrics         Cost, MTTR, and improvement cycle metrics

Usage:
  pip install fastmcp
  python server.py

Then register in Claude Code settings.json:
  {
    "mcpServers": {
      "governance": {
        "command": "python",
        "args": ["/path/to/tools/governance-mcp/server.py"]
      }
    }
  }
"""

import json
import os
import re
from pathlib import Path
from datetime import datetime, timezone

try:
    from fastmcp import FastMCP
except ImportError:
    raise SystemExit(
        "fastmcp is not installed. Run: pip install fastmcp"
    )

# ── Paths ─────────────────────────────────────────────────────────────────────

REPO_ROOT = Path(__file__).parent.parent.parent
HOOKS_DIR = REPO_ROOT / "examples" / "hooks"
INCIDENTS_DIR = REPO_ROOT / "examples" / "incidents"
CONFIGS_DIR = REPO_ROOT / "tools" / "claude-config-manager" / "configs"
MCP_REGISTER = REPO_ROOT / "tools" / "governance-mcp" / "mcp-accountability-register.md"
CLAUDE_DIR = Path.home() / ".claude"
META_FILE = CLAUDE_DIR / ".config-meta.json"

# ── MCP Server ────────────────────────────────────────────────────────────────

mcp = FastMCP(
    name="governance-status",
    instructions=(
        "Query the AI harness governance state. "
        "Use these tools to inspect installed hooks, role configuration, "
        "incident history, and SLO metrics."
    ),
)

# ── Helpers ───────────────────────────────────────────────────────────────────

def _read_meta() -> dict:
    """Read ~/.claude/.config-meta.json safely."""
    if not META_FILE.exists():
        return {}
    try:
        return json.loads(META_FILE.read_text())
    except Exception:
        return {}


def _extract_hook_description(hook_path: Path) -> str:
    """Extract the Purpose line from a hook file header."""
    try:
        for line in hook_path.read_text().splitlines()[:20]:
            if line.startswith("# Purpose:"):
                return line[len("# Purpose:"):].strip()
        return "Security hook"
    except Exception:
        return "Unknown"


def _parse_incident_severity(incident_path: Path) -> str:
    """Extract P0/P1/P2/P3 severity from an incident file."""
    try:
        for line in incident_path.read_text().splitlines()[:10]:
            match = re.search(r'\b(P[0-3])\b', line)
            if match:
                return match.group(1)
    except Exception:
        pass
    return "Unknown"


def _parse_incident_status(incident_path: Path) -> str:
    """Extract Resolved/Open status from an incident file."""
    try:
        for line in incident_path.read_text().splitlines()[:10]:
            if "Permanently resolved" in line or "✅" in line:
                return "resolved"
            if "🔴 Open" in line:
                return "open"
    except Exception:
        pass
    return "unknown"


# ── Tools ─────────────────────────────────────────────────────────────────────

@mcp.tool()
def get_governance_status() -> dict:
    """
    Get a complete overview of the AI harness governance state.

    Returns a summary of all governance components:
    hooks installed, current role config, incident counts, and SLO health.
    Use this as the first call to understand the overall governance posture.
    """
    meta = _read_meta()
    current = meta.get("current", {})

    # Hooks
    hooks = list(HOOKS_DIR.glob("*.sh")) if HOOKS_DIR.exists() else []

    # Incidents
    incidents = [
        p for p in INCIDENTS_DIR.glob("*.md")
        if p.name != "TEMPLATE.md"
    ] if INCIDENTS_DIR.exists() else []

    resolved = sum(
        1 for p in incidents if _parse_incident_status(p) == "resolved"
    )

    return {
        "governance_posture": "active",
        "as_of": datetime.now(timezone.utc).isoformat(),
        "hooks": {
            "count": len(hooks),
            "names": [h.stem for h in sorted(hooks)],
        },
        "role_config": {
            "role": current.get("role", "not installed"),
            "version": current.get("version", "—"),
            "installed_at": current.get("installed_at", "—"),
            "installed_by": current.get("installed_by", "—"),
        },
        "incidents": {
            "total": len(incidents),
            "resolved": resolved,
            "open": len(incidents) - resolved,
        },
        "compliance": {
            "iso_20000": "lightweight alignment",
            "iso_27001": "lightweight alignment",
            "audit_trail": "github_issues + git_log + obsidian",
        },
    }


@mcp.tool()
def list_hooks() -> dict:
    """
    List all security hooks with their trigger type and purpose.

    Each hook runs automatically as a PreToolUse or PostToolUse event
    in Claude Code, blocking or auditing operations before/after execution.
    """
    if not HOOKS_DIR.exists():
        return {"error": f"Hooks directory not found: {HOOKS_DIR}"}

    hooks = []
    for hook_path in sorted(HOOKS_DIR.glob("*.sh")):
        trigger = "PreToolUse"
        content = ""
        try:
            content = hook_path.read_text()
        except Exception:
            pass

        if "PostToolUse" in content:
            trigger = "PostToolUse"
        elif "SessionStart" in content:
            trigger = "SessionStart"

        hooks.append({
            "name": hook_path.stem,
            "trigger": trigger,
            "purpose": _extract_hook_description(hook_path),
            "file": str(hook_path.relative_to(REPO_ROOT)),
        })

    return {
        "total": len(hooks),
        "hooks": hooks,
        "coverage": {
            "credential_leak_prevention": any(
                "secret" in h["name"] or "commit" in h["name"]
                for h in hooks
            ),
            "git_safety": any("worktree" in h["name"] for h in hooks),
            "supply_chain": any("npm" in h["name"] for h in hooks),
            "config_integrity": any("mcp" in h["name"] for h in hooks),
        },
    }


@mcp.tool()
def get_role_config() -> dict:
    """
    Get the currently installed CLAUDE.md role configuration.

    Returns the active role (engineer/analyst/manager), version,
    installation metadata, and full installation history.
    Use this to verify that the correct role config is active.
    """
    meta = _read_meta()

    if not meta:
        return {
            "status": "not_installed",
            "message": (
                "No role config found. Run: "
                "./tools/claude-config-manager/manage.sh install --role engineer"
            ),
        }

    current = meta.get("current", {})
    history = meta.get("history", [])

    # Check if CLAUDE.md has been modified since installation
    import hashlib

    claude_md = CLAUDE_DIR / "CLAUDE.md"
    hash_match = None
    if claude_md.exists() and current.get("hash"):
        actual = hashlib.md5(claude_md.read_bytes()).hexdigest()
        hash_match = (actual == current.get("hash"))

    return {
        "current": {
            "role": current.get("role", "unknown"),
            "version": current.get("version", "unknown"),
            "installed_at": current.get("installed_at", "unknown"),
            "installed_by": current.get("installed_by", "unknown"),
            "integrity": (
                "verified" if hash_match is True
                else "modified" if hash_match is False
                else "unchecked"
            ),
        },
        "available_roles": ["engineer", "analyst", "manager"],
        "install_count": len(history),
        "history_preview": [
            {
                "role": h.get("role"),
                "version": h.get("version"),
                "installed_at": h.get("installed_at", "")[:19],
            }
            for h in history[-5:]  # last 5 installs
        ],
    }


@mcp.tool()
def get_incident_summary() -> dict:
    """
    Get a summary of all recorded incidents with severity breakdown.

    Incidents follow the INC → Problem → CIP → Change cycle (ISO/IEC 20000).
    Each incident includes severity (P0-P3), status, and resolution tracking.
    """
    if not INCIDENTS_DIR.exists():
        return {"error": f"Incidents directory not found: {INCIDENTS_DIR}"}

    incidents = [
        p for p in sorted(INCIDENTS_DIR.glob("*.md"))
        if p.name != "TEMPLATE.md"
    ]

    if not incidents:
        return {"total": 0, "incidents": []}

    severity_counts = {"P0": 0, "P1": 0, "P2": 0, "P3": 0, "Unknown": 0}
    status_counts = {"resolved": 0, "open": 0, "unknown": 0}
    incident_list = []

    for p in incidents:
        severity = _parse_incident_severity(p)
        status = _parse_incident_status(p)
        severity_counts[severity] = severity_counts.get(severity, 0) + 1
        status_counts[status] = status_counts.get(status, 0) + 1

        # Extract title from filename
        title = p.stem.replace("-redacted", "").replace("-", " ").title()

        incident_list.append({
            "file": p.name,
            "title": title,
            "severity": severity,
            "status": status,
        })

    return {
        "total": len(incidents),
        "by_severity": severity_counts,
        "by_status": status_counts,
        "resolution_rate": (
            f"{status_counts['resolved'] / len(incidents) * 100:.0f}%"
            if incidents else "N/A"
        ),
        "incidents": incident_list,
        "itsm_cycle": "INC → Problem → CIP → Change (ISO/IEC 20000)",
    }


@mcp.tool()
def get_slo_metrics() -> dict:
    """
    Get the current SLO (Service Level Objective) metrics for the AI harness.

    Returns cost optimization measurements, incident response times (MTTR),
    CIP completion rates, and overall SLO health status.
    These are the core KPIs from docs/achievements.md.
    """
    # Static metrics from achievements.md (update manually each month)
    return {
        "as_of": "2026-05",
        "slo_status": "green",
        "cost_optimization": {
            "cli_call_cost_reduction_pct": 99.5,
            "before_usd_per_call": 0.21,
            "after_usd_per_call": 0.001,
            "session_start_context_reduction_pct": 99.8,
            "before_mb": 19.0,
            "after_kb": 36,
            "annual_token_reduction_pct": 99.96,
        },
        "incident_management": {
            "total_incidents": 13,
            "permanently_resolved": 6,
            "resolution_rate_pct": 46,
            "mttr_days": {
                "march_2026": 7.0,
                "april_2026": 4.0,
                "may_2026": 2.0,
                "trend": "improving",
            },
        },
        "security": {
            "hooks_active": 9,
            "credential_patterns_detected": 14,
            "recurrence_after_fix": 0,
            "log_size_reduction_pct": 93,
        },
        "improvement_cycle": {
            "cips_proposed": 6,
            "cips_completed": 6,
            "completion_rate_pct": 100,
            "current_open_cips": 0,
        },
        "compliance": {
            "iso_20000": "lightweight",
            "iso_27001": "lightweight",
            "monthly_audit": True,
            "traceability": "github_issues + obsidian",
        },
    }


@mcp.tool()
def get_mcp_accountability() -> dict:
    """
    Get the MCP accountability register — registered servers and their decision boundaries.

    Returns a list of registered MCP servers with their declared scopes,
    escalation paths, and known limitations. Use this to verify that any
    MCP server in use has a defined accountability boundary before invoking it.
    """
    if not MCP_REGISTER.exists():
        return {
            "error": f"MCP accountability register not found: {MCP_REGISTER}",
            "hint": "Expected at tools/governance-mcp/mcp-accountability-register.md",
        }

    content = MCP_REGISTER.read_text()

    # Parse registered servers from the table
    servers = []
    in_table = False
    for line in content.splitlines():
        if line.startswith("| `") or (in_table and line.startswith("| (")):
            in_table = True
            parts = [p.strip() for p in line.split("|")[1:-1]]
            if len(parts) >= 6 and parts[0] not in ("Server ID", "---"):
                server_id = parts[0].strip("`").strip()
                servers.append({
                    "server_id": server_id,
                    "tools": [t.strip() for t in parts[1].split(",")],
                    "owner": parts[2],
                    "decision_scope": parts[3],
                    "escalation_path": parts[4],
                    "registered": parts[5],
                })
        elif in_table and not line.startswith("|"):
            in_table = False

    return {
        "as_of": datetime.now(timezone.utc).isoformat(),
        "register_path": str(MCP_REGISTER.relative_to(REPO_ROOT)),
        "registered_servers": len(servers),
        "servers": servers,
        "audit_fields_required": [
            "mcp_server",
            "tool_name",
            "instructed_by",
            "decision_boundary",
        ],
        "flagging_rule": (
            "audit_report() flags entries where mcp_server is present "
            "but decision_boundary is empty"
        ),
    }


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    mcp.run()
