# System Architecture

**Claude Code AI Harness Infrastructure — Overview**

---

## Diagram 1: Hook Event Flow (Security Guardrails)

```mermaid
sequenceDiagram
    participant U as User
    participant CC as Claude Code
    participant H as Hooks (PreToolUse)
    participant LLM as LiteLLM Proxy
    participant API as Claude API / Local LLM

    U->>CC: Command input
    CC->>H: bash-secret-guard.sh<br/>(credential detection)
    alt Secrets detected
        H-->>CC: exit 2 (block)
        CC-->>U: ⚠️ Blocked + remediation guidance shown
    else Clean
        H-->>CC: exit 0 (pass)
        CC->>LLM: API call (light / heavy / auto)
        LLM->>API: Route by cost optimization
        API-->>LLM: response
        LLM-->>CC: response
        CC->>H: PostToolUse / Stop hooks
        H-->>CC: Audit log recorded
        CC-->>U: Output returned
    end
```

---

## Diagram 2: 5-Layer Stack (Overall Structure)

```mermaid
graph TB
    subgraph L5["L5: Self-Improvement Loop"]
        INC["INC: Incident tracking<br/>(13 total)"]
        CIP["CIP: Improvement proposals<br/>(6 completed)"]
        INC --> CIP
    end

    subgraph L4["L4: Cost Optimization"]
        Router["Model router<br/>light / heavy / auto"]
        LocalLLM["Local LLM<br/>(Gemma4)"]
        CloudLLM["Cloud LLM<br/>(Claude API)"]
        Router --> LocalLLM
        Router --> CloudLLM
    end

    subgraph L3["L3: Security Controls"]
        Hooks["PreToolUse Hooks × 7<br/>+ PostToolUse × 2"]
        gitleaks["gitleaks CI<br/>(auto-scan on push/PR)"]
        SecretsMgr["Secret management<br/>(1Password CLI integration)"]
    end

    subgraph L2["L2: Skills / Automation"]
        Skills["Skills library<br/>(specialized workflows)"]
        Scheduled["Scheduled agents × 3<br/>(daily, weekly)"]
        Integrations["API integrations<br/>(GitHub / Notion / Telegram)"]
    end

    subgraph L1["L1: Claude Code Foundation"]
        CC["Claude Code CLI"]
        Memory["3-tier memory<br/>short / mid / long-term"]
        CLAUDE_MD["Behavioral spec<br/>(policy document)"]
    end

    L5 --> L4
    L4 --> L3
    L3 --> L2
    L2 --> L1
```

---

## Diagram 3: Incident → Improvement Cycle (ITSM Flow)

```mermaid
flowchart LR
    A["🔴 INC<br/>Incident detected"] --> B["🟡 P<br/>Problem management<br/>RCA performed"]
    B --> C["🔵 CIP<br/>Improvement proposal<br/>Design review"]
    C --> D["🟢 C<br/>Change implemented<br/>Tested & verified"]
    D --> E["✅ Permanent resolution<br/>Prevention rule documented"]
    E -.-> A
```

**Results**: INC-001–013 (13 incidents) → CIP-001–006 (6 permanently resolved)

---

## Design Principles

| Principle | Implementation |
|-----------|---------------|
| **Defense in Depth** | Multi-layer controls: policy → hook → CI (L1–L3) |
| **Fail-Safe Default** | Hooks block by default; explicit allowlist required to pass |
| **Observability First** | All hook outputs logged; SLOs monitored continuously |
| **Cost Consciousness** | All API calls routed optimally; cost tracked per call |
| **Continuous Improvement** | INC → CIP cycle converts failures into organizational knowledge |
