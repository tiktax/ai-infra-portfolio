# Multi-AI Governance Policy — Template
*Version 1.0 · Replace [COMPANY] and [DATE] with your values · Based on ai-infra-portfolio*

---

## Section 1: Use-Case Decision Matrix

| Use Case | Data Sensitivity | Recommended Platform | Rationale |
|---|---|---|---|
| Code generation (internal systems) | High | Claude (Bedrock / on-premise) | Audit trail required; signed hook logs via `examples/hooks/` |
| Customer-facing interaction (PII) | High | **Prohibited** | No external AI for personally identifiable information |
| Security analysis / vulnerability review | High | Claude | OWASP ASI coverage; signed audit via `compliance/verify.sh` |
| Internal document drafting (HR, legal) | Medium | Claude | Confidentiality controls; Constitutional AI alignment |
| Security analysis (threat modeling) | Medium | Claude | Structured reasoning; traceable chain-of-thought |
| General productivity (summarize, translate) | Low | Either | Cost-optimize per use case; no PII in prompt |
| Marketing content / image generation | Low | ChatGPT | GPT-4o image/voice capabilities |
| Public-facing FAQ chatbot | Low | Either | Evaluate output quality per domain; enforce content filter |
| Experimental / prototype only | Low | Either | Sandbox environment; no production data |

**Default rule:** When sensitivity is ambiguous, classify as Medium and use Claude until reviewed.

---

## Section 2: Audit Requirements by Platform

| Platform | Audit Mechanism | Hook Layer | Signed Audit | Portfolio Tool |
|---|---|---|---|---|
| Claude Code (CLI) | PreToolUse / PostToolUse hooks | Shell hooks in `examples/hooks/` | Yes — HMAC-signed jsonl | `examples/hooks/` |
| Claude API (Bedrock) | CloudTrail + custom middleware | API gateway layer | Yes — CloudTrail event | `tools/compliance/verify.sh` |
| OpenAI API | Request/response middleware | Python middleware | Yes — SHA-256 signed log | `tools/multi-ai-governance/openai-audit-middleware.py` |
| ChatGPT Enterprise | Admin console export | Platform-native | Partial — CSV export only | Manual review cadence |

**Minimum audit fields (all platforms):** `timestamp`, `user_id`, `model`, `prompt_hash`, `response_hash`, `data_classification`, `approver_tier`.

---

## Section 3: Approval Thresholds

| Tier | AI Operation Type | Approver | ITIL 5 Change Type | Turnaround |
|---|---|---|---|---|
| **Tier 1** | Standard task (Low sensitivity, pre-approved use case) | Self (user) | Standard Change | Immediate |
| **Tier 2** | New use case or Medium-sensitivity data | Team lead / AI Champion | Normal Change | ≤ 2 business days |
| **Tier 3** | High-sensitivity data, new platform, or production integration | CISO + AI Governance Board | Emergency / Major Change | CAB approval required |

**Tier 3 triggers (auto-escalate):**
- PII or regulated data (APPI, GDPR) in prompt
- New SIer API integration (Fujitsu, Hitachi, NEC, NTT Data, NRI endpoints)
- Model version upgrade in production
- Any incident involving AI-generated output in customer communication

---

## Section 4: Incident Response

When an AI-related incident is detected, follow this flow:

```
Detect → INC ticket → Severity triage (P0–P3)
  └─ P0/P1: Disable AI endpoint immediately → notify CISO within 1h
  └─ P2/P3: Log to INCIDENTS.md → RCA within 72h

RCA complete → Root cause: structural? → raise CIP (Continual Improvement Proposal)
  └─ CIP approved → Change (C-XXX) → deploy fix → close INC

SLO: RCA must complete within 72h of INC open timestamp.
```

**Reference:** `examples/incidents/` contains INC→RCA→CIP templates.

**Key fields in every INC record:** `inc_id`, `detected_at`, `platform` (Claude/OpenAI), `data_classification`, `rca_complete_at`, `linked_cip`.

---

## Section 5: Review Cadence

| Trigger | Action | Owner |
|---|---|---|
| Quarterly (every 3 months) | Full policy review; update decision matrix | AI Governance Lead |
| SIer partnership change | Re-evaluate affected platform rows in Section 1 | CISO + Procurement |
| Major model version release | Audit capability delta; re-classify if needed | AI Champion |
| P0 / P1 incident | Emergency review within 5 business days | AI Governance Board |
| Regulatory update (APPI / EU AI Act) | Compliance gap analysis | Legal + CISO |

**Next scheduled review:** [DATE + 3 months]

---

*→ Audit implementation (OpenAI): `tools/multi-ai-governance/openai-audit-middleware.py`*
*→ Audit implementation (Claude Code): `examples/hooks/`*
*→ OWASP coverage check: `tools/compliance/verify.sh`*
*→ Incident log templates: `examples/incidents/`*
*→ ITIL 5 governance framework: `tools/itil5-ai-governance/`*
