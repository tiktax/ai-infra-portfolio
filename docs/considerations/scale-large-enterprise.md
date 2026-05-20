# Deployment Considerations: Large Enterprise (5,000–30,000 people)

> **Disclaimer**: This document provides a general framework. Specific regulatory
> or security requirements should be verified with qualified professionals.

> **Builds on**: [scale-enterprise.md](scale-enterprise.md) — all enterprise considerations apply.
> This document covers what changes or is added at large enterprise scale.

**Scale**: 5,000–30,000 people
**Typical profile**: Dedicated AI/data governance team, mature ITSM, multiple business units, global footprint
**Time to deploy**: 12–18 months

---

## 1. Portfolio Fit — What Works As-Is

At this scale, the portfolio serves primarily as a **reference architecture** rather than a deployable system. The concepts are sound; the implementation artifacts need significant adaptation.

| Artifact | Fit | Role at this scale |
|----------|-----|--------------------|
| `examples/hooks/` | ⚠️ Reference | Hook logic is reusable; packaging and distribution is enterprise-grade |
| `docs/ai-usage-policy-draft.md` | ⚠️ Reference | Starting point for formal AI governance policy |
| `tools/claude-config-manager/` | ⚠️ Reference | Role taxonomy concept; implementation moves to IAM/LDAP |
| `docs/architecture.md` | ✅ Reference | 5-layer stack model is directly presentable to architecture board |
| `tools/roi-calculator/` | ⚠️ Adapt | Scale inputs to 5,000+ users; present to CFO |
| `tools/governance-mcp/` | ⚠️ Extend | Add enterprise system integrations (ServiceNow, Splunk, AD) |

---

## 2. What Needs Adaptation

**Identity & Access Management**: CLAUDE.md roles must integrate with corporate IAM.
Role assignment via `claude-config-manager` is replaced by LDAP group membership
or Azure AD / Okta attributes driving configuration selection.

**Hook distribution**: Enterprise endpoint management at scale (10,000+ devices)
requires packaging as signed packages through enterprise software distribution
(MECM/SCCM, Jamf Pro with enterprise license, Workspace ONE).

**Multi-business-unit governance**: Each BU may have different risk profiles.
A central AI governance team sets baseline policy; BUs add domain-specific overlays.

**Audit & compliance reporting**: Hook logs → SIEM → automated compliance dashboards.
Monthly SLO review becomes a formal governance committee meeting with board reporting.

**Vendor management**: Anthropic must go through full enterprise vendor risk lifecycle:
security questionnaire, legal review, DPA/processing agreement, periodic re-assessment.

---

## 3. What's Missing at This Scale

| Gap | Priority | Notes |
|-----|----------|-------|
| IAM/LDAP integration for role assignment | Critical | Manual role management breaks at this scale |
| Enterprise-grade audit pipeline | Critical | Splunk/QRadar with compliance dashboards |
| AI governance committee structure | Critical | Board-level oversight is expected |
| Formal AI risk taxonomy | High | Beyond P0–P3; full risk register aligned to ERM |
| Business continuity planning for AI tools | High | What happens if Claude API is unavailable? |
| Third-party AI model validation | High | Internal model risk team or external validator |
| Global data residency compliance | High | Multi-country operations require data mapping |
| AI ethics / bias review process | Medium | Increasingly expected by regulators |

---

## 4. Deployment Timeline

```
Months 1–3 (Foundation):
  Establish AI governance committee (CISO, CIO, CLO, business leads)
  Complete Anthropic vendor risk assessment
  Define AI acceptable use policy (based on ai-usage-policy-draft.md)
  Map existing AI tool usage across all BUs

Months 4–6 (Architecture):
  Design IAM integration for role-based CLAUDE.md
  Build SIEM integration for hook audit logs
  Develop enterprise software package for hook distribution
  Create AI risk taxonomy and incident classification

Months 7–9 (Pilot):
  2–3 BUs as pilot (500–1,000 users)
  Full audit pipeline operational
  Quarterly governance committee review

Months 10–18 (Rollout):
  BU-by-BU rollout with dedicated change management
  Mandatory AI literacy training (all staff using Claude)
  Board reporting on AI governance KPIs
```

---

## 5. Approval Chain

```
IT/AI Governance Team
  → CISO (security controls)
  → CIO (technology strategy)
  → General Counsel (policy and contracts)
  → Chief Risk Officer (enterprise risk)
  → Board Risk Committee (AI governance framework)
```

---

## 6. Key Risks at This Scale

| Risk | Mitigation |
|------|-----------|
| BU autonomy vs. central policy | Tiered policy: mandatory baseline + BU overlay |
| Vendor lock-in to Anthropic | Design hooks and policy to be model-agnostic |
| AI shadow IT at scale | Network-level detection; not just endpoint hooks |
| Inconsistent global rollout | Phased by region; dedicated regional change leads |
| Hook maintenance burden | Dedicated AI ops team (2–4 FTE at this scale) |
| Board-level AI incident | Pre-define escalation and communication plan |

---

## 7. Honest Assessment

**This portfolio provides the blueprint. The build is a separate project.**

At 5,000+ people, no individual joins and deploys this repo in their first month.
What this portfolio demonstrates is that the candidate has designed and operated
the full governance stack — security, cost, ITSM, observability, policy — at a
working level. That experience informs the architecture decisions made at enterprise scale.

The value proposition: "I have built this at personal scale; I understand every layer
well enough to specify, procure, and oversee the enterprise version."

---

---

## 日本語版

**対象規模**: 5,000〜30,000名 | **展開期間**: 12〜18ヶ月

> **前提**: [scale-enterprise.md](scale-enterprise.md)の内容に加えて、以下が変わる・追加される。

### このスケールでのポートフォリオの役割

**参照アーキテクチャ**として機能する。そのままデプロイするのではなく、設計思想と実装経験の証明として使う。

### 主要な適合・追加作業

| 項目 | 内容 |
|------|------|
| IAM統合 | CLAUDE.mdロール割り当てをLDAP/Azure AD/Okta連携に置換 |
| エンドポイント配布 | MECM/Jamf Proでのエンタープライズパッケージング |
| AIガバナンス委員会 | CISO・CIO・法務・CROによる正式委員会設置 |
| 監査パイプライン | hookログ → SIEM → コンプライアンスダッシュボード自動化 |
| グローバルデータ残留 | 多国間運営時のデータマッピングと規制対応 |

### 不足している主な要素

- IAM/LDAP連携（Critical）
- エンタープライズ監査パイプライン（Critical）
- AIガバナンス委員会体制（Critical）
- AIリスク分類体系（ERM連携）
- 事業継続計画（Claude API障害時）

### 正直な評価

**このポートフォリオは設計図を提供する。構築は別プロジェクトになる。**

5,000名超の規模では、入社初月にこのリポジトリをデプロイすることはない。このポートフォリオが示すのは「セキュリティ・コスト・ITSM・可観測性・ポリシーの全レイヤーを自ら設計・運用した経験」であり、エンタープライズ版の仕様策定・調達・監督に活きる。
