# AI Usage Policy — Draft v1.0

> **Draft — Personal project scope**
> This document formalizes AI usage rules trialed in a personal Claude Code environment,
> structured for potential organizational adoption. It has not been approved as a formal policy.

**Date**: May 2026
**Audience**: Organizations and teams using generative AI agents in business operations

---

## 1. Purpose

This policy establishes rules for managing security risk, cost, and output quality when using generative AI (large language models) in business operations.

---

## 2. Scope

- Use of AI agents on work devices and cloud environments
- Any input of internal data, personal information, or confidential information into AI systems
- Business use of AI-generated code or documents

---

## 3. Prohibitions

### 3.1 No secrets in prompts

The following must never be pasted directly into AI chat or prompts:

| Prohibited | Examples |
|------------|----------|
| API keys / access tokens | `sk-...`, `ghp_...` |
| Passwords / credentials | Login passwords, private keys |
| Personal information | Customer names, addresses, national ID numbers |
| Non-public financial data | Revenue figures, M&A information |
| Full text of legal documents | NDAs, contracts |

**Alternative**: Store secrets in a secret manager (e.g., 1Password) and pass only variable references to the AI.

### 3.2 No unreviewed AI output in production

- AI-generated code must not be deployed to production without human review
- AI-generated documents (emails, reports) must be reviewed before sending
- URLs in AI output must be verified before accessing

### 3.3 No confidential data sent to external AI services

- Confidential or higher classification data must not be sent to cloud AI services
- Confirm the classification level of any data before submission

---

## 4. Technical Controls (Implementation Reference)

The following patterns were implemented and validated in a personal project environment.

### 4.1 PreToolUse Guardrails

Hooks that automatically inspect every tool call before the AI agent executes it.

```bash
# Patterns detected and blocked:
- Reading contents of .env / *.key / *.pem files (cat, grep, awk, sed, etc.)
- Displaying credential env vars via echo/printf ($TOKEN, $SECRET, etc.)
- Embedding credentials in URL query parameters
- Full environment variable dumps (printenv, env)
```

On detection: execution is blocked immediately and remediation guidance is shown.

See [`../examples/hooks/bash-secret-guard.sh`](../examples/hooks/bash-secret-guard.sh) for a working implementation.

### 4.2 Pre-commit Automatic Scan

gitleaks scans every `git commit` attempt. Commit is blocked if any of the following are detected:

```
Detection patterns (14 types):
Notion API Key / Anthropic API Key / OpenAI API Key /
GitHub PAT / Google API Key / Slack Token / AWS Credentials /
Bearer Token / Private Key / Stripe Key / JWT /
Linear API Key / 1Password Service Account / GitLab PAT
```

### 4.3 Standardized Secret Management

```
❌ Prohibited: Hardcoding API keys in .env files
✅ Recommended: Store in secret manager → reference via op://vault/item/field
                Run with: op run --env-file=.env.template -- <command>
```

---

## 5. Incident Management

### 5.1 Response flow

```
Detect → Immediately revoke the exposed token
       → Record incident (time, scope, interim fix)
       → Root cause analysis (RCA)
       → Implement and test permanent fix
       → Document prevention rule and communicate to team
```

### 5.2 What to record

- Time of occurrence and time of detection
- Type and scope of exposed information
- Affected systems and users
- Interim fix with timestamp
- Root cause and permanent resolution

---

## 6. Cost Management

- Monitor AI usage cost monthly and set SLOs
- Use model tiers by task complexity (complex reasoning → high-capability model; simple transforms → lightweight model)
- Eliminate unnecessary context (logs, files) from automatic loading at session start

---

## 7. Revision History

| Version | Date | Changes |
|---------|------|---------|
| v1.0 draft | May 2026 | Initial draft (personal project trial) |

---

> This draft is based on 2 months of personal environment testing.
> For organizational adoption, formal review by legal and information security teams is required.
