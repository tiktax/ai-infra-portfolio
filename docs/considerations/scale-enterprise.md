# Deployment Considerations: Enterprise (500–5,000 people)

> **Disclaimer**: This document provides a general framework. Specific regulatory
> or security requirements should be verified with qualified professionals.

> **Builds on**: [scale-smb.md](scale-smb.md) — all SMB considerations apply.
> This document covers what changes or is added at enterprise scale.

**Scale**: 500–5,000 people
**Typical profile**: Dedicated IT/security team, ITSM tooling in place, formal change management
**Time to deploy**: 3–6 months

---

## 1. Portfolio Fit — What Works As-Is

| Artifact | Fit | Notes |
|----------|-----|-------|
| `examples/hooks/` | ✅ Direct | Core hook logic is reusable |
| `tests/hooks/run-tests.sh` | ✅ Direct | Integrate into enterprise CI/CD |
| `docs/ai-usage-policy-draft.md` | ⚠️ Partial | Needs legal, compliance, and CISO review |
| `tools/claude-config-manager/` | ⚠️ Partial | Role taxonomy needs expansion (5–10 roles) |
| `tools/roi-calculator/` | ⚠️ Partial | Adapt assumptions; present to CIO |
| `docs/deployment-playbook.md` | ⚠️ Partial | Phases apply; timelines extend significantly |
| `tools/governance-mcp/` | ✅ Direct | Extend with enterprise tool integrations |

---

## 2. What Needs Adaptation

**Role taxonomy**: 3 roles become 5–10.
Engineering sub-roles (junior/senior/lead), plus compliance officer, data analyst, external contractor.

**ITSM integration**: Replace GitHub Issues with existing enterprise ITSM (ServiceNow, Jira Service Management).
The INC→CIP cycle maps directly — only the tooling changes.

**Hook distribution**: MDM (Jamf/Intune/SCCM) replaces manual install.
Package hooks as a managed configuration profile deployed via endpoint management.

**Audit logging**: Hook outputs need to flow into the enterprise SIEM (Splunk, QRadar, Microsoft Sentinel).
Add a PostToolUse hook that ships structured JSON to syslog or a log aggregator.

**Change management**: At this scale, a CAB (Change Advisory Board) process applies.
Each new hook version or CLAUDE.md update needs a formal change record.

**AI policy**: Needs sign-off from CISO, General Counsel, and department heads.
Budget 4–8 weeks for the approval cycle alone.

---

## 3. What's Missing at This Scale

| Gap | Priority | Recommended Action |
|-----|----------|--------------------|
| SIEM integration | High | Build PostToolUse hook → syslog → SIEM pipeline |
| MDM-based deployment | High | Package as Jamf/Intune profile |
| Expanded role taxonomy | High | Design 5–10 roles with HR and department leads |
| Formal change management | High | Register hook updates in CAB process |
| Third-party security audit | Medium | Penetration test the hook system |
| AI model risk assessment | Medium | Document Anthropic as a third-party AI vendor |
| Employee training program | High | Mandatory e-learning (30–60 min) for all users |
| Data classification integration | High | Hook rules must align with existing DLP policies |

---

## 4. Deployment Timeline

```
Month 1–2 (Governance):
  CISO + Legal review of ai-usage-policy-draft.md
  Vendor risk assessment of Anthropic
  Role taxonomy design with HR

Month 3 (Pilot):
  50–100 engineers in sandbox environment
  SIEM integration prototype
  False positive tuning

Month 4 (Infrastructure):
  MDM packaging and testing
  ITSM (ServiceNow) integration for incident tracking
  Employee training module development

Month 5–6 (Rollout):
  Engineering department (all)
  Analyst and manager roles
  First formal SLO review with CISO
```

---

## 5. Approval Chain

```
IT Manager → CISO → CIO → General Counsel (for policy)
                         → CAB (for each hook version update)
```

---

## 6. Key Risks at This Scale

| Risk | Mitigation |
|------|-----------|
| Shadow AI usage bypasses hooks | DLP integration; network-level monitoring |
| Hook updates blocked by CAB process | Pre-approve a "fast track" for security patches |
| SIEM log volume from hook events | Filter to anomalous events only; set retention policy |
| Role proliferation makes CLAUDE.md unmanageable | Strict versioning; quarterly role review |
| Legal blocks cloud AI use entirely | Prepare data residency and DPA documentation early |

---

## 7. Honest Assessment

**50% directly usable; 50% requires enterprise integration work.**

The hook logic, policy framework, and ITSM cycle translate well.
The infrastructure work (SIEM, MDM, ServiceNow) is non-trivial and requires
dedicated engineering time (estimate: 2–4 weeks of engineering effort beyond the portfolio).

---

---

## 日本語版

**対象規模**: 500〜5,000名 | **展開期間**: 3〜6ヶ月

> **前提**: [scale-smb.md](scale-smb.md)の内容に加えて、以下が変わる・追加される。

### ポートフォリオの適合度

hookロジック・ポリシーフレームワーク・ITSMサイクルはそのまま転用可能。インフラ統合（SIEM・MDM・ServiceNow）は新規構築が必要。

### 主要な適合作業

| 項目 | 内容 |
|------|------|
| ロール拡張 | 3種 → 5〜10種（職位・職能別） |
| ITSM統合 | GitHub Issues → ServiceNow |
| hookログ | SIEM（Splunk等）への転送設定 |
| 配布 | MDM（Jamf/Intune）経由での一括展開 |
| 変更管理 | hook更新ごとにCAB承認プロセス |

### 不足しているもの（優先度高）

- SIEMへの監査ログ連携
- MDMパッケージング
- 第三者セキュリティ監査
- 全従業員向けeラーニング（30〜60分）

### 正直な評価

**50%がそのまま使える。残り50%はエンタープライズ統合作業。**
ITマネージャーが主導し、インフラエンジニア1〜2名の支援を得れば3〜6ヶ月で展開可能。
