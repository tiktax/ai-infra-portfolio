# OWASP Agentic AI Top 10 — Project Mapping

The OWASP Agentic AI Top 10 (2025) defines the ten highest-risk vulnerability classes for AI agent systems, covering goal manipulation, tool abuse, identity exploitation, and rogue behavior. This document maps each item (ASI01–ASI10) to artifacts in this AI governance harness. The project's primary goal is tamper-evident audit proof of what the AI *did* — not runtime agent orchestration — so coverage depth varies by item. Where an item falls outside the project's design scope, the rationale is stated explicitly.

---

## ASI01 — Goal Hijacking

**Status:** ✅ Covered

**Risk:** An attacker injects malicious instructions into the AI's context to override its intended goal.

**Coverage:** Prompt injection detection at the PreToolUse hook boundary.

**Artifact:** [`examples/hooks/prompt-injection-guard.sh`](../../examples/hooks/prompt-injection-guard.sh)

**Notes:** Detects 14 known prompt injection patterns before tool execution. Bypass requires explicit inline annotation (`# injection-guard:allow`), which is itself logged in the audit chain.

---

## ASI02 — Tool Misuse

**Status:** ✅ Covered

**Risk:** The AI invokes tools outside their intended scope, exfiltrates data, or manipulates the environment through legitimate tool APIs.

**Coverage:** Two complementary PreToolUse hooks block the two primary misuse vectors.

**Artifacts:**
- [`examples/hooks/bash-secret-guard.sh`](../../examples/hooks/bash-secret-guard.sh) — blocks credential-leaking shell patterns
- [`examples/hooks/mcp-config-guard.sh`](../../examples/hooks/mcp-config-guard.sh) — blocks unauthorized MCP configuration changes

**Notes:** Guards operate at the hook layer, which Claude Code invokes synchronously before tool execution proceeds.

---

## ASI03 — Identity and Privilege Abuse

**Status:** ⚠️ Partial

**Risk:** The AI assumes elevated privileges, impersonates users or systems, or exploits trust relationships to perform unauthorized actions.

**Coverage:** Signing metadata distinguishes AI-originated from human-originated actions via key fingerprint.

**Artifact:** [`tools/trustless_audit/src/signing.py`](../../tools/trustless_audit/src/signing.py)

**Notes:** The `key_fingerprint` field in every signed audit event proves whether the action was AI- or HUMAN-initiated. A full IAM-style identity registry with role-based privilege boundaries is not implemented. This is a partial control: it proves identity after the fact but does not enforce privilege separation at execution time.

---

## ASI04 — Supply Chain Compromise

**Status:** ✅ Covered

**Risk:** Malicious dependencies, model weights, or tooling are introduced into the AI system through the software supply chain.

**Coverage:** Pre-commit secrets scanning and automated SBOM generation with vulnerability auditing.

**Artifacts:**
- [`examples/hooks/pre-commit-secrets.sh`](../../examples/hooks/pre-commit-secrets.sh) — blocks credential commits at the git hook layer
- [`.github/workflows/sbom-scan.yml`](../../.github/workflows/sbom-scan.yml) — generates CycloneDX SBOM and runs pip-audit on every push

**Notes:** CycloneDX SBOM provides a machine-readable inventory of all Python dependencies. pip-audit cross-references against the OSV vulnerability database.

---

## ASI05 — Excessive Code Execution

**Status:** ✅ Covered

**Risk:** The AI executes unintended or malicious code, including credential theft via shell commands.

**Coverage:** Bash execution guard blocks the primary class of credential-leaking shell patterns before execution.

**Artifact:** [`examples/hooks/bash-secret-guard.sh`](../../examples/hooks/bash-secret-guard.sh)

**Notes:** The guard operates at PreToolUse, blocking patterns such as `cat .env`, `grep ... .env`, `echo $*_TOKEN`, and `printenv` before the Bash tool executes. This is the same artifact as ASI02 but addresses the code execution risk specifically.

---

## ASI06 — Memory Poisoning

**Status:** ✅ Covered

**Risk:** An attacker corrupts the AI's persistent memory (e.g., CLAUDE.md files) to alter future behavior without leaving a detectable trace.

**Coverage:** Two-layer defense: dangerous-keyword blocking at write time, plus cryptographic signing of every accepted write into the audit chain.

**Artifact:** [`examples/hooks/claude-md-integrity.sh`](../../examples/hooks/claude-md-integrity.sh)

**Notes:** PreToolUse hook blocks writes containing dangerous instruction patterns. PostToolUse hook ECDSA-signs every accepted CLAUDE.md modification and appends the event to the tamper-evident audit log. An attacker who bypasses the keyword filter still produces a signed, timestamped record.

---

## ASI07 — Insecure Inter-Agent Communication

**Status:** ⚠️ Partial

**Risk:** Messages between agents are tampered with, spoofed, or replayed, causing the receiving agent to act on malicious instructions.

**Coverage:** Hash-linked delegation chain records the sequence of agent-to-agent task handoffs.

**Artifact:** [`tools/trustless_audit/src/orchestration_audit.py`](../../tools/trustless_audit/src/orchestration_audit.py)

**Notes:** Each delegation event is hashed and chained to the prior event, making retrospective insertion detectable. Active agent-to-agent protocol verification (e.g., mutual TLS, message signing at the transport layer) is not implemented. This is a forensic control, not a preventive one.

---

## ASI08 — Cascading Failures

**Status:** ✅ Covered

**Risk:** A failure in one agent or component propagates through the system, causing uncontrolled degradation or runaway actions.

**Coverage:** Manual kill switch with circuit breaker pattern and signed audit events for every state transition.

**Artifact:** [`tools/kill-switch/kill-switch.sh`](../../tools/kill-switch/kill-switch.sh)

**Notes:** Supports `stop` and `trip` commands. Every kill-switch event (activation, deactivation, circuit trip) generates a signed audit record. Designed for immediate human-initiated AI halt in a single-developer environment.

---

## ASI09 — Trust Exploitation

**Status:** Design Tradeoff — Not Implemented

**Risk:** The AI exploits implicit trust granted by users, systems, or other agents to perform actions beyond its authorization.

### Design Tradeoff

This harness is designed for a Claude Code single-developer environment. Its primary goal is to prove what the AI *did* (tamper-evident audit trail) rather than to monitor live agent behavior. Implementing a runtime agent identity registry (ASI09) or behavioral monitoring system (ASI10) would require persistent agent processes and a separate infrastructure layer outside Claude Code's hook model. These are intentional design constraints, not implementation gaps.

---

## ASI10 — Rogue Agents

**Status:** Design Tradeoff — Not Implemented

**Risk:** An agent operates autonomously outside its defined boundaries, takes unauthorized actions, or persists after it should have been terminated.

### Design Tradeoff

This harness is designed for a Claude Code single-developer environment. Its primary goal is to prove what the AI *did* (tamper-evident audit trail) rather than to monitor live agent behavior. Implementing a runtime agent identity registry (ASI09) or behavioral monitoring system (ASI10) would require persistent agent processes and a separate infrastructure layer outside Claude Code's hook model. These are intentional design constraints, not implementation gaps.

---

## Summary

| ID | Title | Status | Primary Artifact |
|----|-------|--------|-----------------|
| ASI01 | Goal Hijacking | ✅ Covered | `examples/hooks/prompt-injection-guard.sh` |
| ASI02 | Tool Misuse | ✅ Covered | `examples/hooks/bash-secret-guard.sh`, `mcp-config-guard.sh` |
| ASI03 | Identity / Privilege Abuse | ⚠️ Partial | `tools/trustless_audit/src/signing.py` |
| ASI04 | Supply Chain | ✅ Covered | `examples/hooks/pre-commit-secrets.sh`, `.github/workflows/sbom-scan.yml` |
| ASI05 | Excessive Code Execution | ✅ Covered | `examples/hooks/bash-secret-guard.sh` |
| ASI06 | Memory Poisoning | ✅ Covered | `examples/hooks/claude-md-integrity.sh` |
| ASI07 | Inter-Agent Communication | ⚠️ Partial | `tools/trustless_audit/src/orchestration_audit.py` |
| ASI08 | Cascading Failures | ✅ Covered | `tools/kill-switch/kill-switch.sh` |
| ASI09 | Trust Exploitation | 🔹 Design Tradeoff | — |
| ASI10 | Rogue Agents | 🔹 Design Tradeoff | — |

**Coverage summary:** 6 fully covered, 2 partial, 2 intentional design tradeoffs (out of scope for single-developer hook-based harness).
