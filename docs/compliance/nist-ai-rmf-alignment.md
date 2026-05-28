# NIST AI RMF 1.0 — Project Alignment

This document maps project artifacts to NIST AI Risk Management Framework 1.0 functions. This is an alignment mapping, not a certification claim.

The four RMF functions — GOVERN, MAP, MEASURE, MANAGE — are addressed in sequence below. Each section includes a table of subcategory-to-artifact mappings and notes on coverage depth.

---

## GOVERN

The GOVERN function establishes organizational policies, roles, and accountability structures for AI risk management.

| RMF Subcategory | Artifact | Notes |
|----------------|----------|-------|
| AI risk policy | [`docs/ai-usage-policy-draft.md`](../ai-usage-policy-draft.md) | ISO/IEC 27001-aligned policy draft covering AI usage boundaries, approval gates, and prohibited actions |
| Roles and accountability | [`tools/governance-mcp/mcp-accountability-register.md`](../../tools/governance-mcp/mcp-accountability-register.md) | Decision boundary register mapping AI actions to human accountable owners |
| Organizational governance | [`tools/itil5-ai-governance/`](../../tools/itil5-ai-governance/) | ITIL 5 8-activity lifecycle (Discover → Design → Build → Deploy → Operate → Observe → Improve → Retire) with 6C Capability Model |

---

## MAP

The MAP function identifies AI risks in context, including the deployment environment, intended use, and affected stakeholders.

| RMF Subcategory | Artifact | Notes |
|----------------|----------|-------|
| Risk identification | [`tools/itil5-ai-governance/`](../../tools/itil5-ai-governance/) | Feature gates 01–08 implement structured risk gates at the Discover phase before any capability is deployed |
| Privacy risk | [`tools/trustless_audit/src/audit.py`](../../tools/trustless_audit/src/audit.py), [`docs/privacy-law-matrix.md`](../privacy-law-matrix.md) | Display-time PII scrubbing in audit output; privacy law matrix maps GDPR/CCPA/APPI requirements to project controls |
| Supply chain risk | [`.github/workflows/sbom-scan.yml`](../../.github/workflows/sbom-scan.yml) | CycloneDX SBOM generated on every push; pip-audit checks against OSV vulnerability database |
| Scope and deployment context | [`docs/considerations/`](../considerations/) | Five scale-specific gap analyses covering deployment at personal, team, enterprise, regulated-industry, and 1000+-user scales |

---

## MEASURE

The MEASURE function analyzes and assesses AI risks using metrics, testing, and evaluation.

| RMF Subcategory | Artifact | Notes |
|----------------|----------|-------|
| Risk tracking and SLO monitoring | [`tools/itil5-ai-governance/monitor.sh`](../../tools/itil5-ai-governance/monitor.sh) | Monitors SLO compliance for AI governance metrics; alerts on threshold breaches |
| Incident metrics | [`examples/incidents/`](../../examples/incidents/) | 13 documented incidents with root cause analysis; 6 resolved with verified closure criteria |
| Audit evidence and tamper-evidence | [`tools/trustless_audit/`](../../tools/trustless_audit/) | ECDSA + ML-DSA-65 dual-signature, RFC 3161 trusted timestamps, S3 WORM storage — cryptographic proof of AI action history |
| Coverage metrics | [`tools/compliance/verify.sh`](../../tools/compliance/verify.sh) | OWASP Agentic AI coverage reporter; produces per-item status across the audit harness |

---

## MANAGE

The MANAGE function addresses AI risks through response planning, incident handling, and continuous improvement.

| RMF Subcategory | Artifact | Notes |
|----------------|----------|-------|
| Incident response lifecycle | [`examples/incidents/`](../../examples/incidents/) | INC → Problem → CIP → Change four-phase cycle; each incident has RCA, corrective action, and verified resolution |
| Kill switch / immediate halt | [`tools/kill-switch/kill-switch.sh`](../../tools/kill-switch/kill-switch.sh) | Immediate AI activity halt; every activation and deactivation generates a signed, timestamped audit event |
| Continual improvement workflow | [`tools/itil5-ai-governance/`](../../tools/itil5-ai-governance/) | CIP (Continual Improvement Proposal) → Change approval workflow; changes require explicit human approval token before governance files are modified |
| Deployment and operational runbooks | [`install.sh`](../../install.sh), [`manage.sh`](../../manage.sh), [`docs/deployment-playbook.md`](../deployment-playbook.md) | Reproducible install and day-2 management procedures for the governance harness |

---

## Honest Limitations

The following gaps exist as of the current project state:

**Certification status:** NIST AI RMF certification has not been pursued. This mapping is a self-assessment for portfolio documentation purposes.

**AI reasoning externalization (Phase 6b):** The planned Phase 6b capability — externalizing AI chain-of-thought reasoning into the audit trail — is not yet implemented. Until complete, the MEASURE and MANAGE functions have partial coverage: audit records prove *what* the AI did but not *why* it made a specific decision. This is a known gap tracked as a roadmap item.

**Scale testing:** Organizational deployment at 1000+ user scale is designed and documented in `docs/considerations/` but has not been tested in production. SLO thresholds and governance workflows are calibrated for single-developer and small-team use. Scaling behavior under concurrent agent load is unvalidated.

**Real-time behavioral monitoring:** The harness provides forensic audit evidence (what happened, proven tamper-evidently) rather than real-time behavioral anomaly detection. MANAGE function controls are human-initiated rather than automated-response.
