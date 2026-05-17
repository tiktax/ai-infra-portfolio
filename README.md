# AI Infrastructure / Harness Engineering Portfolio

**対象期間**: 2026年3月〜5月（2ヶ月・50 commits）  
**対象職種**: IT管理職・情報システム部長候補

---

## このリポジトリについて

Claude Code（Anthropic社製AIエージェント開発環境）の制御レイヤーを個人プロジェクトとして設計・構築したものです。  
情報システム部門が本来担うべき機能（セキュリティポリシー・コスト管理・障害管理・自動化）を、AIシステムの運用基盤として一気通貫で設計・実装しました。

---

## 解いた問題と成果

### 1. セキュリティガバナンス

**課題**: AI出力経由でcredentialが漏洩するリスクが発見された（INC-011/012）

**対応**:
- `PreToolUse` / `PostToolUse` hookによる技術的ガードレール実装（9種類）
- AIの行動規範をポリシー文書として策定・Git版管理（ITSM §10準拠）
- 1Password CLI統合により秘密情報の直接埋め込みを根絶
- git commit前の自動credentialスキャン（gitleaks CI）

**結果**: INC-011/012発生後、再発ゼロ

---

### 2. コスト管理・ROI

**課題**: AI推論コストが無制御に増加

**対応**:
- ローカルLLM（Gemma4）とクラウドLLM（Claude API）の自動ルーティング設計
- タスク複雑度に応じた軽量/重量モデルの自動選択（light/heavy/auto）
- Claude Code CLI呼び出しの最適化

**結果**:

| 指標 | Before | After | 削減率 |
|------|--------|-------|-------|
| CLI subprocess コスト | $0.21/call | $0.001/call | **-99.5%** |
| SessionStart context | 19 MB/session | 36 KB/session | **-99.8%** |
| 年間トークン消費（推定） | 33.2B tokens | 13.3M tokens | **-99.96%** |

> 計算根拠: [`docs/achievements.md`](docs/achievements.md)

---

### 3. 障害管理・継続的改善（ITSM準拠）

**課題**: AIシステムの障害・ルール違反が場当たり的対応で再発していた

**対応**:
- INC（Incident）→ P（Problem）→ CIP（Continual Improvement Proposal）→ C（Change）フロー実装
- インシデント13件を体系管理し、根本原因分析（RCA）と恒久解消まで追跡
- SLOモニタリング（MCP登録数・context使用量）の自動計測

**結果**: CIP-001〜006の恒久解消完了、改善サイクルの自動化

---

### 4. 業務自動化

**課題**: 定型業務（情報収集・KPIレポート・手続き管理）が手動で非効率

**対応**:
- Scheduledエージェント3本（日次情報収集・週次KPIレビュー・手続き管理）
- Notion・GitHub・Telegram統合パイプライン（API連携）
- WikiBuilderによるKnowledge base自動構築・Obsidian同期

---

### 5. 知識管理・可観測性

**課題**: AIの行動ログ・インシデント記録が散在し検索・監査が困難

**対応**:
- 3層メモリ構造（短期セッション / 中期プロジェクト / 長期Obsidian）の設計・実装
- AGENT-LOG日次ダイジェスト化（93%削減）
- Claude API使用制限モニタリングツール実装

---

## 2ヶ月の進化ロードマップ

```
3月                4月                5月
│                  │                  │
▼                  ▼                  ▼
Notion/Telegram    Context最適化       ITSM改善ループ
API連携実装        99.96%トークン削減   INC→CIPフロー
                   1Password移行       worktree安全弁
                   セキュリティhook群   Obsidian同期自動化
```

---

## ドキュメント

| ファイル | 内容 |
|---------|------|
| [`docs/achievements.md`](docs/achievements.md) | 定量実績・計算根拠 |
| [`docs/architecture.md`](docs/architecture.md) | システム構成図（Mermaid）|
| [`docs/ai-usage-policy-draft.md`](docs/ai-usage-policy-draft.md) | AI利活用ガイドライン草案 |
| [`examples/hooks/`](examples/hooks/) | セキュリティhookのサンプル実装 |

---

## 技術スタック

- **AIエージェント**: Claude Code (Anthropic) + Claude API
- **ローカルLLM**: Gemma4 via LiteLLM Proxy
- **セキュリティ**: gitleaks / 1Password CLI / bash hooks
- **統合**: GitHub API / Notion API / Telegram Bot API
- **自動化**: cron / GitHub Actions / Shell scripts
- **知識管理**: Obsidian / GitHub Issues

---

## English Summary

This repository documents a solo project where I engineered an **AI harness infrastructure** for Claude Code, Anthropic's AI agent platform, over 2 months.

**Key accomplishments:**
- **Security & compliance**: Deployed 9 guardrail hooks and credential leak prevention mechanisms with gitleaks CI integration — achieving zero security incidents after initial fixes
- **Cost efficiency**: Reduced AI inference cost per API call by 99.5%; annual token consumption by 99.96%
- **ITSM framework**: Implemented incident-to-change management cycle (Incident → Problem → CIP → Change), resolving 13 incidents systematically
- **Operations**: Built 3 scheduled agents and integrated Notion/GitHub/Telegram APIs for daily/weekly automation
- **Observability**: Designed 3-tier memory architecture with SLO monitoring and daily log digests (93% size reduction)

> Target role: IT Infrastructure Manager / Head of Information Systems (solo personal project)
