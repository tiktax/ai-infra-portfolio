# AI Infrastructure / Harness Engineering Portfolio

> 多くの組織はAIの導入を「社員にチャット画面を与える」ことから始める。このプロジェクトはその逆のアプローチをとった——**誰かが使い始める前に、AIを安全・監査可能・コスト制御可能にするインフラ層を設計する**。

**期間**: 2026年3〜5月 | 個人プロジェクト &nbsp;·&nbsp; [English](README.md)

---

## クイックスタート

```bash
git clone https://github.com/tiktax/ai-infra-portfolio
cd ai-infra-portfolio
./demo.sh        # セキュリティhookの動作確認（セットアップ不要）
```

---

## このプロジェクトについて

セキュリティポリシーの強制・インシデント管理・コスト最適化・監査証跡を、後付けではなくシステムとして設計・構築。エンタープライズのIT/AI運用チームが担うべき領域を、一人で一気通貫で実装しました。

---

## ガバナンスフレームワーク

**ISO/IEC 20000**（ITサービスマネジメント）および **ISO/IEC 27001**（情報セキュリティマネジメント）の軽量版に準拠した運用ガバナンスをプロジェクト全体に適用しました。正式認証取得ではなく、設計思想としての準拠です。

| 規格 | 本プロジェクトでの適用範囲 |
|------|--------------------------|
| **ISO/IEC 20000** | インシデント→問題→変更サイクル、継続的改善、サービス継続性 |
| **ISO/IEC 27001** | credential管理（A.9）、監査ログ（A.12）、セキュリティインシデント管理（A.16）、リスクベースポリシー |
| **ITIL 5** | AI Governance（6C Capability Model）; プロダクト/サービスライフサイクル（8アクティビティ）; Change Enablement |

### 完全トレーサビリティと月次監査対応

すべてのガバナンス成果物を **GitHub** と **Obsidian** でデュアルトラッキングし、完全なトレーサビリティと月次監査対応を実現しています。

| レイヤー | ツール | 記録内容 |
|---------|--------|---------|
| **意思決定ログ** | GitHub Issues | インシデント（INC）・問題（P）・改善提案（CIP）・変更（C）を不変タイムスタンプ付きで記録 |
| **変更履歴** | GitHub（git log）| ポリシー・設定変更を作成者・日時・理由とともにコミットメッセージで管理 |
| **知識ベース** | Obsidian（LLM-Wiki）| RCA結果・アーキテクチャ判断・教訓を検索可能・相互リンク形式で蓄積 |
| **監査証跡** | GitHub Issues + git | INC→CIP→Cの完全トレーサビリティ・月次でオープンインシデントとSLO指標をレビュー |

**リスク判定・スコアリング**: 各インシデントおよび改善提案をObsidianで発生可能性×影響度マトリクスによりスコアリング。スコアがCIPの優先度決定に反映され、月次監査レビューへフィードバックされる。

| スコア | 発生可能性 | 影響度 | 対応方針 |
|-------|-----------|--------|---------|
| P0（致命）| 高 | 高 | 即時対処・作業停止 |
| P1（高）| 高 or 高 | 中 or 高 | 当サイクル内でCIP |
| P2（中）| 中 | 中 | スケジュールCIP |
| P3（低）| 低 | 任意 | バックログ |

---

## 解いた問題と成果

**1. セキュリティガバナンス**（ISO/IEC 27001: A.9/A.12/A.16 準拠）

AI出力経由のcredential漏洩（INC-011/012）を発見・根本解消。PreToolUse/PostToolUse hookを9種実装し技術的に遮断。ISO/IEC 27001に沿ったポリシー文書をGit版管理。1Password CLI統合で秘密情報の直書きを根絶。再発ゼロを実現。

**2. コスト管理・ROI**

ローカルLLM（Gemma4）とクラウドLLM（Claude API）の自動ルーティングを設計。

| 指標 | Before | After | 削減率 |
|------|--------|-------|-------|
| CLI呼び出しコスト | $0.21/call | $0.001/call | **−99.5%** |
| SessionStartコンテキスト | 19 MB | 36 KB | **−99.8%** |
| 年間トークン消費（推定） | 33.2B tokens | 13.3M tokens | **−99.96%** |

> 計算根拠: [`docs/achievements.md`](docs/achievements.md)

**3. 障害管理・継続的改善**（ISO/IEC 20000 準拠）

INC→問題→CIP→変更のフルサイクルを実装。インシデント13件を体系管理し根本原因分析（RCA）を実施。6件を恒久解消（CIP-001〜006）。SLOモニタリングを自動化。

**4. 業務自動化**（ISO/IEC 20000: サービス運用・継続的改善）

Scheduledエージェント3本（日次情報収集・週次KPIレビュー・週次手続き管理）を実装。Notion/GitHub/Telegram APIを統合したパイプラインを構築。Karpathiが提唱するLLM-Wikiのコンセプトを実装し、AIが維持・更新する知識ベースをエージェントのコンテキストにフィードバックするPDCAサイクルを知識管理に導入。

**5. 可観測性・知識管理**（ISO/IEC 27001: A.12; ISO/IEC 20000: サービスレポーティング）

3層メモリ構造（短期セッション/中期プロジェクト/長期Obsidian）を設計・実装。AGENT-LOG日次ダイジェスト化でログサイズ93%削減。Claude API使用制限モニタリングツールを実装。

---

## 発揮したスキル

| 領域 | 根拠 |
|-----|------|
| セキュリティポリシー策定 | hook 9種・gitleaks CI・1Password統合・再発ゼロの実績 |
| ISO/IEC 27001 準拠設計 | credential管理・監査ログ・インシデント対応・リスクベースポリシー |
| ISO/IEC 20000 準拠設計 | INC→問題→変更サイクル・SLOモニタリング・継続的改善 |
| コスト可視化・最適化 | 99.5%削減・計算根拠の文書化 |
| システム統合（API連携） | Notion/GitHub/Telegram・ローカル/クラウドLLMルーティング |
| 可観測性設計 | SLOモニタリング・3層メモリ・ログローテーション自動化 |
| ガバナンス文書化 | AI利活用ガイドライン草案・行動規範のバージョン管理 |
| 自動化設計 | Scheduledエージェント3本・CI/CDパイプライン・hookシステム |
| **ITIL 5 AIガバナンス** | 8アクティビティライフサイクル管理; 6C Capability Model; EU AI Act / 金融庁 / SR 11-7 多管轄対応 |

---

## プラットフォーム移植性

実装はClaude Codeで行いましたが、**ガバナンスフレームワーク自体はツール非依存**です。

| レイヤー | 移植性 | 内容 |
|---------|--------|------|
| **ガバナンス層** | ✅ 完全に移植可能 | INC→CIPサイクル・ISO準拠・リスクスコアリング・監査証跡 |
| **ポリシー層** | ✅ 概念は移植可能 | ロール別ルール・AI利活用ガイドライン（形式は変わる）|
| **実装層** | ⚠️ 要再実装 | hooks・CLAUDE.md・MCPサーバー（Claude Code固有）|

他プラットフォームへの展開例:
- **Cursor**: `.cursorrules` + VSCode拡張でhookを代替
- **OpenAI API**: APIミドルウェア（Lambda等）でガードレールを実装
- **Microsoft 365 Copilot**: Purview DLP + 条件付きアクセスで代替
- **オンプレLLM**: 任意のミドルウェアで実装可能

設計思想（多層防御・フェイルセーフ・監査優先・ロールベース制御）はどのAIプラットフォームにも適用できます。

---

## 2ヶ月の進化ロードマップ

```
3月                          4月                              5月
│                            │                                │
▼                            ▼                                ▼
コンセプト実証。              2つの問題が同時発生：             修正だけでは再発を
Notion/Telegram/GitHub       コスト（$0.21/call）と            防げない。
連携が動作——                  本番環境でのcredential           ガバナンス層を構築：
そしてAIツールは              漏洩。どちらもゼロから           INC→CIPサイクル、
制約なしでは秘密情報を        設計して解決：9つのhook          6件の恒久対応、
漏洩すると発覚。              ＋トークン99.96%削減。          改善ループを自動化。
                              パッチではなく設計で直した。
```

---

## ドキュメント

| ファイル | 内容 |
|---------|------|
| [`docs/achievements.md`](docs/achievements.md) | 定量実績・計算根拠 |
| [`docs/architecture.md`](docs/architecture.md) | システム構成図（Mermaid）|
| [`docs/ai-usage-policy-draft.md`](docs/ai-usage-policy-draft.md) | AI利活用ガイドライン草案 |
| [`docs/dashboard.md`](docs/dashboard.md) | 運用ダッシュボード（Mermaid 6グラフ）|
| [`docs/roadmap.md`](docs/roadmap.md) | 個人→組織展開へのスケールアップ計画 |
| [`examples/hooks/`](examples/hooks/) | セキュリティhookのサンプル実装 |
| [`tools/itil5-ai-governance/`](tools/itil5-ai-governance/) | ITIL 5 AIガバナンス準拠ツール — 8アクティビティライフサイクル・6C Capability Model・多管轄承認（JP/US/EU） |

---

## 技術スタック

- **AIエージェント**: Claude Code (Anthropic) + Claude API
- **ローカルLLM**: Gemma4 via LiteLLM Proxy
- **セキュリティ**: gitleaks / 1Password CLI / bash hooks
- **統合**: GitHub API / Notion API / Telegram Bot API
- **自動化**: cron / GitHub Actions / Shell scripts
- **知識管理**: Obsidian / GitHub Issues

---

## Contact

AIインフラ・エンタープライズAIガバナンス領域でのポジションを探しています。

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?logo=linkedin)](https://www.linkedin.com/in/takeshi-koide-3337193b/)
