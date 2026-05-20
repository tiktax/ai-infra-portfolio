# Deployment Considerations by Scale

Gap analysis for deploying this AI harness across different organization sizes and regulatory contexts.

Each document is **additive** — larger scales build on smaller ones.
Read only the document that matches your organization.

---

| Document | Scale | People | Deploy time |
|----------|-------|--------|-------------|
| [scale-startup.md](scale-startup.md) | Startup | < 50 | 1–2 weeks |
| [scale-smb.md](scale-smb.md) | SMB | 50–500 | 3–6 weeks |
| [scale-enterprise.md](scale-enterprise.md) | Enterprise | 500–5,000 | 3–6 months |
| [scale-large-enterprise.md](scale-large-enterprise.md) | Large Enterprise | 5,000–30,000 | 12–18 months |
| [scale-regulated.md](scale-regulated.md) | Regulated Industries | Any size | +3–12 months |

---

## How to read these documents

**Start with your scale.** Then add `scale-regulated.md` if your industry is:
- Financial services (banking, insurance, securities)
- Healthcare / life sciences
- Public sector / government

Each document covers:
1. **Portfolio Fit** — what works as-is
2. **What Needs Adaptation** — what to change
3. **What's Missing** — what to build new
4. **Deployment Timeline** — realistic schedule
5. **Approval Chain** — who needs to sign off
6. **Key Risks** — what to watch out for
7. **Honest Assessment** — direct summary
8. **日本語版** — Japanese equivalent

---

## Quick reference: Portfolio fit by scale

```
Startup        ████████████████████  ~95% direct use
SMB            ████████████████░░░░  ~80% direct use
Enterprise     ████████████░░░░░░░░  ~50% direct use
Large Ent.     ██████░░░░░░░░░░░░░░  ~30% (reference architecture)
Regulated      Add compliance layer to whichever scale applies
```
