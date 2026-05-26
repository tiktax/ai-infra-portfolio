# Project Roadmap

## Vision

To evolve from a personal AI harness (one person, one environment) into a **deployable AI governance framework** that a team or organization can adopt — with documented change management, multi-user controls, and validated ROI.

---

## Current State (as of May 2026)

| Capability | Status | Artifact |
|-----------|--------|----------|
| Security policy enforcement (9 hooks) | ✅ Complete | `examples/hooks/` |
| Cost optimization (local/cloud LLM routing) | ✅ Complete | `docs/achievements.md` |
| ITSM-aligned incident management (INC→CIP) | ✅ Complete | `examples/incidents/` |
| Audit trail (GitHub Issues + git) | ✅ Complete | `docs/ai-usage-policy-draft.md` |
| Observability (SLO monitoring, log digest) | ✅ Complete | `docs/dashboard.md` |
| LLM-Wiki / PDCA knowledge cycle | ✅ Complete | `docs/architecture.md` |
| **Hook regression testing** | ✅ Complete | `tests/hooks/` (38 test cases) |
| **Team deployment playbook** | ✅ Complete | `docs/deployment-playbook.md` |
| **ROI calculator (org scale)** | ✅ Complete | `tools/roi-calculator/` |
| **Multi-user access control** | ✅ Complete | `tools/claude-config-manager/` |
| **Custom MCP server** | ✅ Complete | `tools/governance-mcp/` |
| **ITIL 5 AI Governance Compliance Tool** | ✅ Complete | `tools/itil5-ai-governance/` |
| **Privacy law coverage (GDPR/APPI/CCPA)** | ✅ Complete | `tools/itil5-ai-governance/feature-gates/`, `privacy-law-matrix.md` |
| **Automated installation** | ✅ Complete | `install.sh` |
| **Role-based access control** | ✅ Complete | `tools/claude-config-manager/configs/`, `manage.sh` |
| **Automated onboarding pipeline** | ✅ Complete | `onboard.sh`, `generate-kb-list.sh`, `templates/` |
| **Accountability register (AI vs Human)** | ✅ Complete | `tools/itil5-ai-governance/accountability-register.md` |
| **ECDSA signing module (trustless audit)** | ✅ Complete | `tools/trustless_audit/` |
| **Approval expiry + co-approver + check-expiry** | ✅ Complete | `tools/itil5-ai-governance/phase-gate.sh` |
| **Automated post-deployment monitoring** | ✅ Complete | `tools/itil5-ai-governance/monitor.sh` |
| **Multi-Signature M-of-N** | ✅ Complete | `tools/trustless_audit/src/multisig.py` |
| **Post-Quantum Crypto (ML-DSA-65)** | ✅ Complete | `tools/trustless_audit/src/pqc_signing.py` |
| **RFC 3161 Trusted Timestamps** | ✅ Complete | `tools/trustless_audit/src/timestamp.py` |
| **WORM Storage (S3 Object Lock)** | ✅ Complete | `tools/trustless_audit/src/worm_storage.py` |
| **TRiSM Privacy coverage (40% → 75%)** | ✅ Complete | `examples/hooks/pii-guard.sh` · `tools/trustless_audit/src/audit.py` |

---

### Phase 2 — ITIL 5 AI Governance Compliance Tool ✅ Complete

**Gap filled**: AI product lifecycle governance aligned to latest ITSM standard

Implements ITIL 5 (PeopleCert, 2026) — the first ITSM standard to mandate AI Governance:

- **8-activity lifecycle** (Discover → Design → Build → Deploy → Operate → Observe → Improve → Retire) — minimum guaranteed feature catalog per activity
- **AI Governance 6C Capability Model** — phase gate evaluation mapped to each capability
- **Multi-jurisdiction compliance** — JP (金融庁), US (SR 11-7※), EU (AI Act Art.43/Annex III)
- **Append-only audit trail** — human approval log with tamper-evident sha256 hashing
- **Financial governance** — 7-role RACI matrix + outcome-based KPI reporting

> ※ SR 11-7 applies to financial sector organizations

**Artifacts**: `phase-gate.sh`, `generate-report.sh`, `feature-gates/01-08`, `cost-template.md`, `approvals.log`

---

### Phase 3 — Privacy Law Coverage (GDPR / APPI / CCPA) ✅ Complete

**Gap filled**: Personal data protection compliance across the full AI lifecycle

Current ITIL 5 tool covers data deletion at Retire phase only. This phase adds structured privacy law checkpoints to each of the 8 lifecycle activities:

| Activity | Addition |
|----------|---------|
| **01-discover** | DPIA trigger assessment (GDPR Art.35) / 要配慮個人情報分類 (APPI) / CCPA data category inventory |
| **02-design** | Privacy by Design (GDPR Art.25) / data minimization / purpose limitation |
| **03-build** | Pseudonymization / anonymization verification / CCPA-covered data identification |
| **04-deploy** | Third-party data sharing consent / DPA (Data Processing Agreement) check |
| **05-operate** | Breach notification procedure (GDPR 72h / APPI prompt notification) |

**Jurisdictions**: JP (個人情報保護法 / APPI) | EU (GDPR) | US (CCPA + sectoral)

**Artifacts**: Updates to `feature-gates/01-05.md`, addition of `privacy-law-matrix.md`

---

### Phase 3 (cont.) — Automated Installation Script ✅ Complete

**Gap filled**: Organization-wide deployment of hooks and settings is currently fully manual

Current `docs/deployment-playbook.md` requires each team member to manually copy hook files, hand-edit `settings.json`, and update path references in `worktree-guard.sh`. At 10+ people this is error-prone and unscalable.

**`install.sh` — what it automates**:

| Step | Current (manual) | Automated |
|------|-----------------|-----------|
| Copy hooks + chmod | Per-machine copy | `cp` + `chmod +x` in one command |
| Register hooks in `settings.json` | Hand-edit JSON | `jq` merge (preserves existing config) |
| Set repo path in `worktree-guard.sh` | Edit source file | Prompted input or `--repo-path` arg |
| Pre-flight check (claude/bash/python3/git/op versions) | Read table, run manually | Auto-checked with pass/fail output |
| Verify installation | Run `demo.sh` manually | Auto-run at end of install |

**What cannot be automated** (requires human / admin action):
- GitHub repository access grant
- 1Password vault access grant
- Claude Code account provisioning

**Artifacts**: `install.sh` (new), updated `docs/deployment-playbook.md` Installation section

---

### Phase 3 (cont.) — Role-based Access Control ✅ Complete

**Gap filled**: `claude-config-manager` distributes behavioral specs (CLAUDE.md) but enforces no actual access control

Current state: role configs define *guidelines* only. Nothing in `settings.json` enforces which directories, tools, or commands each role can actually use.

**What will be added to `manage.sh install --role <role>`**:

| Control | Engineer | Analyst | Manager |
|---------|----------|---------|---------|
| `permissions.allow` (writable paths) | `src/`, `tests/` | read-only | read-only |
| `permissions.deny` (blocked commands) | `rm -rf`, `git push --force` | `git push *`, `Write`, `Edit` | `Bash(*)` |
| `additionalDirectories` (readable paths) | repo root | `docs/`, `reports/` | `docs/` |
| Role change requires admin approval | — | ✓ | ✓ |

**Implementation**:
- `manage.sh install` merges role-specific `permissions` block into `~/.claude/settings.json` (via `jq`, non-destructive)
- `manage.sh verify` checks `settings.json` permissions have not been manually overridden since install
- `manage.sh audit` logs who installed which role and when (append-only, sha256-signed)
- Role escalation (e.g., analyst → engineer) requires a second approver entry in the audit log

**Artifacts**: Updated `manage.sh`, new `configs/<role>-permissions.json` per role, updated `docs/deployment-playbook.md`

---

### Phase 3 (cont.) — Automated Onboarding Pipeline ✅ Complete

**Gap filled**: New user onboarding is a series of disconnected manual steps across multiple systems

Currently, adding a new team member requires an admin to manually create accounts, grant permissions, install hooks, and share documentation — across GitHub, 1Password, Claude Code, and any internal KB. Each step is a separate action with no audit trail connecting them.

**End-to-end pipeline triggered by a single command**:

```bash
./onboard.sh --user alice@example.com --role engineer --manager bob@example.com
```

| Step | What happens | Tool |
|------|-------------|------|
| **1. Account provisioning** | GitHub org invite + team assignment | GitHub API (`gh`) |
| **2. 1Password vault access** | Add user to shared vault (prompt admin to approve) | `op` CLI |
| **3. Hook + config install** | Run `install.sh --role <role>` on target machine via SSH or send install link | `install.sh` |
| **4. Access control apply** | Merge role-specific `permissions` into `settings.json` | `manage.sh install` |
| **5. Welcome email** | Send templated email with role, links, and KB pointers | SMTP / sendmail |
| **6. KB / manual sharing** | Generate role-specific reading list from `docs/` and attach to email | `generate-kb-list.sh` |
| **7. Audit log entry** | Record provisioning event (user, role, admin, timestamp, sha256) | append-only log |

**What cannot be automated** (requires human action):
- 1Password vault approval (security boundary — admin must confirm)
- Claude Code account creation (Anthropic console — no public API)
- SSH access to target machine (unless self-service install link is used)

**Design constraints**:
- No credentials stored in script — all secrets via `op run`
- Idempotent: re-running for existing user is a no-op with warning
- `--dry-run` flag previews all actions without executing
- Works without SSH: optionally generates a self-service install URL the new user runs themselves

**Artifacts**: `onboard.sh`, `templates/welcome-email.txt`, `generate-kb-list.sh`, updated `docs/deployment-playbook.md`

---

### Phase 4 — AI Product Accountability, Approval Governance & Automated Monitoring ✅ Complete

**Gap filled**: Approvals are recorded but accountability is undefined; post-deployment monitoring is manual checklists only

Current state: `approvals.log` captures *who approved* but not *who owns* the AI product. Monitoring items in `feature-gates/05-08` are manual checkboxes with no automated execution or alerting.

#### 4a — AI Product Accountability Definition

**What's missing**: No document defines the single accountable owner per AI product, their scope of responsibility, or what triggers a re-review.

| Artifact | Content |
|----------|---------|
| `tools/itil5-ai-governance/accountability-register.md` | Per-product register: Product Owner, Risk Owner, Data Owner, Technical Owner — with scope and escalation path |
| `phase-gate.sh` update | `--owner` field added to `approve` command; stored in `approvals.log` |
| Re-review triggers documented | Model update, regulatory change, incident, or approval age > 12 months |

#### 4b — Approval Governance Enhancements

**What's missing**: Single approver per gate, no expiry, no multi-party support.

| Enhancement | Implementation |
|-------------|---------------|
| Approval expiry | `approvals.log` entries include `expires_at` (default: 12 months); `phase-gate.sh audit` flags expired entries |
| Multi-party approval | `phase-gate.sh approve --co-approver <email>` adds second sign-off for High-Risk EU AI Act activities |
| Re-approval trigger | `phase-gate.sh check-expiry` lists gates requiring renewal |

#### 4c — Automated Post-deployment Monitoring

**What's missing**: `06-observe.md` and `05-operate.md` checklists have no automated execution.

| Artifact | What it does |
|----------|-------------|
| `tools/itil5-ai-governance/monitor.sh` | Scheduled monitoring runner: reads `feature-gates/05-operate.md` + `06-observe.md`, checks evidence files exist and are recent, outputs pass/fail |
| SLO breach detection | Compares evidence file timestamps against configurable freshness thresholds (e.g., drift report must be < 7 days old) |
| Alert output | `monitor.sh --alert` exits non-zero and prints actionable summary when SLO breached |
| Cron integration | Example crontab entry for weekly automated run |

**Artifacts**: `accountability-register.md`, updated `phase-gate.sh` (`--co-approver`, `--expires-months`, `check-expiry`), new `monitor.sh` (`--alert`, `--format json`, cron-ready)

---

### Phase 5 — Advanced Trustless Infrastructure ✅ Complete

**Gap filled**: ECDSA P-256 alone is insufficient against quantum attacks, single-key compromise, clock manipulation, and local log deletion.

| Feature | Status | Artifact |
|---------|--------|---------|
| **Multi-Signature (M-of-N)** | ✅ Complete | `tools/trustless_audit/src/multisig.py` |
| **Post-Quantum Cryptography (ML-DSA-65)** | ✅ Complete | `tools/trustless_audit/src/pqc_signing.py` |
| **RFC 3161 Trusted Timestamps** | ✅ Complete | `tools/trustless_audit/src/timestamp.py` |
| **WORM Storage (AWS S3 Object Lock)** | ✅ Complete | `tools/trustless_audit/src/worm_storage.py` |
| **AI Output Signing (C2PA)** | 🔲 Future | Out of scope — not selected for Phase 5 |

**Key design decisions**:
- Multi-sig: M-of-N ECDSA — single key compromise cannot forge a valid entry
- PQC: Dual-signing (ECDSA + ML-DSA-65) for migration period; PQC signed first, ECDSA second
- RFC 3161: default TSA freetsa.org; fallback hash verification if cert check fails
- WORM: S3 COMPLIANCE mode + CloudFormation template; `generate_worm_config_example()` works without AWS

**Artifacts**: `multisig.py`, `pqc_signing.py`, `timestamp.py`, `worm_storage.py`, CLI scripts, `.env.aws.1password` template

---

### Phase 6a — TRiSM Privacy Coverage ✅ Complete

**Gap filled**: Privacy coverage was policy-layer only (40% TRiSM score). No technical enforcement existed.

| Capability | Before | After | Artifact |
|---|---|---|---|
| PII detection in AI commands | None | `pii-guard.sh` — PreToolUse hook blocking real PII in Bash + Write | `examples/hooks/pii-guard.sh` |
| PII scrubbing in audit output | None | `scrub_pii()` — display-time redaction (email/phone/card/My Number) | `tools/trustless_audit/src/audit.py` |
| DPIA governance dashboard | Checklist only | Structured tracker + consent registry + breach notification timing | LLM-Wiki `governance/PRIVACY.md` |
| Cross-border transfer compliance | Not covered | GDPR Ch.V / APPI Art.24 / CCPA comparison table | `privacy-law-matrix.md` |
| Anonymization standards | Not covered | JP 仮名加工情報 / EU pseudonymization / CCPA de-identification reconciliation | `privacy-law-matrix.md` |

**TRiSM Privacy score**: 40% → 75%

**Remaining 25% gap** (structurally out of scope for a personal project):
- Real-time consent enforcement DB (would require a separate consent service)
- Pseudonymization/tokenization engine (new data pipeline component)
- Right-to-erasure cascade across WORM-locked audit logs (conflicts with tamper-evident design by construction)

> `scrub_pii()` is display-time substitution only. It does **not** constitute anonymization under GDPR, APPI, or CCPA. Signed originals are preserved for accountability. This boundary is documented in `audit.py` docstrings and `privacy-law-matrix.md §Anonymization Standards Comparison`.

**Artifacts**: `examples/hooks/pii-guard.sh`, updated `tools/trustless_audit/src/audit.py`, updated `tools/itil5-ai-governance/privacy-law-matrix.md`, LLM-Wiki `governance/PRIVACY.md` + `raw/templates/`

---

### Phase 6b — AI Reasoning Externalization & Record

**Gap filled**: The audit trail captures *what* AI did. It does not capture *why* — the reasoning behind each decision remains internal and unrecordable.

Current state: action logs, approval records, and signed audit entries exist. But when a decision is challenged, there is no structured record of the reasoning that led to it. "The AI decided X" is not an auditable statement.

**Approach**: Force AI reasoning into structured, externalized output before action — then capture, sign, and chain that output as part of the audit record.

Three prompt-engineering techniques are combined:

| Technique | What it produces | Recordable artifact |
|---|---|---|
| **Semi-Formal Reasoning** (Meta, Apr 2026) | Premises → execution trace → conclusion, in order | "Logic certificate" — signed and hash-chained with the action entry |
| **Verbalized Confidence** | Per-claim confidence score (0–100); items below threshold trigger self-verification | Confidence manifest — flags low-certainty decisions for human review |
| **Town Hall Debate Prompting** (2025) | Multi-persona deliberation (e.g., economist / operator / critic) → vote-based conclusion | Deliberation transcript — records that alternatives were considered |

**What this adds to the audit trail**:

```
Current entry:
  action: "approved deployment of model v2.1"
  timestamp: ...
  signature: ...

Phase 6 entry:
  action: "approved deployment of model v2.1"
  reasoning_certificate:
    premises: ["model drift < 2%", "no open P0 incidents", "privacy review passed"]
    trace: ["drift within SLO → proceed", "no blockers → proceed", "compliance clear → proceed"]
    conclusion: "approve"
    confidence: 87
  deliberation_transcript: "economist: ROI positive; critic: rollback path unverified → addressed"
  timestamp: ...
  signature: ...
```

**Known limitation that remains**:
This records *stated* reasoning, not *actual* internal computation. Whether the two correspond is not verifiable with current model architectures. That boundary is explicitly documented in each Phase 6 audit entry.

**Planned artifacts**: `tools/trustless_audit/src/reasoning_capture.py`, updated `audit.py` schema, prompt templates (`templates/semiformal.md`, `templates/confidence.md`, `templates/townhall.md`)

---

### Phase 7 — End-to-End Demo, MCP Accountability Boundary, Multi-Agent Orchestration

**Gap filled**: Current demos show individual components in isolation. Three structural gaps remain unaddressed.

---

#### 7a — End-to-End Reproducible Demo with Sample Audit Log

**Gap**: The existing `demo.sh` demonstrates hook blocking in isolation. It does not show the full governance chain from block → audit entry → incident → improvement → change.

**What will be built**: A single script that walks through the complete chain:

| Step | What is shown |
|---|---|
| 1. Pre-hook interception | Secret-touching command is blocked; allowed command passes |
| 2. Signed audit entry | Block and pass events written to audit log with ECDSA signature and hash chain |
| 3. INC registration | Blocked event auto-registers as incident |
| 4. CIP proposal | Root cause analysis generates improvement proposal |
| 5. Change implementation | Policy update applied and recorded as Change entry |
| 6. Local/cloud routing | Same script routes a low-complexity call to local LLM (Gemma4) and a high-complexity call to Claude API; routing decision recorded in audit log |

**Planned artifact**: `demo-full.sh`, `samples/audit-log-annotated.jsonl` (sample log with inline commentary)

---

#### 7b — MCP Accountability Boundary

**Gap**: When an MCP server executes a tool call, the current audit trail records the action but not the accountability boundary — who instructed the MCP, which server handled it, and what the decision boundary was between the orchestrating agent and the MCP server.

**What will be built**:

- Audit schema extension: each MCP tool call entry includes `mcp_server`, `tool_name`, `instructed_by`, `decision_boundary`
- Accountability register entry: MCP servers are registered with their owner, scope, and escalation path — same format as AI product accountability in Phase 4
- Boundary definition: explicit record of what the MCP server is permitted to decide autonomously vs. what requires orchestrator approval

**Open question this addresses**:
> *"AIが判断した" という記録は、責任分解においてどう扱われるべきか*
> → MCP servers are AI-adjacent tools. Their actions require the same accountability framing.

**Planned artifact**: Updated `audit.py` schema, `tools/governance-mcp/mcp-accountability-register.md`

---

#### 7c — Sub-agent & Orchestration Support

**Gap**: All current tooling assumes a single agent. Multi-agent systems — where an orchestrator delegates to sub-agents — multiply the accountability problem: each agent acts, each produces artifacts, each makes decisions. No current mechanism links these across agents into a coherent audit trail.

**What will be built**:

- Per-agent audit log: each sub-agent writes signed entries to its own log; entries include `agent_id`, `delegated_by`, `task_scope`
- Orchestrator-level decision record: the orchestrating agent records *why* each sub-agent was selected and what scope was delegated
- Artifact provenance: each sub-agent output is hash-linked to the agent that produced it and the task it was assigned
- Cross-agent chain: sub-agent logs are hash-linked to the orchestrator log, forming a verifiable tree rather than a flat sequence

**Open questions this addresses**:
> *AIの行動量が人間の監視能力を超えたとき、何が変わるか*
> → Multi-agent orchestration is the scenario where this threshold is crossed. Each agent acts at machine speed; the audit chain must survive that volume.

> *表明された推論と実際の推論の乖離をどこまで許容するか*
> → In orchestrated systems, reasoning gaps compound across agents. Phase 6 reasoning capture applied per agent is the proposed mitigation.

**Planned artifacts**: `tools/trustless_audit/src/orchestration_audit.py`, updated `audit.py` schema, `examples/multi-agent/`

---

### Phase 8 — Individual AI & Data Sovereignty

**Gap filled**: Phases 1–7 address organizational governance of AI systems. The inverse question — *who governs the AI that governs you?* — is unaddressed. As AI increasingly mediates personal decisions (health, finance, relationships), individuals need the same governance primitives that organizations have.

**Context and positioning**: This phase applies the cryptographic and governance infrastructure built in Phases 1–7 to a new domain: AI sovereignty at the individual level. Aligned with MyData Global principles but differentiated by implementing the AI layer in code, not just principles.

**Design principles**:
- **Offline-first**: all inference runs locally — no personal data leaves the device by default
- **Individual as IdP**: the person controls their own identity, credentials, and consent decisions
- **SSI/DID foundation**: portable, verifiable identity independent of any platform
- **Data portability**: full personal AI history exportable in open formats at any time

**Technical foundations (inherited from this project)**:
| Component | Source phase | Role in Phase 8 |
|---|---|---|
| ECDSA + hash chain | Phase 5 | Personal AI decision audit trail |
| Post-quantum signing (ML-DSA-65) | Phase 5 | Future-proof identity layer |
| PII guard + display-time scrubbing | Phase 6a | Privacy enforcement at the device level |

**Legal framework**:
| Jurisdiction | Instrument | Key right addressed |
|---|---|---|
| EU | AI Act (Art. 22) + GDPR (Art. 17, 20) | Right to explanation + data portability |
| US | EO 14110 + state AI bills | Transparency, opt-out rights |
| Japan | APPI 改正 (2022) + AI事業者ガイドライン | 要配慮個人情報 + 利用停止権 |

**Planned capabilities**:
- Mobile LLM integration: Gemma3-class models run entirely on-device (technically feasible today)
- Social recovery for identity keys: M-of-N key recovery without any central authority
- SSI/DID credential issuance and verification
- Personal AI audit log: portable, cryptographically signed, user-owned

**Design constraints**:
- UX form factor is TBD — smartphones are the current target, but the architecture must not assume them; the form factor the era chooses may differ
- Japan-specific legal implementation is the primary barrier; EU/US frameworks are more mature
- Differentiation from MyData Global: this project implements the AI layer — MyData defines principles, this project writes the code

**Separate project**: See [own-your-ai](https://github.com/tiktax/own-your-ai)

---

## Completed Projects

### P1 — AI Deployment Playbook ✅ Complete
**Gap addressed**: Team deployment, change management

A runbook for deploying this harness to a team of 10+. Covers CLAUDE.md distribution strategy, hook management across machines, onboarding procedures, and resistance mitigation.

**Artifact**: [`docs/deployment-playbook.md`](docs/deployment-playbook.md)

---

### P1 — Hook Test Suite ✅ Complete
**Gap addressed**: Testing, quality assurance

Automated regression tests for all 9 security hooks. Each hook gets test cases for: expected blocks, expected passes, edge cases, and bypass attempts.

**Artifact**: [`tests/hooks/`](tests/hooks/) — 38 test cases, CI-integrated

---

### P2 — ROI Calculator ✅ Complete
**Gap addressed**: Business case at organizational scale

A tool that takes org size, AI usage patterns, and security incident rates as input, and outputs projected cost savings and risk reduction.

**Artifact**: [`tools/roi-calculator/`](tools/roi-calculator/)

---

### P2 — Multi-user CLAUDE.md Manager ✅ Complete
**Gap addressed**: Access control, role-based AI behavior

A system for distributing and versioning role-specific CLAUDE.md files across a team. Different roles (engineer, analyst, manager) get different behavioral specs and permission levels.

**Artifact**: [`tools/claude-config-manager/`](tools/claude-config-manager/)

---

### P3 — Custom MCP Server ✅ Complete
**Gap addressed**: MCP design and implementation experience

Custom MCP server connecting governance data (hooks, role config, incidents, SLO metrics) to Claude Code.

**Artifact**: [`tools/governance-mcp/`](tools/governance-mcp/)

---

## Timeline (All Complete)

```
Mar–Apr 2026              May 2026                  May 2026
│                         │                         │
▼                         ▼                         ▼
Hook Test Suite ✅        ROI Calculator ✅         ITIL 5 AI Governance ✅
AI Deployment Playbook ✅ Multi-user CLAUDE.md ✅  Privacy Law Coverage ✅
                          Custom MCP Server ✅      install.sh ✅
                                                    Access Control ✅
                                                    Onboarding Pipeline ✅
```

---

---

## 日本語版

## ビジョン

個人用AIハーネス（一人・一環境）から、チームや組織が導入できる**デプロイ可能なAIガバナンスフレームワーク**へ進化させる。変更管理の文書化・マルチユーザー制御・検証済みROIを備えた状態を目指す。

---

## 現状（2026年5月時点）

| 機能 | 状態 |
|------|------|
| セキュリティポリシー強制（9種hook）| ✅ 完了 | `examples/hooks/` |
| コスト最適化（ローカル/クラウドLLMルーティング）| ✅ 完了 | `docs/achievements.md` |
| ITSM準拠インシデント管理（INC→CIP）| ✅ 完了 | `examples/incidents/` |
| 監査証跡（GitHub Issues + git）| ✅ 完了 | `docs/ai-usage-policy-draft.md` |
| 可観測性（SLOモニタリング・ログダイジェスト）| ✅ 完了 | `docs/dashboard.md` |
| LLM-Wiki / PDCAナレッジサイクル | ✅ 完了 | `docs/architecture.md` |
| **hookリグレッションテスト** | ✅ 完了 | `tests/hooks/`（38件）|
| **チーム展開プレイブック** | ✅ 完了 | `docs/deployment-playbook.md` |
| **ROI計算ツール（組織規模）** | ✅ 完了 | `tools/roi-calculator/` |
| **マルチユーザーアクセス制御** | ✅ 完了 | `tools/claude-config-manager/` |
| **カスタムMCPサーバー** | ✅ 完了 | `tools/governance-mcp/` |
| **ITIL 5 AIガバナンス準拠ツール** | ✅ 完了 | `tools/itil5-ai-governance/` |
| **各国個人情報保護法対応（GDPR/APPI/CCPA）** | ✅ 完了 | `feature-gates/01-05`, `privacy-law-matrix.md` |
| **インストール自動化** | ✅ 完了 | `install.sh` |
| **ロールベースアクセス制御** | ✅ 完了 | `configs/*-permissions.json`, `manage.sh` |
| **オンボーディング自動化パイプライン** | ✅ 完了 | `onboard.sh`, `generate-kb-list.sh`, `templates/` |
| **説明責任レジスター（AI vs 人間）** | ✅ 完了 | `tools/itil5-ai-governance/accountability-register.md` |
| **ECDSA署名モジュール（trustless audit）** | ✅ 完了 | `tools/trustless_audit/` |

---

### Phase 2 — ITIL 5 AIガバナンス準拠ツール ✅ 完了

**埋めるギャップ**: 最新ITSMフレームワーク準拠のAIプロダクトライフサイクルガバナンス

ITIL 5（2026年PeopleCert）は、ITSMとしてAI Governanceを初めて必須要件とした。

- **8アクティビティライフサイクル**: 各フェーズの最低保証機能カタログ
- **6C Capability Model**: 各能力軸への評価マッピング
- **多管轄対応**: JP・US・EU の高リスクAI承認フロー
- **改ざん検知**: sha256ハッシュ付きappend-only承認ログ
- **財務ガバナンス**: 7ロールRACIマトリクス + アウトカムKPIレポート

---

### Phase 3 — 各国個人情報保護法対応（GDPR / 個人情報保護法 / CCPA）✅ 完了

**埋めるギャップ**: AIライフサイクル全フェーズへのプライバシー法準拠チェックポイント追加

現在のITIL 5ツールはRetireフェーズのデータ削除（GDPR Art.17 / 個人情報保護法）のみ対応。本フェーズで8アクティビティ全体に構造的なプライバシー法チェックを追加する。

| アクティビティ | 追加内容 |
|------------|--------|
| **01-discover** | DPIAトリガー評価（GDPR Art.35）/ 要配慮個人情報分類（個人情報保護法）/ CCPAデータカテゴリ棚卸し |
| **02-design** | Privacy by Design（GDPR Art.25）/ データ最小化 / 目的外利用禁止設計 |
| **03-build** | 仮名化・匿名化の実施確認 / CCPA対象データの識別 |
| **04-deploy** | 第三者提供同意確認 / DPA（データ処理委託契約）チェック |
| **05-operate** | 漏洩時通知手順（GDPR 72時間 / 個人情報保護法 速やかに） |

**対応管轄**: JP（個人情報保護法 / APPI）| EU（GDPR）| US（CCPA + セクトラル法）

**成果物**: `feature-gates/01-05.md` 更新 + `privacy-law-matrix.md` 新規追加

---

### Phase 3（続き）— インストール自動化スクリプト ✅ 完了

**埋めるギャップ**: 組織展開時のhook・設定登録がすべて手作業

現状の `docs/deployment-playbook.md` では、hook ファイルのコピー・`settings.json` の手編集・`worktree-guard.sh` のパス書き換えを各自で実施する必要がある。10名以上では手順ミスが発生しやすくスケールしない。

**`install.sh` が自動化する作業**:

| 手順 | 現状（手動） | 自動化後 |
|-----|-----------|--------|
| hookコピー + 実行権限付与 | 各自で実施 | 1コマンドで完結 |
| `settings.json` へのhook登録 | JSON手編集（構文ミスリスク） | `jq` マージ（既存設定を保持） |
| `worktree-guard.sh` のリポパス設定 | ファイル直接編集 | 対話入力 or `--repo-path` 引数 |
| 前提ツールのバージョン確認 | 表を見て手動実行 | 自動チェック + 合否表示 |
| インストール後の動作確認 | `demo.sh` を手動実行 | インストール完了時に自動実行 |

**自動化できない作業**（管理者・人間が必要）:
- GitHubリポジトリのアクセス権付与
- 1Passwordボルトのアクセス権付与
- Claude Codeアカウントの発行

**成果物**: `install.sh`（新規）、`docs/deployment-playbook.md` Installation セクション更新

---

### Phase 3（続き）— ロールベースアクセス制御 ✅ 完了

**埋めるギャップ**: `claude-config-manager` は行動指示書（CLAUDE.md）を配布するだけで、実際のアクセス制御を強制していない

現状のロール設定はガイドラインの文書に過ぎず、`settings.json` の `permissions` によるディレクトリ・ツール・コマンドの実際の制限は存在しない。

**`manage.sh install --role <role>` に追加するアクセス制御**:

| 制御項目 | Engineer | Analyst | Manager |
|---------|----------|---------|---------|
| `permissions.allow`（書込可能パス）| `src/`, `tests/` | 読み取り専用 | 読み取り専用 |
| `permissions.deny`（ブロックコマンド）| `rm -rf`, force push | `git push *`, `Write`, `Edit` | `Bash(*)` |
| `additionalDirectories`（読取可能パス）| リポジトリルート | `docs/`, `reports/` | `docs/` |
| ロール変更時の承認要件 | — | 管理者承認必須 | 管理者承認必須 |

**実装方針**:
- `manage.sh install` がロール別 `permissions` ブロックを `~/.claude/settings.json` に `jq` マージ（既存設定を保持）
- `manage.sh verify` でインストール後の `settings.json` 改ざんを検知
- `manage.sh audit` でロール付与履歴をsha256署名付きappend-onlyログに記録
- ロール昇格（例: analyst → engineer）には第二承認者のログエントリが必要

**成果物**: `manage.sh` 更新、ロール別 `configs/<role>-permissions.json` 新規追加、`docs/deployment-playbook.md` 更新

---

### Phase 3（続き）— オンボーディング自動化パイプライン ✅ 完了

**埋めるギャップ**: 新規ユーザー追加時の作業が複数システムにまたがる手作業の連鎖になっている

現状はGitHub・1Password・Claude Code・社内KBそれぞれに対して管理者が個別に操作し、それらをつなぐ監査証跡も存在しない。

**1コマンドで一気通貫に実行されるパイプライン**:

```bash
./onboard.sh --user alice@example.com --role engineer --manager bob@example.com
```

| ステップ | 実行内容 | 手段 |
|---------|---------|------|
| **1. アカウントプロビジョニング** | GitHubオーガニゼーション招待 + チーム追加 | GitHub API (`gh`) |
| **2. 1Passwordボルトアクセス付与** | 共有ボルトへのユーザー追加（管理者承認をプロンプト） | `op` CLI |
| **3. hook + config インストール** | `install.sh --role <role>` をSSH経由またはセルフサービスリンクで実行 | `install.sh` |
| **4. アクセス制御適用** | ロール別 `permissions` を `settings.json` にマージ | `manage.sh install` |
| **5. ウェルカムメール送信** | ロール・リンク・KB参照先を含むテンプレートメール送信 | SMTP / sendmail |
| **6. KB・マニュアル共有** | `docs/` からロール別推奨ドキュメントリストを生成しメールに添付 | `generate-kb-list.sh` |
| **7. 監査ログ記録** | プロビジョニングイベント（ユーザー・ロール・管理者・日時・sha256）をログに追記 | append-only log |

**自動化できない作業**（人間・管理者が必要）:
- 1Passwordボルト承認（セキュリティ境界—管理者の確認必須）
- Claude Codeアカウント発行（Anthropicコンソール—公開APIなし）
- ターゲットマシンへのSSHアクセス（セルフサービスインストールリンクで代替可能）

**設計上の制約**:
- スクリプト内にcredentialを保持しない—すべて `op run` 経由
- 冪等性確保: 既存ユーザーへの再実行は警告を出してno-op
- `--dry-run` フラグで実行前に全アクションをプレビュー可能
- SSH不要モード: 新規ユーザー自身が実行するセルフサービスインストールURLを生成

**成果物**: `onboard.sh`、`templates/welcome-email.txt`、`generate-kb-list.sh`、`docs/deployment-playbook.md` 更新

---

### Phase 4 — AIプロダクト説明責任・承認ガバナンス・自動モニタリング ✅ 完了

**埋めるギャップ**: 承認は記録されているが責任者が未定義; デプロイ後のモニタリングが手動チェックリストのみ

現状の `approvals.log` は「誰が承認したか」を記録するが、「誰がそのAIプロダクトに説明責任を持つか」が定義されていない。`feature-gates/05-08` のモニタリング項目は手動☐であり、自動実行・アラートの仕組みがない。

#### 4a — AIプロダクト説明責任の定義

**不足しているもの**: プロダクトごとに最終説明責任者・責任範囲・再評価トリガーを定めるドキュメントがない。

| 成果物 | 内容 |
|--------|------|
| `accountability-register.md` | プロダクト別台帳: プロダクトオーナー・リスクオーナー・データオーナー・技術オーナー（範囲・エスカレーション経路付き） |
| `phase-gate.sh` 更新 | `approve` コマンドに `--owner` フィールド追加; `approvals.log` に記録 |
| 再評価トリガーの定義 | モデル更新・規制改正・インシデント発生・承認から12ヶ月経過 |

#### 4b — 承認ガバナンスの強化

**不足しているもの**: 承認者が1名のみ、有効期限なし、複数承認未対応。

| 強化内容 | 実装方法 |
|---------|---------|
| 承認有効期限 | `approvals.log` に `expires_at`（デフォルト12ヶ月）を追加; `phase-gate.sh audit` が期限切れをフラグ |
| 複数承認（マルチパーティ） | EU AI Act高リスク活動に `phase-gate.sh approve --co-approver <email>` で第二承認を追加 |
| 再承認トリガー | `phase-gate.sh check-expiry` で更新が必要なゲートを一覧表示 |

#### 4c — デプロイ後自動モニタリング

**不足しているもの**: `06-observe.md` / `05-operate.md` のチェックリストに自動実行機構がない。

| 成果物 | 機能 |
|--------|------|
| `monitor.sh` | 定期モニタリング実行: evidenceファイルの存在・更新日時を確認、合否を出力 |
| SLO違反検知 | evidenceファイルのタイムスタンプを設定可能な鮮度閾値（例: ドリフトレポートは7日以内）と比較 |
| アラート出力 | `monitor.sh --alert` はSLO違反時にnon-zeroで終了し、対処が必要な項目を出力 |
| cron連携 | 週次自動実行のcrontabサンプルを同梱 |

**成果物**: `accountability-register.md`、`phase-gate.sh` 更新、`monitor.sh` 新規追加

---

### Phase 6 — AI推論プロセスの外部化と記録

**埋めるギャップ**: 監査証跡は「何をしたか」を記録する。「なぜそう判断したか」は記録されていない。

現状: アクションログ・承認記録・署名付き監査エントリは存在する。しかし判断が問われたとき、その根拠となった推論プロセスの構造化された記録がない。「AIがXと判断した」は監査可能な証跡ではない。

**アプローチ**: AIの推論を、行動の前に構造化された外部出力として強制し、その出力を監査レコードの一部として署名・ハッシュチェーンする。

3つのプロンプト技術を組み合わせる:

| 技術 | 生成される成果物 | 記録可能な監査成果物 |
|---|---|---|
| **Semi-Formal Reasoning**（準形式推論）Meta, 2026年4月 | 前提→実行パストレース→結論の順を強制 | 「論理証明書」— アクションエントリと署名・ハッシュチェーン |
| **Verbalized Confidence**（確信度の言語化） | 主張ごとの確信度（0〜100）; 閾値未満は自己再検証を強制 | 確信度マニフェスト — 低確信度の判断に人間レビューフラグ |
| **Town Hall Debate Prompting**（多視点討論、2025年） | 複数ペルソナによる討論（例: 経済学者/現場責任者/批判的投資家）→ 投票で結論 | 討論トランスクリプト — 代替案が検討されたことを記録 |

**監査証跡に加わるもの**:

```
現在のエントリ:
  action: "model v2.1 のデプロイを承認"
  timestamp: ...
  signature: ...

Phase 6 エントリ:
  action: "model v2.1 のデプロイを承認"
  reasoning_certificate:
    premises: ["モデルドリフト < 2%", "P0インシデントなし", "プライバシーレビュー通過"]
    trace: ["ドリフトSLO内 → 続行", "ブロッカーなし → 続行", "コンプライアンスクリア → 続行"]
    conclusion: "承認"
    confidence: 87
  deliberation_transcript: "経済学者: ROI正。批判者: ロールバック経路未検証 → 対処済み"
  timestamp: ...
  signature: ...
```

**残る限界**:
これは「表明された推論」を記録する。「実際の内部計算」ではない。
両者が一致するかの検証は、現行モデルアーキテクチャでは不可能だ。
この境界はPhase 6の各監査エントリに明示的に記録される。

**予定成果物**: `tools/trustless_audit/src/reasoning_capture.py`、`audit.py` スキーマ更新、プロンプトテンプレート（`templates/semiformal.md`、`templates/confidence.md`、`templates/townhall.md`）

---

### Phase 7 — エンドツーエンドデモ・MCP責任分界点・マルチエージェント対応

**埋めるギャップ**: 現在のデモは各コンポーネントを個別に示すのみ。3つの構造的なギャップが未対応のまま残っている。

---

#### 7a — エンドツーエンド再現デモ + サンプル監査ログ一式

**ギャップ**: 既存の `demo.sh` はフック遮断のみを示す。ブロック→監査エントリ→インシデント→改善→変更という一連のガバナンスチェーンを見せていない。

**構築するもの**: 一連の流れを1つのスクリプトで通す:

| ステップ | 何を示すか |
|---|---|
| 1. 事前フック遮断 | 秘密情報に触れるコマンドをブロック; 許可コマンドは通過 |
| 2. 署名付き監査エントリ | ブロック・通過の両イベントをECDSA署名＋ハッシュチェーン付きで記録 |
| 3. INC登録 | ブロックイベントが自動的にインシデントとして登録される |
| 4. CIP提案 | 根本原因分析から改善提案が生成される |
| 5. Change反映 | ポリシー更新が適用され、Changeエントリとして記録される |
| 6. ローカル/クラウド自動ルーティング | 同一スクリプト内で低複雑度コールをローカルLLM（Gemma4）、高複雑度コールをClaude APIへルーティング; 判断を監査ログに記録 |

**予定成果物**: `demo-full.sh`、`samples/audit-log-annotated.jsonl`（注釈付きサンプルログ）

---

#### 7b — MCP責任分界点

**ギャップ**: MCPサーバーがツールコールを実行するとき、現在の監査証跡はアクションを記録するが責任の境界を記録しない——誰がMCPに指示したか、どのサーバーが処理したか、オーケストレーターとMCPサーバーの間の判断境界はどこかが残らない。

**構築するもの**:

- 監査スキーマ拡張: MCPツールコールのエントリに `mcp_server`、`tool_name`、`instructed_by`、`decision_boundary` を追加
- 説明責任レジスター: MCPサーバーをオーナー・スコープ・エスカレーション経路付きで登録（Phase 4の形式に準拠）
- 境界定義: MCPサーバーが自律的に判断してよい範囲と、オーケストレーター承認が必要な範囲の明示的な記録

**答える開かれた問い**:
> 「AIが判断した」という記録は、責任分解においてどう扱われるべきか
> → MCPサーバーはAI隣接ツールだ。その行動は同じ説明責任フレームを必要とする。

**予定成果物**: `audit.py` スキーマ更新、`tools/governance-mcp/mcp-accountability-register.md`

---

#### 7c — サブエージェント・オーケストレーション対応

**ギャップ**: 現在のすべてのツールは単一エージェントを前提とする。オーケストレーターがサブエージェントに委譲するマルチエージェントシステムでは、各エージェントが行動し、成果物を生成し、判断を下す。これらを横断する一貫した監査証跡を作る仕組みが存在しない。

**構築するもの**:

- エージェント別監査ログ: 各サブエージェントが `agent_id`、`delegated_by`、`task_scope` を含む署名付きエントリを自身のログに記録
- オーケストレーターレベル判断記録: なぜそのサブエージェントを選んだか、どのスコープを委譲したかを記録
- 成果物の来歴: サブエージェントの出力を、生成したエージェントと割り当てられたタスクにハッシュリンク
- クロスエージェントチェーン: サブエージェントログをオーケストレーターログにハッシュリンクし、フラットな連鎖ではなく検証可能なツリーを形成

**答える開かれた問い**:
> AIの行動量が人間の監視能力を超えたとき、何が変わるか
> → マルチエージェントオーケストレーションは、その閾値を越える典型的なシナリオだ。

> 表明された推論と実際の推論の乖離をどこまで許容するか
> → オーケストレーションシステムでは、推論のギャップがエージェント間で累積する。Phase 6の推論キャプチャをエージェントごとに適用することが提案される緩和策だ。

**予定成果物**: `tools/trustless_audit/src/orchestration_audit.py`、`audit.py` スキーマ更新、`examples/multi-agent/`

---

### Phase 8 — 個人AIとデータ主権（Own Your AI）

**埋めるギャップ**: Phase 1〜7 は組織によるAIシステムのガバナンスを扱う。裏側の問いは未対応のままだ——*あなたを管理するAIを、誰が管理するのか？* AIが個人の意思決定（健康・金融・人間関係）を仲介するようになるにつれ、個人も組織が持つのと同じガバナンス基盤を必要とする。

**背景と位置づけ**: このフェーズは Phase 1〜7 で構築した暗号・ガバナンス基盤を新たな領域——個人レベルのAI主権——に適用する。MyData Globalの原則に沿いつつ、原則にとどまらずAIレイヤーをコードとして実装する点が差別化ポイント。

**設計原則**:
- **オフラインファースト**: 推論はすべてローカルで完結——個人データはデフォルトでデバイス外に送出しない
- **個人がIdP**: ユーザー自身がアイデンティティ・認証情報・同意判断を管理する
- **SSI/DID基盤**: 特定プラットフォームに依存しない可搬・検証可能なアイデンティティ
- **データポータビリティ**: 個人のAI履歴はいつでもオープン形式でエクスポート可能

**技術的基盤（本プロジェクトからの継承）**:
| コンポーネント | 継承元フェーズ | Phase 8 での役割 |
|---|---|---|
| ECDSA + ハッシュチェーン | Phase 5 | 個人のAI判断に対する監査証跡 |
| ポスト量子署名（ML-DSA-65）| Phase 5 | 将来対応のアイデンティティ基盤 |
| PIIガード + 表示時スクラブ | Phase 6a | デバイスレベルのプライバシー強制 |

**法的フレームワーク**:
| 管轄 | 適用法令 | 対応する権利 |
|---|---|---|
| EU | AI Act（第22条）+ GDPR（第17・20条）| 説明を受ける権利 + データポータビリティ権 |
| 米国 | EO 14110 + 各州AIビル | 透明性・オプトアウト権 |
| 日本 | 改正個人情報保護法（2022）+ AI事業者ガイドライン | 要配慮個人情報 + 利用停止権 |

**計画する主要機能**:
- モバイルLLM統合: Gemma3クラスのモデルがオンデバイスで完全動作（現時点で技術的に実現可能）
- アイデンティティキーのソーシャルリカバリー: 中央集権的権限なしのM-of-N鍵回復
- SSI/DIDクレデンシャル発行・検証
- 個人AI監査ログ: 可搬・署名済み・ユーザー所有のAI判断記録

**設計上の制約**:
- UXの形態は未定——現時点ではスマートフォンが想定対象だが、時代が決めるUX形態を前提としないアーキテクチャとする
- 日本の法的実装が主要なブロッカー; EU/USフレームワークはより成熟している
- MyData Globalとの差別化: 本プロジェクトはAIレイヤーを実装する——MyDataは原則を定義するがコードを書かない

**別プロジェクト**: [own-your-ai](https://github.com/tiktax/own-your-ai) を参照

---

### Phase 5 — 高度なTrustlessインフラストラクチャ ✅ 完了

**埋めるギャップ**: ECDSA P-256単独では量子コンピューター・単一鍵漏洩・時刻偽装・ローカルログ削除に対して不十分。

| 機能 | 状態 | 成果物 |
|------|------|-------|
| **マルチシグネータ（M-of-N）** | ✅ 完了 | `tools/trustless_audit/src/multisig.py` |
| **ポスト量子暗号（ML-DSA-65）** | ✅ 完了 | `tools/trustless_audit/src/pqc_signing.py` |
| **RFC 3161 信頼済みタイムスタンプ** | ✅ 完了 | `tools/trustless_audit/src/timestamp.py` |
| **WORMストレージ（AWS S3 Object Lock）** | ✅ 完了 | `tools/trustless_audit/src/worm_storage.py` |
| **AI出力署名（C2PA）** | 🔲 将来 | 今回スコープ外 |

**主要な設計判断**:
- マルチシグ: M-of-N ECDSA — 単一鍵漏洩では有効なエントリを偽造不可
- PQC: 二重署名（ECDSA + ML-DSA-65）で移行期間を担保。**PQC署名→ECDSA署名の順序必須**
- RFC 3161: デフォルトTSA freetsa.org、証明書検証失敗時はハッシュ一致でフォールバック
- WORM: S3 COMPLIANCEモード + CloudFormationテンプレート（AWSなしでもconfig例を生成可）

---

### Phase 6a — TRiSM Privacy カバレッジ ✅ 完了

**埋めるギャップ**: Privacy 対応がポリシー文書層のみ（TRiSMスコア 40%）。技術的強制ゼロ。

| 機能 | 変更前 | 変更後 | 成果物 |
|---|---|---|---|
| AIコマンドのPII検出 | なし | `pii-guard.sh` — Bash/Writeの実PIIパターンをブロック | `examples/hooks/pii-guard.sh` |
| 監査出力のPIIスクラブ | なし | `scrub_pii()` — 表示時マスク（メール/電話/カード/マイナンバー） | `tools/trustless_audit/src/audit.py` |
| DPIAガバナンス台帳 | チェックリストのみ | トラッカー + 同意台帳 + 漏洩通知タイミング | LLM-Wiki `governance/PRIVACY.md` |
| クロスボーダー転送規定 | 未対応 | GDPR第5章 / APPI第24条 / CCPA 比較表 | `privacy-law-matrix.md` |
| 匿名化基準の差分 | 未対応 | JP仮名加工情報 / EU擬名化 / CCPA de-identification | `privacy-law-matrix.md` |

**TRiSM Privacy スコア**: 40% → 75%

**残存する25%のギャップ**（個人プロジェクト規模では構造的に対応不可）:
- リアルタイム同意強制DB（別サービス規模）
- 仮名化/トークン化エンジン（新規データパイプライン）
- WORM保存済み監査ログへの消去権対応（改ざん耐性設計と原理的に競合）

**成果物**: `examples/hooks/pii-guard.sh`、更新済み `audit.py`、更新済み `privacy-law-matrix.md`、LLM-Wiki `governance/PRIVACY.md`

---

## 完了済みプロジェクト

### P1 — AI展開プレイブック ✅ 完了
**埋めるギャップ**: チーム展開・変更管理

10名以上のチームへのハーネス展開Runbook。CLAUDE.md配布戦略・複数端末でのhook管理・オンボーディング手順・抵抗への対処法を含む。

**成果物**: [`docs/deployment-playbook.md`](docs/deployment-playbook.md)

---

### P1 — hookテストスイート ✅ 完了
**埋めるギャップ**: テスト・品質保証

9種全hookの自動リグレッションテスト（38件）。CI統合済み。

**成果物**: [`tests/hooks/`](tests/hooks/)

---

### P2 — ROI計算ツール ✅ 完了
**埋めるギャップ**: 組織規模でのビジネスケース

組織規模・AI利用パターン・セキュリティインシデント発生率を入力として、コスト削減効果とリスク低減を算出するツール。

**成果物**: [`tools/roi-calculator/`](tools/roi-calculator/)

---

### P2 — マルチユーザーCLAUDE.mdマネージャー ✅ 完了
**埋めるギャップ**: アクセス制御・ロールベースのAI行動制御

ロール別のCLAUDE.mdをチームに配布・バージョン管理するシステム。

**成果物**: [`tools/claude-config-manager/`](tools/claude-config-manager/)

---

### P3 — カスタムMCPサーバー ✅ 完了
**埋めるギャップ**: MCP設計・実装経験

ガバナンスデータ（hook・ロール設定・インシデント・SLOメトリクス）をClaude Codeに接続するカスタムMCPサーバー。

**成果物**: [`tools/governance-mcp/`](tools/governance-mcp/)
