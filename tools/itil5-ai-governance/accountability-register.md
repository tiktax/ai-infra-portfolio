# AI Product Accountability Register

> **ITIL 5 Practice: AI Governance** — Part of the trustless design framework.
> Defines who is accountable for what, and under what conditions human approval is required.

---

## Purpose

This register defines the accountability boundary between AI and human responsibility
for each AI product/system. It answers three questions:

1. **Who owns this AI product?** (accountability by role)
2. **What is AI responsible for?** (technical scope)
3. **What requires human judgment?** (approval gates)

---

## Accountability Roles

| Role | Responsibility Scope |
|------|---------------------|
| **AI Product Owner** | Business outcomes; adoption/rejection decisions; final sign-off |
| **Risk Owner** | Risk classification; escalation; regulatory compliance |
| **Data Owner** | Training data quality; data governance; privacy compliance |
| **Technical Owner** | Model quality; infrastructure; security configuration |
| **Approver (Human)** | Gate-by-gate human sign-off (recorded in `approvals.log`) |

---

## AI vs Human Responsibility

### What AI is Responsible For (Technical Scope)
- Quality of generated, classified, or executed output
- Model inference errors and algorithmic bugs
- Training data limitations and representational bias
- Technical performance against defined SLA metrics

### What Humans Are Responsible For (Final Authority)
- Decision to **adopt or reject** AI proposals
- Business application of AI-generated output
- Governance policy design and enforcement
- Incident accountability when AI causes harm

---

## Scenario Breakdown

| Scenario | AI Responsibility | Human Responsibility |
|----------|------------------|---------------------|
| AI generates incorrect prediction | Generation quality (technical) | Verification + adoption decision |
| AI system is compromised | Vulnerability in model/infra | Security configuration + response |
| AI executes an action autonomously | Technical execution | Permission scope + monitoring |
| AI produces biased output | Training data + model quality | Bias audit + remediation decision |

---

## Risk Levels and Approval Gates

Mapped to `phase-gate.sh approve --jurisdiction <JP|US|EU>`:

| Risk Level | Criteria | Required Approver | ITIL 5 Gate |
|-----------|----------|------------------|-------------|
| **LOW** | Limited scope, no PII, reversible | Manager | Discover, Design |
| **MEDIUM** | Operational impact, some PII | CRO / Senior Manager | Build, Operate |
| **HIGH** | Customer-facing, irreversible, regulated | Director / Board (JP) · CRO (US) · Third-party (EU) | Deploy, Retire |

---

## Re-review Triggers

An approval becomes stale and requires re-review when any of the following occurs:

- [ ] Model retrained or fine-tuned with new data
- [ ] Regulatory change in applicable jurisdiction (JP/US/EU)
- [ ] Security incident involving this AI product
- [ ] Approval age > 12 months (see `phase-gate.sh check-expiry` — Phase 4)
- [ ] Material change in use case or data sources

---

## Integration with phase-gate.sh

```bash
# Record approval with owner
./tools/itil5-ai-governance/phase-gate.sh approve \
  --activity deploy \
  --approver director@example.com \
  --jurisdiction JP

# Future (Phase 4): --owner field
# ./phase-gate.sh approve --activity deploy --approver ... --owner "AI Product Owner"
```

---

## 日本語版

# AIプロダクト説明責任レジスター

## 目的

このレジスターは、AIと人間の責任範囲を定義し、「誰が何に責任を持つか」を明確化します。

## 責任ロール

| ロール | 責任範囲 |
|-------|---------|
| **AIプロダクトオーナー** | ビジネス成果・採用/却下の最終判断 |
| **リスクオーナー** | リスク分類・エスカレーション・規制対応 |
| **データオーナー** | 学習データ品質・データガバナンス・プライバシー |
| **技術オーナー** | モデル品質・インフラ・セキュリティ設定 |
| **承認者（人間）** | ゲートごとの人間承認（approvals.logに記録） |

## リスクレベルと承認ゲート

| リスクレベル | 条件 | 必要な承認者 |
|-----------|------|------------|
| **LOW** | 限定的スコープ・PII不使用・可逆的 | マネージャー |
| **MEDIUM** | 運用影響あり・一部PII | CRO / シニアマネージャー |
| **HIGH** | 顧客向け・非可逆・規制対象 | 取締役（JP）· CRO（US）· 第三者機関（EU） |

## 再評価トリガー

- モデルの再学習またはファインチューニング
- 適用管轄（JP/US/EU）での規制改正
- このAIプロダクトに関連するセキュリティインシデント
- 承認から12ヶ月経過
- ユースケースまたはデータソースの実質的な変更
