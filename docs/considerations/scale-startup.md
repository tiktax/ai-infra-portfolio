# Deployment Considerations: Startup (< 50 people)

> **Disclaimer**: This document provides a general framework. Specific regulatory
> or security requirements should be verified with qualified professionals.

**Scale**: < 50 people
**Typical profile**: Engineering-led, fast-moving, minimal existing process
**Time to deploy**: 1–2 weeks

---

## 1. Portfolio Fit — What Works As-Is

| Artifact | Fit | Notes |
|----------|-----|-------|
| `demo.sh` + `examples/hooks/` | ✅ Direct | 30-min install, immediate value |
| `docs/ai-usage-policy-draft.md` | ✅ Direct | Use as-is or simplify to 1 page |
| `tests/hooks/run-tests.sh` | ✅ Direct | Run in CI from day one |
| `tools/roi-calculator/` | ✅ Direct | Useful for founder pitch |
| `tools/claude-config-manager/` | ⚠️ Partial | 2 roles (engineer/manager) sufficient |
| `docs/deployment-playbook.md` | ⚠️ Partial | Phases 0–2 only; skip enterprise sections |

---

## 2. What Needs Adaptation

**CLAUDE.md**: Simplify to 1–2 pages. Startups don't need manager/analyst roles.
Remove the full role matrix — one config for everyone is fine.

**Incident management**: GitHub Issues is perfect at this scale.
The INC→CIP cycle can be informal — a Slack thread + an issue is enough.

**Approval chain**: CTO or founder signs off. No committee needed.

**Hook configuration**: Install all 5 hooks. Skip worktree-guard if the team
doesn't use git worktrees (common in early-stage projects).

---

## 3. What's Missing at This Scale

Very little. The main gaps:

| Gap | Priority | Why |
|-----|----------|-----|
| Formal AI usage policy sign-off | Low | Informal agreement among founders is sufficient early on |
| SIEM integration | None | No SIEM at this scale |
| Vendor risk assessment of Anthropic | Low | Review Anthropic's SOC 2 report if handling sensitive data |

---

## 4. Deployment Timeline

```
Week 1:
  Day 1–2: Install hooks + run demo.sh (all engineers)
  Day 3–4: Agree on CLAUDE.md baseline (async Slack discussion)
  Day 5:   First commit blocked by pre-commit-secrets → explained, understood

Week 2:
  Day 1–3: Tune false positives (expect 2–5 adjustments)
  Day 5:   Declare "done" — revisit quarterly or after an incident
```

---

## 5. Approval Chain

```
Engineer → CTO/Founder (1 person, 1 conversation)
```

---

## 6. Key Risks at This Scale

| Risk | Mitigation |
|------|-----------|
| Team too small — hooks feel like overhead | Start with bash-secret-guard only; add others gradually |
| Fast iteration clashes with hook friction | Tune `allow-secret:` and `worktree-guard:allow` liberally at first |
| Founder bypasses hooks "just this once" | Model the behavior yourself — culture sets in early |

---

## 7. Honest Assessment

**This portfolio is most directly applicable here.**
A startup can deploy the full stack in a weekend. The ROI is immediate:
one prevented credential leak at a seed-stage company can be existential.

---

---

## 日本語版

**対象規模**: 50名未満 | **展開期間**: 1〜2週間

### ポートフォリオの適合度

ほぼそのまま使える。`demo.sh` + hooks の30分インストールで即日効果が出る。

### 必要な適合作業

- CLAUDE.md: 1〜2ページに簡略化。ロール区分不要（全員同一設定でよい）
- インシデント管理: GitHub Issues + Slackの組み合わせで十分。正式フロー不要
- 承認: CTO/創業者1名の口頭合意で十分

### 不足しているもの

ほぼなし。Anthropicのベンダーリスク評価（SOC 2確認）は機密データを扱う場合のみ。

### リスク

- hook摩擦が速度感と衝突する → 最初は `bash-secret-guard` だけ入れて様子を見る
- 創業者が「今回だけ」とバイパスする → 文化の設定は早期が重要

### 正直な評価

**このポートフォリオが最も直接的に適用できるスケール。**
週末で全スタック展開可能。credential漏洩1件の防止がシード段階の会社には致命的な意味を持つため、ROIが最も高い。
