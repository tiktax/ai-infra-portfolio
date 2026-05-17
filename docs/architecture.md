# システムアーキテクチャ

**Claude Code AIハーネス基盤 — 全体構成図**

---

## 図1: Hookイベントフロー（セキュリティガードレール）

```mermaid
sequenceDiagram
    participant U as User
    participant CC as Claude Code
    participant H as Hooks (PreToolUse)
    participant LLM as LiteLLM Proxy
    participant API as Claude API / Local LLM

    U->>CC: コマンド入力
    CC->>H: bash-secret-guard.sh<br/>（credential検出）
    alt secretsを検出
        H-->>CC: exit 2 (block)
        CC-->>U: ⚠️ ブロック + 代替手段を提示
    else clean
        H-->>CC: exit 0 (pass)
        CC->>LLM: API call (light / heavy / auto)
        LLM->>API: ルーティング（コスト最適化）
        API-->>LLM: response
        LLM-->>CC: response
        CC->>H: PostToolUse / Stop hooks
        H-->>CC: 監査ログ記録
        CC-->>U: 結果出力
    end
```

---

## 図2: 5層スタック（全体構造）

```mermaid
graph TB
    subgraph L5["L5: 自己改善ループ"]
        INC["INC: インシデント管理<br/>（13件）"]
        CIP["CIP: 改善提案<br/>（6件完了）"]
        INC --> CIP
    end

    subgraph L4["L4: コスト最適化"]
        Router["モデルルーター<br/>light / heavy / auto"]
        LocalLLM["ローカルLLM<br/>（Gemma4）"]
        CloudLLM["クラウドLLM<br/>（Claude API）"]
        Router --> LocalLLM
        Router --> CloudLLM
    end

    subgraph L3["L3: セキュリティ統制"]
        Hooks["PreToolUse Hooks × 7<br/>+ PostToolUse × 2"]
        gitleaks["gitleaks CI<br/>（push/PR自動スキャン）"]
        SecretsMgr["シークレット管理<br/>（1Password CLI統合）"]
    end

    subgraph L2["L2: Skills / 自動化"]
        Skills["Skillsライブラリ<br/>（専用ワークフロー）"]
        Scheduled["Scheduledエージェント × 3<br/>（日次・週次）"]
        Integrations["API統合<br/>（GitHub / Notion / Telegram）"]
    end

    subgraph L1["L1: Claude Code基盤"]
        CC["Claude Code CLI"]
        Memory["3層メモリ<br/>短期 / 中期 / 長期"]
        CLAUDE_MD["CLAUDE.md<br/>（行動規範・ポリシー）"]
    end

    L5 --> L4
    L4 --> L3
    L3 --> L2
    L2 --> L1
```

---

## 図3: インシデント→改善サイクル（ITSMフロー）

```mermaid
flowchart LR
    A["🔴 INC\n障害・逸脱の発見"] --> B["🟡 P\n問題管理\nRCA実施"]
    B --> C["🔵 CIP\n改善提案\n設計レビュー"]
    C --> D["🟢 C\n変更実施\nテスト確認"]
    D --> E["✅ 恒久解消\n再発防止ルール文書化"]
    E -.-> A
```

**実績**: INC-001〜013（13件）→ CIP-001〜006（6件恒久解消）

---

## 設計原則

| 原則 | 実装 |
|-----|------|
| **Defense in Depth** | L1〜L3の多層防御（policy → hook → CI） |
| **Fail-Safe Default** | hookはblockをデフォルト、明示的allowlistで許可 |
| **Observability First** | 全hookの出力をログ記録、SLOをモニタリング |
| **Cost Consciousness** | 全APIコールをルーターで最適分配、コスト可視化 |
| **Continuous Improvement** | INC→CIPサイクルで障害を組織知識に変換 |
