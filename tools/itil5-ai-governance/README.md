# ITIL 5 AI Governance Compliance Tool

> **ITIL 5 Practice Implementation**: Product/Service Lifecycle (8 Activities), AI Governance (6C Capability Model), Service Financial Management, Change Enablement
> Based on ITIL 5 preview spec (PeopleCert, 2026); will align to final release.

## Overview

ITIL 5 marks a fundamental shift in IT service management: it extends ITSM into digital product management and embeds AI Governance as a mandatory practice — the first major framework to do so at industry scale. Where earlier versions focused on service delivery processes, ITIL 5 treats AI systems as first-class products with their own lifecycle accountability requirements, including explainability, risk classification, and audit-ready approval trails.

This tool implements four ITIL 5 practices end-to-end. The **Product/Service Lifecycle** practice is covered by eight activity checklists (Discover through Retire), each enforcing minimum guaranteed features before a gate opens. The **AI Governance** practice is implemented via risk-tier classification aligned to EU AI Act categories, plus phase-gate evaluation using the 6C Capability Model. **Service Financial Management** is addressed through outcome-based KPI templates and automated report generation. **Change Enablement** is enforced by an append-only approval log with per-entry SHA-256 hashing for tamper detection.

Regulatory coverage spans three jurisdictions simultaneously. EU AI Act Annex III/VII requirements, Japan FSA AI risk management guidelines, and US SR 11-7 model risk management standards are all encoded in the jurisdiction-aware approval workflow. When multiple jurisdictions apply to a deployment, the tool enforces the strictest applicable requirement automatically.

Within the portfolio, this tool occupies a distinct layer. The hooks tool handles pre-commit and pre-push guardrails at the developer workflow level; the ITSM governance playbooks and ROI calculator address operational metrics and business cases. This tool governs the AI product lifecycle itself — from initial discovery through decommission — and produces the audit artifacts that satisfy regulatory reviewers.

## ITIL 5 Practice Mapping

| ITIL 5 Practice | Implementation | Key Artifact |
|---|---|---|
| Product/Service Lifecycle (8 Activities) | Minimum Guaranteed Feature Catalog | `feature-gates/01-08` |
| AI Governance (6C Capability Model) | Phase gate evaluation + EU AI Act risk tiers | `phase-gate.sh` |
| Service Financial Management (Outcome-based) | Financial RACI + Outcome KPIs | `cost-template.md`, `generate-report.sh` |
| Change Enablement | Human approval audit trail | `approvals.log` |

## ITIL 5 6C AI Capability Model

| Capability | Applied In Activities |
|---|---|
| Creation | Design, Build, Improve |
| Curation | Build, Operate, Observe, Improve, Retire |
| Clarification | Discover, Design |
| Cognition | Discover, Build, Operate, Observe, Improve |
| Communication | Deploy, Operate |
| Coordination | Design, Deploy, Improve, Retire |

## Regulatory Compliance

| Jurisdiction | High-Risk AI Approval | Basis |
|---|---|---|
| JP | Director level | 金融庁AIリスク管理ガイドライン |
| US | CRO / Independent Model Risk Officer | SR 11-7 ※Financial sector |
| EU | Third-party Conformity Assessment Body | EU AI Act Art.43 + Annex VII |
| All | Human approval required at each gate | ITIL 5 Change Enablement |

**EU AI Act Risk Tiers:**

- **Prohibited** — implementation stop flag (`exit 1`)
- **High-Risk (Annex III)** — Third-party assessment + Art.12 logging required
- **Limited** — Transparency disclosure required (Art.13)
- **Minimal** — Standard gates only

## File Structure

```
tools/itil5-ai-governance/
├── feature-gates/
│   ├── 01-discover.md      # Discover activity checklist
│   ├── 02-design.md        # Design activity checklist
│   ├── 03-build.md         # Build activity checklist
│   ├── 04-deploy.md        # Deploy activity checklist
│   ├── 05-operate.md       # Operate activity checklist
│   ├── 06-observe.md       # Observe activity checklist
│   ├── 07-improve.md       # Improve activity checklist
│   └── 08-retire.md        # Retire activity checklist
├── cost-template.md        # Service Financial Management RACI + Outcome KPIs
├── approvals.log           # Append-only JSONL with SHA-256 per entry
├── phase-gate.sh           # Core gate enforcement script
├── generate-report.sh      # Financial and compliance report generator
└── README.md
```

## Usage

### Quick Start (5 minutes)

```bash
# 1. Check current gate status across all activities
bash phase-gate.sh status

# 2. Run checklist validation for a specific activity
bash phase-gate.sh check --activity build

# 3. Record an approval for a gate transition
bash phase-gate.sh approve --activity deploy --approver reviewer@example.com --jurisdiction EU

# 4. Audit the approval log for tampering
bash phase-gate.sh audit

# 5. Classify AI system risk tier by jurisdiction
bash phase-gate.sh risk-tier --jurisdiction EU

# 6. Generate compliance report with defaults
bash generate-report.sh --defaults

# 7. Generate HTML report for stakeholder distribution
bash generate-report.sh --format html
```

### Workflow

1. **New AI project** — run `risk-tier` to classify the system under each applicable jurisdiction before any design work begins.
2. **Fill checklists** — work through `feature-gates/01-discover.md` items; the gate will not open until minimum required checkboxes are marked complete.
3. **Record approvals** — run `phase-gate.sh approve` for each gate; approver email, timestamp, jurisdiction, and SHA-256 hash are written to `approvals.log`.
4. **Periodic audit** — run `phase-gate.sh audit` to verify log integrity; any hash mismatch indicates tampering and triggers an alert.
5. **Stakeholder reporting** — run `generate-report.sh` after each gate or on a scheduled cadence to produce financial and compliance summaries.

## Design Decisions

- **Append-only log**: `approvals.log` uses JSONL format with a SHA-256 hash per entry, enabling tamper detection without an external database.
- **Source of truth**: `approvals.log` is authoritative for gate status; feature-gate checkboxes are display artifacts only — they do not gate the scripts directly.
- **No external dependencies**: implementation requires only `bash`, standard POSIX tools, and `python3` (macOS built-in) — no pip installs, no npm, no Docker.
- **Jurisdiction layering**: when multiple jurisdictions apply to a single deployment, the strictest requirement across all active jurisdictions wins automatically.

---

## 日本語版

**概要**: ITIL 5の4プラクティス（製品ライフサイクル管理・AIガバナンス・サービス財務管理・変更実現）をシェルスクリプトで実装したコンプライアンス・ツール。EU AI Act / 金融庁 / SR 11-7 の多管轄対応。

**4プラクティス対応表（簡略）**:

| プラクティス | 実装 |
|---|---|
| 製品/サービスライフサイクル (8活動) | `feature-gates/01-08` チェックリスト |
| AIガバナンス (6Cモデル) | `phase-gate.sh` リスク分類 + フェーズゲート |
| サービス財務管理 | `cost-template.md` + `generate-report.sh` |
| 変更実現 | `approvals.log` 追記専用 + SHA-256 改ざん検知 |

**クイックスタート（主要3コマンド）**:

```bash
bash phase-gate.sh status                                                      # ゲート状況確認
bash phase-gate.sh risk-tier --jurisdiction EU                                 # リスク分類
bash phase-gate.sh approve --activity deploy --approver you@example.com --jurisdiction EU  # 承認記録
```

**設計上の主要決定**:

- `approvals.log` はJSONL形式・追記専用。エントリごとにSHA-256を付与し改ざんを検出可能にする
- フィーチャーゲートのチェックボックスは表示用。承認の正式記録は `approvals.log` のみが権威ソース
- 外部依存ゼロ（bash + POSIX + python3 のみ）。`pip install` / Docker 不要
- 複数管轄が同時適用の場合、最も厳しい要件を自動的に優先する
