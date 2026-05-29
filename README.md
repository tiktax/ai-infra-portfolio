# Can you prove what your AI actually did — without trusting the system that recorded it?

**Period**: March – May 2026 | Personal project · [日本語版](README_ja.md)

---

Your AI made a mistake.
Can you prove what it did wrong, and who is responsible?

Most organizations can't answer that.
There are no logs. Or if there are, there is no way to know whether they were altered.
And when you try to verify — the party holding the logs is the same party being audited.

This repository is published as **one attempt** at answering that question.
Not a finished answer. A proposal — an opening for discussion.

- What the AI did, when, and in what order — traceable across the full lifecycle
- Where AI responsibility ends and human responsibility begins — explicitly recorded
- The record cannot be rewritten by anyone — protected by digital signatures and hash chains
- Governance continues across platform changes — no vendor owns the audit trail
- Incidents trigger an automated improvement cycle — the same failure does not recur

Two months. 13 incidents. 6 permanently resolved. The improvement cycle is still running.

→ [Verify in 30 seconds](./demo.sh) · [OWASP coverage](./tools/compliance/verify.sh) · [Implementation details](#8-implementation-details)

---

## 1. Why This Is Unsolved

Discussions of AI governance are growing. Most stop at "define a policy" or "capture logs."

The foundational question goes unasked: **who verifies those logs?**

The current structure:

```
AI takes an action
  → The platform creates the record
  → Verification is delegated to the same platform
  → The auditor and the audited party are identical
```

This is not a new problem. In financial reporting and medical records, the same structure is called "self-reporting" — and is not accepted as evidence on its own. Notarization, third-party audits, signed documents — human institutions have spent centuries building around this failure mode.

AI has no equivalent institution yet.

AI makes the problem harder. Human actions are slow, countable, and observable.
AI actions are fast, high-volume, and invisible. "Review it later" does not work at the scale AI operates.

The result:
- When an incident occurs, what happened cannot be traced
- Responsibility stays ambiguous — "the AI's fault" or "human error" — with no record to resolve it
- A platform change wipes out the entire history of governance decisions
- "We fixed it" is a claim, not a proof

This is not a technical problem. **It is a structural one.**

The technology already exists — digital signatures, hash chains, trusted timestamps.
These are standard tools in finance and law.
Applying them to AI action management remains nearly absent in practice.

---

## 2. One Attempt

This project tests what a single person can implement in two months against that structural problem.

One premise to state clearly: this is not a finished answer.
It is an implementation on a specific platform (Claude Code),
testing whether the structural approach is feasible within those constraints.

---

**1. Record AI actions across the full lifecycle**

Before and after each AI action, the action, decision, and result are automatically recorded.
Not isolated log entries — a chain where the sequence of events is preserved.
Each record is protected by digital signatures and hash chains:
altering any entry creates a detectable contradiction in every subsequent entry.

**2. Record the accountability boundary**

Did the AI decide, or did a human approve?
Was this system behavior or a configuration error?
When "who is responsible" is challenged after the fact, the record answers.

**3. Design for platform independence**

Governance logic is not bound to platform-specific features.
If Claude Code changes, or a different AI is adopted,
the record and improvement cycle continue in an independent layer.

**4. Automate the improvement cycle**

A record alone is not enough when an incident occurs.
Incident → root cause analysis → improvement proposal → implementation → verification:
this cycle runs without human intervention.
If the same failure recurs, the system records it as a systemic failure.

**5. Externalize the reasoning process** *(next phase)*

The AI's internal computation remains a black box.
However, structuring and externalizing the reasoning process —
and recording the "stated logic" with a signature — is technically feasible.

→ Details: [`docs/roadmap.md — Phase 6`](docs/roadmap.md)

---

---

## 3. Observation Data

Data from two months of implementation at individual scale.
Read this as observations of what happened at this scale — not as achievements.

### Incidents and resolution

| Item | Count |
|---|---|
| Incidents that occurred | 13 |
| Permanently resolved | 6 |
| Detected by automated improvement cycle | 6 of 6 |
| Credential leaks after hook enforcement | 0 (before: 2) |

All 13 incidents have a root cause analysis on record.
Not "fixed" — but "why it happened, and how the structure was changed" — traceable.

### Cost and scale

| Metric | Before | After | Change |
|---|---|---|---|
| AI call cost — L5 subprocess flags | $0.21/call | $0.001/call | −99.3% measured |
| SessionStart context size — L2 | 19 MB | 36 KB | −99.8% measured |
| RTK output compression — L6 | content tokens | −70% daily avg | measured, 37 days |
| L5 + L6 + L7 compound per call | $0.21/call | ~$0.00009/call | −99.96% |

> Full breakdown by technique (what each compresses, at what scale): [`docs/achievements.md`](docs/achievements.md) · 8-layer reference: [`docs/token-optimization-layers.md`](docs/token-optimization-layers.md)

These numbers do not demonstrate a good implementation.
They demonstrate **how inefficient and unverifiable unstructured AI operations actually are.**
The size of the reduction reflects the depth of the starting problem, not the quality of the fix.

The −99.3% per-call figure was measured on this environment. Your number will differ — more MCP servers and a larger CLAUDE.md mean a higher baseline and a larger reduction. Run [`examples/benchmark/measure-baseline.sh`](examples/benchmark/measure-baseline.sh) to measure your own optimization headroom in under a minute.

---

## 4. What This Attempt Does Not Answer

An honest record. The following are not "future improvements" —
they are structural limits of this attempt, and questions that remain open.

### Technical open questions

| Question | Current state |
|---|---|
| Who holds the signing key | In personal use: 1Password. At organizational scale, key management itself becomes a new trust center |
| Timestamp reliability | External timestamps via RFC 3161 — but that server is trusted |
| Signing AI output itself | Actions can be signed. Signing AI-generated content (C2PA equivalent) is not implemented |
| Post-quantum migration | ML-DSA-65 implemented; compatibility with existing signed records is unverified |
| Hook bypass in production | Subprocess calls using `--setting-sources ""` disable all hooks at the process level. Tracked as INC-015. Mitigation: audit all Claude subprocess invocations before using hook-based enforcement as a security boundary. |

### Structural open questions

**Scale**
Deployment to teams of 10–500 is designed and automated (`install.sh`, `manage.sh`, scale-specific analysis).
What remains untested: whether this design holds at 1,000+ with key management and permission separation intact.

**Who audits the governance system**
A system was built to audit AI actions. Who audits this system?
A design that avoids infinite regress does not yet exist.

**Legal standing**
A cryptographically protected record is technically tamper-resistant.
Whether it constitutes legal evidence depends on jurisdiction, industry, and regulation.

**AI "intent" cannot be recorded**
Actions can be recorded. Why the AI made a particular judgment remains a black box.
Phase 6 (reasoning externalization) is a partial response to this — but whether
stated reasoning corresponds to actual reasoning is an unsolved question.

### Next phase: externalizing and recording the reasoning process

Structuring AI reasoning into externalized output before action — then capturing,
signing, and chaining that output as part of the audit record — is technically feasible.
Three techniques are planned in combination:

**Semi-Formal Reasoning** (Meta, April 2026)
Forces premises → execution trace → conclusion in sequence.
The AI's judgment becomes a "logic certificate" that can be signed and hash-chained.

**Verbalized Confidence**
Each claim is assigned a confidence score (0–100).
Low-confidence decisions are flagged for human review and recorded.

**Town Hall Debate Prompting** (2025)
Multiple expert personas deliberate within a single AI, reaching a conclusion by vote.
The deliberation transcript is recorded as evidence that alternatives were considered.

The question that remains:
**Whether stated reasoning corresponds to actual reasoning is still unsolved.**

→ Details: [`docs/roadmap.md — Phase 6`](docs/roadmap.md)

---

## 5. Platform-Agnostic Design

Binding governance to a platform means governance disappears when the platform changes.

This is not a theoretical risk.
Implementing governance in Claude Code-specific features means
that migrating to Cursor, GitHub Copilot, or a next-generation AI tool
requires rebuilding hooks, policies, and the audit trail from scratch.
If migration costs are high enough, the choice not to migrate is forced —
which is another name for vendor lock-in.

This design avoids that by separating into three layers:

```
Governance layer    INC→CIP cycle, ISO alignment, risk scoring, audit trail
(tool-agnostic)  →  Works with any AI platform. No changes required.

Policy layer        Role-based rules, acceptable use policy, behavioral specs
(adaptable)      →  Concept is universal; format adapts per platform.

Implementation      PreToolUse/PostToolUse hooks, CLAUDE.md, MCP server
(platform-specific) → Needs reimplementation per platform. That is expected.
```

| Platform | Hook equivalent | Policy equivalent | Audit implementation |
|---|---|---|---|
| Claude Code | PreToolUse / PostToolUse hooks | CLAUDE.md + MCP server | `examples/hooks/` ✅ |
| OpenAI API | `AuditedOpenAI` middleware | System prompt | `tools/multi-ai-governance/openai-audit-middleware.py` ✅ |
| Cursor | `.cursorrules` + VS Code extension | `.cursorrules` | — |
| GitHub Copilot | IDE extension + org policy | Organization-level policy | — |
| Amazon Bedrock | AWS Lambda Guardrails | System prompt | — |

Reimplementing the implementation layer has a bounded cost.
The governance and policy layers continuing across migrations is the core of this design.

**This is now demonstrated, not just claimed.**
`tools/multi-ai-governance/openai-audit-middleware.py` wraps the OpenAI Python client
and records every `chat.completions.create()` call with the same ECDSA-signed audit entry format
as the Claude Code audit trail — same JSON schema, same `approvals.log`, same verification command.

```bash
# Demo (no API key needed):
python3 tools/multi-ai-governance/openai-audit-middleware.py --demo
# → audit entry signed and written to approvals.log
# → same format as Claude Code entries; verified with the same tool
```

For enterprises operating both Claude and ChatGPT (Fujitsu, NRI, and others now doing so),
a use-case decision matrix is available at:
[`tools/multi-ai-governance/multi-ai-policy-template.md`](tools/multi-ai-governance/multi-ai-policy-template.md)

---

## 6. Invitation to Discussion

This project is one attempt at the questions below.
If there is a better answer, this is an invitation to bring it.

---

**Design questions**

- Is there a better abstraction for separating governance from the platform?
- What does realistic key management look like when operated at organizational scale?
- How much divergence between stated reasoning and actual reasoning is acceptable?

**Scale questions**

- Does a system that works for one person hold at 1,000?
- When AI action volume exceeds human oversight capacity, what changes?

**Legal and institutional questions**

- Under what conditions and in which jurisdictions is a cryptographically signed record legally admissible?
- How should records stating "the AI decided" or "the MCP server executed" be treated in accountability decomposition?

---

Disagreement, alternative implementations, counterarguments — all are welcome.

→ [Open a discussion](https://github.com/tiktax/ai-infra-portfolio/discussions)
→ [File an issue or improvement](https://github.com/tiktax/ai-infra-portfolio/issues)

---

## 7. Verification

**Three verification modes — choose based on what you want to confirm.**

```bash
./demo.sh                      # Hook blocking only. 16 tests. ~10 seconds.
./demo-full.sh                 # Full chain: hook → signing → tamper detect → INC→CIP → LLM routing.
./tools/compliance/verify.sh   # OWASP Agentic Top 10 coverage. ~5 seconds.
```

`demo.sh` expected output:
```
🔍 AI Harness Security Hook Demo
=================================
--- Commands that SHOULD be blocked ---
  ✅ BLOCKED  cat .env
  ✅ BLOCKED  grep password .env
  ✅ BLOCKED  echo $SECRET_TOKEN
--- Commands that SHOULD pass ---
  ✅ PASSED   wc -l .env (metadata only)
  ✅ PASSED   git status
Results: 16 passed, 0 failed
✅ All tests passed. Hook is working correctly.
```

`tools/compliance/verify.sh` expected output:

> **Why 6/10 and not 10/10**: ASI09 (Trust Exploitation) and ASI10 (Rogue Agents) require a runtime agent identity registry — intentionally out of scope for a single-developer harness focused on proving actions, not monitoring agent behavior. Tools that claim 10/10 coverage typically count policy documents as artifacts. This project counts only executable, verifiable code. See [`docs/compliance/owasp-agentic-top10-mapping.md`](docs/compliance/owasp-agentic-top10-mapping.md).

```
OWASP Agentic AI Top 10 — Coverage Report
===========================================

  ✅ ASI01  Goal Hijacking             examples/hooks/prompt-injection-guard.sh
  ✅ ASI02  Tool Misuse                examples/hooks/bash-secret-guard.sh
  ⚠️  ASI03  Identity/Privilege Abuse  tools/trustless_audit/src/signing.py
  ✅ ASI04  Supply Chain               examples/hooks/pre-commit-secrets.sh
  ✅ ASI05  Code Execution             examples/hooks/bash-secret-guard.sh
  ✅ ASI06  Memory Poisoning           examples/hooks/claude-md-integrity.sh
  ⚠️  ASI07  Inter-Agent Comms          tools/trustless_audit/src/orchestration_audit.py
  ✅ ASI08  Cascading Failures         tools/kill-switch/kill-switch.sh
  🔹 ASI09  Trust Exploitation
  🔹 ASI10  Rogue Agents

  Covered:  6/10
  Partial:  2/10  (artifact exists; partial coverage)
  Tradeoff: 2/10  (intentionally out of scope — see notes)

  ✅ All covered items verified.
```

**CLAUDE.md integrity demo** (ASI06 — memory poisoning proof):
```bash
# Any Write/Edit to CLAUDE.md automatically creates a signed audit entry.
# To verify the record:
python tools/trustless_audit/src/audit.py --verify --action claude_md_modified
# ✅ 1 CLAUDE.md modification verified (ECDSA P-256)
```

`demo-full.sh` verifies the complete governance chain end-to-end, including ECDSA signing and tamper detection. Requires `pip install cryptography` for Section 2; other sections run without it.

> The ROI calculator and deployment playbook allow an organization to verify the economic and operational case without re-deriving it from scratch.
> [`tools/roi-calculator/`](tools/roi-calculator/) · [`docs/deployment-playbook.md`](docs/deployment-playbook.md)

---

## 8. Implementation Details

### How this compares to other approaches

Runtime enforcement tools — intercepting agent calls and blocking unauthorized actions — are a necessary first layer of defense.
[Microsoft's Agent Governance Toolkit](https://github.com/microsoft/agent-governance-toolkit) does this well for SDK-integrated agent frameworks (LangChain, AutoGen, OpenAI Agents SDK).

Two things distinguish this project:

**First, the layer.** AGT's SDK hooks do not intercept MCP-native tool calls in Claude Code or Cursor.
This project operates at the PreToolUse/PostToolUse hook layer — precisely where those tools do not reach.

**Second, the question.** Policy enforcement answers "was this action allowed?"
This project answers "can you prove, after the fact, that the record of what happened has not been altered?"
ECDSA signatures, RFC 3161 timestamps, and WORM storage are the answer to that second question.

> The MCP blind spot is a current architectural constraint of SDK-layer tools — likely to narrow over time.
> This distinction exists today.

---

### The cryptographic chain

Every gate approval is signed with ECDSA (NIST P-256) and its hash included in the next entry —
forming a chain where any modification is immediately detectable.

```
Entry N:
  prev_hash: sha256(Entry N-1)
  action: "bash command approved"
  timestamp: 2026-04-12T09:14:22Z
  signature: ECDSA(private_key, sha256(action + timestamp + prev_hash))
Entry N+1:
  prev_hash: sha256(Entry N)   ← breaks if Entry N is altered
  ...
```

Rewriting a past governance decision requires re-signing every subsequent entry —
with a private key held offline. This represents a cost and operational barrier
that makes retroactive alteration practically infeasible.

### What was built

| Area | Contents | Artifact |
|---|---|---|
| Signed audit infrastructure | ECDSA signing (FIPS 186-5), M-of-N multi-sig, ML-DSA-65 PQC (FIPS 204), RFC 3161 trusted timestamps, S3 Object Lock WORM | [`tools/trustless_audit/`](tools/trustless_audit/) |
| Security enforcement | 6 guardrail hooks (credential leak, PII, supply chain, MCP config, npm typosquatting, worktree guard), gitleaks CI, 1Password CLI integration | [`examples/hooks/`](examples/hooks/) · [`tests/hooks/`](tests/hooks/) |
| ITIL 5 AI Governance | 8-activity lifecycle (Discover→Retire), 6C Capability Model, EU AI Act / Japan FSA / US SR11-7 alignment | [`tools/itil5-ai-governance/`](tools/itil5-ai-governance/) |
| Incident management | INC→Problem→CIP→Change cycle, 13 incidents tracked, 6 permanently resolved, SLO monitoring | [`examples/incidents/`](examples/incidents/) |
| Team deployment | Automated installer, role-based access control (3 tiers), onboarding automation, scale-specific playbooks (startup → enterprise) | [`install.sh`](install.sh) · [`manage.sh`](tools/claude-config-manager/manage.sh) · [`docs/deployment-playbook.md`](docs/deployment-playbook.md) |
| OWASP Agentic Top 10 | 6/10 covered ✅ · 2/10 partial ⚠️ · 2/10 design tradeoff 🔹 — ASI09/ASI10 require runtime agent identity registry (intentionally out of scope); ASI01–08 covered with executable hooks | [`tools/compliance/verify.sh`](tools/compliance/verify.sh) · [`docs/compliance/`](docs/compliance/) |

<details>
<summary>Full artifact list (click to expand)</summary>

| Area | Contents | Artifact |
|---|---|---|
| Cost control | Local/cloud LLM auto-routing via LiteLLM Proxy | [`docs/achievements.md`](docs/achievements.md) |
| Observability | Log digest automation, 3-tier memory architecture | [`docs/dashboard.md`](docs/dashboard.md) |
| TRiSM Privacy coverage | PII guard hook, display-time scrubbing, DPIA dashboard, cross-border transfer docs (40% → 75%) | [`examples/hooks/pii-guard.sh`](examples/hooks/pii-guard.sh) · [`tools/trustless_audit/src/audit.py`](tools/trustless_audit/src/audit.py) |
| End-to-end demo | Full-chain verification: hook → ECDSA sign → tamper detect → INC→CIP → LLM routing | [`demo-full.sh`](demo-full.sh) · [`samples/`](samples/) |
| SBOM & dependency scan | CycloneDX SBOM generation + pip-audit vulnerability scan in CI | [`.github/workflows/sbom-scan.yml`](.github/workflows/sbom-scan.yml) |
| MCP accountability boundary | MCP server register, decision boundary enforcement, audit schema for tool calls | [`tools/governance-mcp/mcp-accountability-register.md`](tools/governance-mcp/mcp-accountability-register.md) |
| Orchestration audit chain | Per-agent signed logs with hash-linked parent-child delegation records | [`tools/trustless_audit/src/orchestration_audit.py`](tools/trustless_audit/src/orchestration_audit.py) |
| GitHub Actions OIDC (WIF) | Keyless AWS auth via OIDC federation — no long-lived credentials in GitHub Secrets | [`tools/wif/`](tools/wif/) · [`.github/workflows/worm-audit.yml`](.github/workflows/worm-audit.yml) |

</details>

Full system diagrams: [`docs/architecture.md`](docs/architecture.md)

### Roadmap

| Phase | Contents | Status |
|---|---|---|
| Phase 1–5 | Security hooks → ITIL 5 → Privacy law → Accountability → Signed audit infrastructure | ✅ Complete |
| Phase 6 (Privacy TRiSM) | PII guard hook, display-time scrubbing, DPIA dashboard, cross-border docs | ✅ Complete |
| Phase 7a | End-to-end demo (`demo-full.sh`) + annotated sample audit log | ✅ Complete |
| SBOM | CycloneDX dependency manifest + pip-audit CI workflow | ✅ Complete |
| Phase 7b | MCP accountability boundary — audit schema + register + governance-mcp tool | ✅ Complete |
| Phase 7c | Sub-agent / orchestration audit trail — hash-linked delegation chain | ✅ Complete |
| Phase 7d | GitHub Actions OIDC — keyless AWS auth via Workload Identity Federation | ✅ Complete |
| Phase 7e | Kill Switch + Circuit Breaker — signed stop/trip events in audit log | ✅ Complete |
| Phase 8a | OWASP gap-fill hooks (ASI01 prompt injection, ASI06 CLAUDE.md integrity) + verify.sh | ✅ Complete |
| Phase 8b | Compliance mapping docs (OWASP Agentic Top 10, NIST AI RMF) | ✅ Complete |
| Multi-AI | OpenAI API audit middleware + Multi-AI policy template (Claude ↔ ChatGPT) | ✅ Complete |
| Phase 6 (Reasoning) | Reasoning process externalization and recording | Planned |

→ Details: [`docs/roadmap.md`](docs/roadmap.md)

### Docs & Tools

| File | Contents |
|---|---|
| [`docs/achievements.md`](docs/achievements.md) | Quantified results with calculation basis |
| [`docs/architecture.md`](docs/architecture.md) | System diagrams (hook flow, 5-layer stack, ITSM cycle) |
| [`docs/ai-usage-policy-draft.md`](docs/ai-usage-policy-draft.md) | AI usage policy (ISO/IEC 27001-aligned) |
| [`docs/deployment-playbook.md`](docs/deployment-playbook.md) | Deploy to a team of 10+ |
| [`docs/roadmap.md`](docs/roadmap.md) | Phase-by-phase implementation plan |
| [`docs/considerations/`](docs/considerations/) | Gap analysis by scale + regulated industries |
| [`examples/hooks/`](examples/hooks/) | 6 security hook implementations (runnable) |
| [`examples/incidents/`](examples/incidents/) | Redacted incident records: INC→RCA→CIP flow |
| [`tools/roi-calculator/`](tools/roi-calculator/) | Estimate cost savings at org scale |
| [`tools/governance-mcp/`](tools/governance-mcp/) | MCP server — query governance data from Claude Code |

### Tech Stack

| Technology | Role |
|---|---|
| Claude Code + Claude API | AI agent runtime + cloud inference |
| Gemma4 + LiteLLM Proxy | Local LLM inference + auto-routing |
| bash hooks | PreToolUse / PostToolUse enforcement |
| Python + cryptography | ECDSA signing (FIPS 186-5) |
| dilithium-py | ML-DSA-65 post-quantum signatures (FIPS 204) |
| rfc3161ng | RFC 3161 trusted timestamps |
| boto3 + AWS S3 Object Lock | 7-year COMPLIANCE mode WORM storage |
| gitleaks | Secret scanning in CI |
| 1Password CLI | Credential management |
| GitHub API + Notion API + Telegram Bot API | Incident tracking, knowledge base, notifications |
