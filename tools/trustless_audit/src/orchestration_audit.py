"""
orchestration_audit.py — Multi-agent orchestration audit chain

Provides functions to create, link, and verify signed audit entries
across an orchestrator-subagent hierarchy.

Each entry in the chain:
1. Is ECDSA-signed via signing.py
2. Carries entry_hash = sha256(all signed fields)  <- linking target
3. Result entries carry parent_hash = entry_hash of the delegation <- link

Verification is hash-based (not signature-based) — for ECDSA verification
of individual entries, use audit.py audit_report() with log_path pointing
to the agent log file.
"""

import hashlib
import json
from datetime import datetime, timezone
from typing import Optional

from .signing import sign_operation_log


def entry_hash(entry: dict) -> str:
    """
    Compute SHA-256 of a signed entry's canonical JSON (all fields, sorted keys).

    Uses ALL fields including signature — so any modification to signature
    or payload fields both invalidate this hash.

    Args:
        entry: A signed log entry dict (output of sign_operation_log or similar)

    Returns:
        Hex SHA-256 string (64 chars)
    """
    canonical = json.dumps(entry, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canonical.encode()).hexdigest()


def create_delegation_entry(
    orchestrator_id: str,
    sub_agent_id: str,
    task_scope: str,
    delegation_reason: str,
    private_key_pem: bytes,
) -> dict:
    """
    Create a signed log entry recording that orchestrator delegated a task to sub_agent.

    The returned entry includes 'entry_hash' (SHA-256 of the full signed entry),
    which sub-agents must reference as 'parent_hash' in their result entries.

    Returns:
        Signed dict with fields:
          timestamp, operator_id (=orchestrator_id), operator_type="AI",
          action="delegate", sub_agent_id, task_scope, delegation_reason,
          signature, key_fingerprint, entry_hash
    """
    base = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "operator_id": orchestrator_id,
        "operator_type": "AI",
        "action": "delegate",
        "sub_agent_id": sub_agent_id,
        "task_scope": task_scope,
        "delegation_reason": delegation_reason,
    }
    signed = sign_operation_log(base, private_key_pem)
    signed["entry_hash"] = entry_hash(signed)
    return signed


def create_agent_result_entry(
    agent_id: str,
    task_scope: str,
    result_summary: str,
    parent_entry_hash: str,
    private_key_pem: bytes,
    artifact: Optional[dict] = None,
    artifact_type: str = "result",
) -> dict:
    """
    Create a signed log entry recording a sub-agent's result.

    The parent_hash field links this entry to the delegation entry from the
    orchestrator, forming a verifiable parent-child chain.

    Args:
        parent_entry_hash: entry_hash of the corresponding delegation entry
        artifact: Optional dict of output data (will be sha256-hashed)
        artifact_type: "result" | "decision" | "error"

    Returns:
        Signed dict with fields:
          timestamp, operator_id (=agent_id), operator_type="AI",
          action="agent_result", task_scope, result_summary, parent_hash,
          artifact_type, artifact_hash (if artifact provided),
          signature, key_fingerprint, entry_hash
    """
    base: dict = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "operator_id": agent_id,
        "operator_type": "AI",
        "action": "agent_result",
        "task_scope": task_scope,
        "result_summary": result_summary,
        "parent_hash": parent_entry_hash,
        "artifact_type": artifact_type,
    }
    if artifact is not None:
        artifact_canonical = json.dumps(artifact, sort_keys=True, separators=(",", ":"))
        base["artifact_hash"] = hashlib.sha256(artifact_canonical.encode()).hexdigest()

    signed = sign_operation_log(base, private_key_pem)
    signed["entry_hash"] = entry_hash(signed)
    return signed


def verify_orchestration_chain(entries: list) -> dict:
    """
    Verify the hash chain integrity across a list of agent log entries.

    Checks:
    1. agent_result entries must have a parent_hash that matches an entry_hash
       in the entries list -> broken_links if not found
    2. agent_result entries without parent_hash field -> orphaned_entries

    Does NOT verify ECDSA signatures (that is audit_report()'s responsibility).

    Args:
        entries: List of signed log entries (mix of delegation + result entries)

    Returns:
        {
            "valid": bool,            # True iff broken_links and orphaned_entries are both empty
            "agent_count": int,       # distinct operator_ids
            "delegation_count": int,  # entries with action=="delegate"
            "result_count": int,      # entries with action=="agent_result"
            "broken_links": list[str],    # agent_id values of result entries whose
                                          # parent_hash doesn't match any entry_hash
            "orphaned_entries": list[str] # agent_id values of result entries with
                                          # no parent_hash field at all
        }
    """
    known_hashes = {e["entry_hash"] for e in entries if "entry_hash" in e}

    agent_ids = {e.get("operator_id") for e in entries if "operator_id" in e}
    delegation_count = sum(1 for e in entries if e.get("action") == "delegate")
    result_count = sum(1 for e in entries if e.get("action") == "agent_result")

    broken_links: list = []
    orphaned_entries: list = []

    for e in entries:
        if e.get("action") != "agent_result":
            continue
        agent_id = e.get("operator_id", "")
        if "parent_hash" not in e:
            orphaned_entries.append(agent_id)
        elif e["parent_hash"] not in known_hashes:
            broken_links.append(agent_id)

    valid = len(broken_links) == 0 and len(orphaned_entries) == 0

    return {
        "valid": valid,
        "agent_count": len(agent_ids),
        "delegation_count": delegation_count,
        "result_count": result_count,
        "broken_links": broken_links,
        "orphaned_entries": orphaned_entries,
    }


def build_audit_tree(entries: list) -> dict:
    """
    Build a tree structure from a flat list of agent log entries.

    Returns:
        {
            "orchestrators": list[str],   # operator_ids with action=="delegate"
            "sub_agents": list[str],      # operator_ids with action=="agent_result"
            "delegations": [              # one entry per delegation
                {
                    "orchestrator_id": str,
                    "sub_agent_id": str,
                    "task_scope": str,
                    "entry_hash": str,
                    "results": [          # matching agent_result entries
                        {"agent_id": str, "result_summary": str, "entry_hash": str}
                    ]
                }
            ],
            "unlinked_results": list[str]  # entry_hashes of results with no matching delegation
        }
    """
    delegation_entries = [e for e in entries if e.get("action") == "delegate"]
    result_entries = [e for e in entries if e.get("action") == "agent_result"]

    orchestrators = list({e.get("operator_id", "") for e in delegation_entries})
    sub_agents = list({e.get("operator_id", "") for e in result_entries})

    # Map delegation entry_hash -> delegation node
    delegation_map: dict = {}
    delegations = []
    for d in delegation_entries:
        d_hash = d.get("entry_hash", "")
        node = {
            "orchestrator_id": d.get("operator_id", ""),
            "sub_agent_id": d.get("sub_agent_id", ""),
            "task_scope": d.get("task_scope", ""),
            "entry_hash": d_hash,
            "results": [],
        }
        delegation_map[d_hash] = node
        delegations.append(node)

    unlinked_results: list = []
    for r in result_entries:
        parent_hash = r.get("parent_hash", "")
        r_hash = r.get("entry_hash", "")
        if parent_hash in delegation_map:
            delegation_map[parent_hash]["results"].append({
                "agent_id": r.get("operator_id", ""),
                "result_summary": r.get("result_summary", ""),
                "entry_hash": r_hash,
            })
        else:
            unlinked_results.append(r_hash)

    return {
        "orchestrators": orchestrators,
        "sub_agents": sub_agents,
        "delegations": delegations,
        "unlinked_results": unlinked_results,
    }
