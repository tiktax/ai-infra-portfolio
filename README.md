# AI Infrastructure Portfolio
> *"What is needed is an AI governance system based on cryptographic proof instead of trust."*

**Period**: March – May 2026 | Personal project · [日本語版](README_ja.md)

---

## 1. Introduction

Current AI deployments rely almost exclusively on trust — trust in the model, trust in the operator. Most organizations have not even reached the point of asking whether their logs are trustworthy: there are no logs to question.

This trust-based model contains an inherent vulnerability: **there is no mechanism to verify that AI acted as claimed, without relying on the same party being audited.**

A purely trust-based approach can never offer truly non-repudiable accountability. Audit costs scale with the volume of AI actions. The absence of a tamper-evident record means incidents cannot be traced, and improvements cannot be proven.

What is needed is an AI governance system based on cryptographic proof instead of trust — allowing any party to verify AI behavior without relying on the system being audited.

This project builds that system.

```bash
git clone https://github.com/tiktax/ai-infra-portfolio
cd ai-infra-portfolio
./demo.sh
```

Expected output:
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

---

## 2. The Problem: Double-Trust

**Double-trust** is the inability to prove an AI action occurred as recorded, without trusting the system that recorded it.

| The question | The failure |
|---|---|
| Who prevents an AI log being altered after the fact? | The auditor is auditing themselves. |
| How do you trust an AI audit trail without trusting the auditor? | You can't — without cryptographic proof. |
| Solved by: | Hash chains + ECDSA signatures |

The common failure mode: organizations adopt AI, incidents occur, logs are checked — but the logs themselves are unverified.

---

## 3. The Solution: A Tamper-Evident Record of AI Actions

Every AI action passes through a hook layer before and after execution. Each decision is recorded, hashed, and chained — making the sequence of governance events tamper-evident without requiring trust in any single party.

```
sequenceDiagram
    participant U as User
    participant CC as Claude Code
    participant H as Hooks (PreToolUse)
    participant LLM as LiteLLM Proxy
    participant API as Claude API / Local LLM
    U->>CC: Command input
    CC->>H: bash-secret-guard.sh (credential detection)
    alt Secrets detected
        H-->>CC: exit 2 (block)
        CC-->>U: ⚠️ Blocked + remediation guidance
    else Clean
        H-->>CC: exit 0 (pass)
        CC->>LLM: API call (light / heavy / auto)
        LLM->>API: Route by complexity
        API-->>LLM: Response
        LLM-->>CC: Response
        CC->>H: PostToolUse — audit log entry (SHA-256 chained)
        CC-->>U: Output returned
    end
```

Full diagrams: [`docs/architecture.md`](docs/architecture.md)

---

## 4. How It Works: The Cryptographic Chain

Every gate approval is signed with ECDSA (NIST P-256) and its hash included in the next entry — forming a chain where any modification is immediately detectable.

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

Rewriting a past governance decision requires re-signing every subsequent entry — and the private key is held offline. This is not merely expensive: it is **cryptographically impossible** without the signing key.

---

## 5. What Was Built

Five areas, each driven by a concrete incident or operational failure.

### 5.1 Security Governance
*ISO/IEC 27001: A.9 Access Control, A.12 Operations Security, A.16 Incident Management*

**Problem (INC-011, INC-012):** Credential leak via AI tool output discovered in production.

**Built:**
- 9 guardrail hooks (`PreToolUse` / `PostToolUse`) intercepting risky commands before execution
- AI behavioral policy (ISO/IEC 27001-aligned), version-controlled in Git
- 1Password CLI integration — eliminated plaintext secrets from all config files
- gitleaks CI scanning every push and pull request

**Result:** Zero recurrence after initial remediation.

### 5.2 Cost Control

**Problem:** AI inference costs growing without visibility.

**Built:** Local LLM (Gemma4) / Cloud LLM (Claude API) auto-routing via LiteLLM Proxy.

| Metric | Before | After | Change |
|---|---|---|---|
| CLI call cost | $0.21/call | $0.001/call | **−99.5%** |
| SessionStart context size | 19 MB | 36 KB | **−99.8%** |
| Est. annual token usage | 33.2B tokens | 13.3M tokens | **−99.96%** |

> Calculation basis: [`docs/achievements.md`](docs/achievements.md)

### 5.3 Incident Management
*ISO/IEC 20000: Incident → Problem → Change → Continual Improvement*

**Problem:** AI failures handled reactively with no permanent resolution path.

**Built:**
- Full INC → Problem → CIP → Change cycle
- 13 incidents tracked from discovery through root cause to permanent resolution
- SLO monitoring for context size and MCP connector count

**Result:** 6 permanent resolutions (CIP-001–006); improvement cycle now automated.

### 5.4 Operations Automation

**Problem:** Repetitive tasks done manually.

**Built:**
- 3 scheduled agents (daily digest, weekly KPI, weekly procedure tracking)
- API integration: Notion / GitHub / Telegram
- LLM-Wiki: Karpathy's concept implemented as a PDCA knowledge cycle

### 5.5 Observability

**Problem:** Claude Code injects the full session log into context at every session start. As logs grew, context size ballooned — directly inflating token usage and inference cost on every invocation.

**Built:**
- Daily log digest automation — compresses raw session logs into structured summaries, reducing log file size by 93% and cutting SessionStart context from 19 MB to 36 KB
- 3-tier memory architecture (session / project / Obsidian long-term) — retains actionable history while discarding noise
- Claude API usage monitoring with hard limit detection — prevents cost overruns before they occur

---

## 6. Design: Platform-Agnostic by Principle

The implementation uses Claude Code — but the governance framework is designed to survive platform changes.

External tools (Notion, Telegram, GitHub API, LiteLLM Proxy) are used in the implementation. Each is a trust dependency. The design goal is to ensure that governance decisions are verifiable independently of any single one of them: the signed audit chain is the ground truth, not the external service's own record.

```
Governance layer   INC→CIP cycle, ISO alignment, risk scoring, audit trail
(tool-agnostic) →  Works with any AI platform. No changes needed.

Policy layer       Role-based rules, acceptable use policy, CLAUDE.md
(adaptable)    →   Concept is universal; format changes per platform.

Implementation     PreToolUse/PostToolUse hooks, CLAUDE.md, MCP server
(platform-specific)→ Needs reimplementation per platform.
```

| Platform | Hook equivalent | Policy equivalent |
|---|---|---|
| Cursor | `.cursorrules` + VS Code extension | `.cursorrules` |
| GitHub Copilot | IDE extension + org policy | Organization-level policy |
| OpenAI API | API middleware (Lambda / proxy) | System prompt |
| Amazon Bedrock | AWS Lambda Guardrails | System prompt |
| Microsoft 365 Copilot | Purview DLP + Conditional Access | Admin center policy |

---

## 7. Why Governance Pays

**Organizations that govern AI honestly bear lower incident costs, lower remediation costs, and lower regulatory risk than those that don't.**

This project makes that argument with numbers:
- 99.5% cost reduction from structured routing over ad-hoc invocation
- Zero credential incidents after systematic hook enforcement vs. two incidents before
- 6 permanent resolutions vs. recurring manual firefighting

Governance is not a cost. It is the cheaper path.

---

## 8. Accountability: What AI Owns, What Humans Own

| Scenario | AI's Responsibility | Human's Responsibility |
|---|---|---|
| AI generates incorrect data | Generation quality (technical) | Adoption decision + verification |
| AI system is compromised | System vulnerability | Security configuration |
| AI executes autonomously | Technical execution | Permission settings + scope control |
| AI produces inappropriate output | Output quality | Monitoring + filtering |

> Full register: [`tools/itil5-ai-governance/accountability-register.md`](tools/itil5-ai-governance/accountability-register.md)

---

## 9. Verification

**Anyone can verify the security hooks are working in under 60 seconds, without reading the full codebase.**

```bash
./demo.sh
# 16 tests. No setup required. Output is self-explanatory.
```

The ROI calculator and deployment playbook extend this further — allowing an organization to verify the economic and operational case without re-deriving it from scratch.

> [`tools/roi-calculator/`](tools/roi-calculator/) · [`docs/deployment-playbook.md`](docs/deployment-playbook.md)

---

## 10. Known Limitations

A system that claims no weaknesses is itself untrustworthy.

| Limitation | Current state | Status |
|---|---|---|
| Single key management | 1Password CLI dependency | ✅ Multi-signature M-of-N implemented (`tools/trustless_audit/src/multisig.py`) |
| Post-quantum cryptography | NIST P-256 / ECDSA | ✅ ML-DSA-65 / CRYSTALS-Dilithium (FIPS 204) implemented (`src/pqc_signing.py`) |
| Timestamp trust | Server clock dependent | ✅ RFC 3161 / freetsa.org implemented (`src/timestamp.py`) |
| AI output signing (C2PA) | Not implemented | Roadmap: Sign AI output artifacts |
| WORM storage | Append-only log files | ✅ AWS S3 Object Lock, 7-year COMPLIANCE mode (`src/worm_storage.py`) |

---

## 11. Conclusion

This project proposes a shift in how AI is governed: trust in AI vendors, AI operators, and AI logs — replaced by trust in cryptographic mechanisms, audit chains, and enforced behavioral specifications.

The result is a governance framework that is:
- **Verifiable** — any claim can be checked independently
- **Non-repudiable** — every decision is signed and chained
- **Platform-agnostic** — the principles survive any vendor change
- **Economically justified** — 99.96% token reduction; zero post-remediation incidents

The network of AI agents is growing. The question is not whether to govern it — but whether governance will be built on trust, or proof.

---

## Timeline

```
March                     April                          May
│                         │                              │
▼                         ▼                              ▼
Proved the concept.       Two problems hit at once:      Fixes alone don't
Notion/Telegram/GitHub    cost ($0.21/call) and a        prevent recurrence.
integrations running —    credential leak in prod.       Built governance:
and discovered AI tools   Solved both from scratch:      INC→CIP cycle,
leak secrets if           9 hooks + 99.96% token cut.   6 permanent fixes,
left unconstrained.       Not patched — engineered.     loop now automated.
```

---

## Docs & Tools

| File | Contents |
|---|---|
| [`docs/achievements.md`](docs/achievements.md) | Quantified results with calculation basis |
| [`docs/architecture.md`](docs/architecture.md) | System diagrams (hook flow, 5-layer stack, ITSM cycle) |
| [`docs/ai-usage-policy-draft.md`](docs/ai-usage-policy-draft.md) | AI usage policy (ISO/IEC 27001-aligned) |
| [`examples/hooks/`](examples/hooks) | 5 security hook implementations (runnable) |
| [`examples/incidents/`](examples/incidents) | Redacted incident records: INC→RCA→CIP flow |
| [`tests/hooks/`](tests/hooks) | Regression test suite |
| [`demo.sh`](demo.sh) | One-command verification — no setup required |
| [`docs/deployment-playbook.md`](docs/deployment-playbook.md) | Deploy to a team of 10+ |
| [`tools/roi-calculator/`](tools/roi-calculator) | Estimate savings at org scale |
| [`tools/claude-config-manager/`](tools/claude-config-manager) | Multi-user CLAUDE.md with audit trail |
| [`tools/governance-mcp/`](tools/governance-mcp) | MCP server — query governance data from Claude Code |
| [`tools/itil5-ai-governance/`](tools/itil5-ai-governance) | ITIL 5 AI Governance: 8-activity lifecycle, multi-jurisdiction |
| [`tools/trustless_audit/`](tools/trustless_audit) | ECDSA signing, multi-sig, PQC, RFC 3161, WORM storage |
| [`docs/considerations/`](docs/considerations) | Gap analysis by scale + regulated industries |

---

## Tech Stack

| Technology | Version | Role |
|---|---|---|
| Claude Code | Latest | AI agent runtime |
| Claude API | Latest | Cloud LLM inference |
| Gemma4 | Latest | Local LLM via LiteLLM Proxy |
| gitleaks | Latest | Secret scanning in CI |
| 1Password CLI | Latest | Credential management |
| bash hooks | — | PreToolUse / PostToolUse enforcement |
| GitHub API | REST v3 | Incident and governance tracking |
| Notion API | Latest | Knowledge base integration |
| Telegram Bot API | Latest | Notification pipeline |
| Python | 3.10+ | ECDSA signing, audit reports |
| cryptography | 41.0+ | NIST P-256 signatures (FIPS 186-5) |
| dilithium-py | 1.4.0+ | ML-DSA-65 post-quantum signatures (FIPS 204) |
| rfc3161ng | 1.1+ | RFC 3161 trusted timestamps |
| boto3 | 1.34.0+ | AWS S3 Object Lock (WORM) |
| AWS S3 Object Lock | — | 7-year COMPLIANCE mode immutability |

---

## Contact

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?logo=linkedin)](https://www.linkedin.com/in/takeshi-koide-3337193b/)
