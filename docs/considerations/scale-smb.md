# Deployment Considerations: SMB (50–500 people)

> **Disclaimer**: This document provides a general framework. Specific regulatory
> or security requirements should be verified with qualified professionals.

> **Builds on**: [scale-startup.md](scale-startup.md) — all startup considerations apply.
> This document covers what changes or is added at SMB scale.

**Scale**: 50–500 people
**Typical profile**: Structured teams, some process maturity, IT department exists
**Time to deploy**: 3–6 weeks

---

## 1. Portfolio Fit — What Works As-Is

| Artifact | Fit | Notes |
|----------|-----|-------|
| `examples/hooks/` (all 5) | ✅ Direct | Deploy to all engineers |
| `tests/hooks/run-tests.sh` | ✅ Direct | Add to CI pipeline |
| `tools/claude-config-manager/` | ✅ Direct | 3 roles cover most SMB structures |
| `docs/deployment-playbook.md` | ✅ Direct | Follow Phases 0–3 as written |
| `docs/ai-usage-policy-draft.md` | ✅ Direct | Get legal review before enforcing |
| `tools/roi-calculator/` | ✅ Direct | Use for IT budget justification |
| `docs/dashboard.md` | ✅ Direct | Monthly SLO review with IT lead |

---

## 2. What Needs Adaptation

**CLAUDE.md distribution**: At 50+ people, manual copy/paste breaks down.
Use `claude-config-manager` with a shared git repo that team members pull from.

**Role expansion**: The 3 default roles (engineer/analyst/manager) usually suffice,
but you may need a `support` role for helpdesk staff using Claude for ticket drafting.

**Incident management**: GitHub Issues works up to ~200 people.
Above that, consider migrating to Jira or Linear for better team visibility.

**Hook false positive tuning**: With 50+ engineers, false positives multiply.
Dedicate one sprint to collecting and resolving them before broad rollout.

**Approval chain**: Needs IT manager + department head sign-off.
A written policy (based on `ai-usage-policy-draft.md`) is now expected.

---

## 3. What's Missing at This Scale

| Gap | Priority | Recommended Action |
|-----|----------|--------------------|
| MDM-based hook distribution | Medium | Use Jamf/Intune to push `~/.claude/` config at scale |
| Formal AI policy approval | High | Legal + IT manager sign-off required |
| Anthropic vendor assessment | Medium | Request SOC 2 Type II report |
| Log retention policy | Medium | Define how long hook logs are kept (align with data policy) |
| Employee awareness training | High | 30-min session before enforcing hooks |

---

## 4. Deployment Timeline

```
Week 1–2 (Pilot):
  Select 5–10 volunteer engineers
  Install full hook suite + engineer CLAUDE.md
  Collect false positive log

Week 3 (Policy):
  Draft AI usage policy from ai-usage-policy-draft.md
  Get legal and IT manager review
  Fix false positives from pilot

Week 4–5 (Rollout):
  Deploy to all engineers via claude-config-manager
  Run awareness session (30 min)
  Deploy analyst + manager configs

Week 6 (Steady state):
  First monthly SLO review
  Open incident management in GitHub Issues / Jira
```

---

## 5. Approval Chain

```
IT Manager → Department Head → CEO/COO (for policy sign-off)
```

---

## 6. Key Risks at This Scale

| Risk | Mitigation |
|------|-----------|
| IT dept doesn't own AI tools | Establish ownership before rollout |
| Engineers route around hooks | Make bypass visible (`# allow:` in commit = audit trail) |
| Policy exists but isn't enforced | Hook enforcement makes policy technical, not just advisory |
| No one owns incident follow-up | Assign an AI ops owner (even 10% of one person's time) |

---

## 7. Honest Assessment

**80% of this portfolio is directly usable.**
The main additions are: formal policy approval, MDM distribution, and a 30-min training session.
An IT manager joining at this scale could deploy in their first month.

---

---

## 日本語版

**対象規模**: 50〜500名 | **展開期間**: 3〜6週間

> **前提**: [scale-startup.md](scale-startup.md)の内容に加えて、以下が変わる・追加される。

### ポートフォリオの適合度

3ロール構成がそのまま機能する。`deployment-playbook.md` をPhase 0〜3通りに実施すれば展開できる。

### 必要な適合作業

- CLAUDE.md配布: `claude-config-manager` + 共有gitリポジトリで自動化
- ロール追加: サポートデスク向け `support` ロールが必要になる場合がある
- インシデント管理: 200名超ならJiraへの移行を検討

### 不足しているもの

| ギャップ | 優先度 | 対応 |
|---------|--------|------|
| MDM経由のhook配布（Jamf/Intune）| 中 | 大人数への一括展開に必要 |
| 正式なAIポリシー承認 | 高 | IT管理職 + 部門長のサインオフ |
| Anthropicベンダー評価 | 中 | SOC 2 Type IIレポートの取得 |
| 従業員向け研修 | 高 | hook適用前の30分セッション |

### リスク

- hook摩擦への抵抗 → バイパスを「見える化」する設計（`# allow-secret:` がコミット履歴に残る）
- ポリシーはあるが誰も管理しない → AI運用オーナーを1名指定（10%工数でも可）

### 正直な評価

**ポートフォリオの80%がそのまま使える。**
正式なポリシー承認・MDM配布・研修の3点を追加すれば、ITマネージャーが入社1ヶ月で展開できるレベル。
