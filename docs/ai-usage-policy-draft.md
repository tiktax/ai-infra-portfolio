# AI Usage Policy — Draft v1.0

> **Draft — Personal project scope**
> This document formalizes AI usage rules trialed in a personal Claude Code environment,
> structured for potential organizational adoption. It has not been approved as a formal policy.

**Date**: May 2026
**Audience**: Organizations and teams using generative AI agents in business operations
**Governance alignment**: Lightweight ISO/IEC 27001 (Information Security) and ISO/IEC 20000 (IT Service Management)

---

## 1. Purpose

This policy establishes rules for managing security risk, cost, and output quality when using generative AI (large language models) in business operations, aligned with ISO/IEC 27001 risk-based principles and ISO/IEC 20000 service management practices.

---

## 2. Scope

- Use of AI agents on work devices and cloud environments
- Any input of internal data, personal information, or confidential information into AI systems
- Business use of AI-generated code or documents

---

## 3. Prohibitions
*ISO/IEC 27001: A.9 Access Control, A.8 Asset Management*

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
*ISO/IEC 27001: A.14 System Acquisition and Development*

- AI-generated code must not be deployed to production without human review
- AI-generated documents (emails, reports) must be reviewed before sending
- URLs in AI output must be verified before accessing

### 3.3 No confidential data sent to external AI services
*ISO/IEC 27001: A.13 Communications Security*

- Confidential or higher classification data must not be sent to cloud AI services
- Confirm the classification level of any data before submission

---

## 4. Technical Controls
*ISO/IEC 27001: A.12 Operations Security, A.9 Access Control*

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
*ISO/IEC 27001: A.12.1 Operational Procedures and Responsibilities*

gitleaks scans every `git commit` attempt. Commit is blocked if any of the following are detected:

```
Detection patterns (14 types):
Notion API Key / Anthropic API Key / OpenAI API Key /
GitHub PAT / Google API Key / Slack Token / AWS Credentials /
Bearer Token / Private Key / Stripe Key / JWT /
Linear API Key / 1Password Service Account / GitLab PAT
```

### 4.3 Standardized Secret Management
*ISO/IEC 27001: A.9.4 System and Application Access Control*

```
❌ Prohibited: Hardcoding API keys in .env files
✅ Recommended: Store in secret manager → reference via op://vault/item/field
                Run with: op run --env-file=.env.template -- <command>
```

---

## 5. Incident Management
*ISO/IEC 27001: A.16 Information Security Incident Management; ISO/IEC 20000: Incident and Problem Management*

### 5.1 Response flow

```
Detect → Immediately revoke the exposed token
       → Record incident (time, scope, interim fix)
       → Root cause analysis (RCA)
       → Implement and test permanent fix
       → Document prevention rule and communicate to team
```

This flow follows the ISO/IEC 20000 Incident → Problem → Change cycle, with permanent resolution tracked through Continual Improvement Proposals (CIPs).

### 5.2 What to record

- Time of occurrence and time of detection
- Type and scope of exposed information
- Affected systems and users
- Interim fix with timestamp
- Root cause and permanent resolution

---

## 6. Traceability & Audit
*ISO/IEC 27001: A.12.4 Logging and Monitoring; ISO/IEC 20000: Service Reporting*

All governance artifacts are dual-tracked across GitHub and Obsidian to ensure full traceability and audit readiness.

| Record type | Tool | Retention |
|-------------|------|-----------|
| Incident / problem / change log | GitHub Issues | Permanent (immutable, timestamped) |
| Policy & config change history | git log | Permanent (author, date, rationale) |
| RCA findings & lessons learned | Obsidian (LLM-Wiki) | Ongoing, cross-linked |
| Monthly SLO review | GitHub Issues | Monthly, referenced against baseline |

**Risk assessment & scoring**: Each incident and improvement proposal is scored in Obsidian using a likelihood × impact matrix. Scores drive CIP prioritization and feed into the monthly audit review.

| Score | Likelihood | Impact | Action |
|-------|-----------|--------|--------|
| P0 (Critical) | High | High | Immediate remediation, block further work |
| P1 (High) | High or High | Medium or High | CIP within current cycle |
| P2 (Medium) | Medium | Medium | Scheduled CIP |
| P3 (Low) | Low | Any | Backlog |

**Monthly audit cycle**: Open incidents, CIP status, SLO measurements, and risk scores are reviewed monthly against the governance baseline, producing a closed-loop record suitable for internal audit or compliance review.

---

## 7. Cost Management
*ISO/IEC 20000: Capacity Management, Continual Service Improvement*

- Monitor AI usage cost monthly and set SLOs
- Use model tiers by task complexity (complex reasoning → high-capability model; simple transforms → lightweight model)
- Eliminate unnecessary context (logs, files) from automatic loading at session start

---

## 8. Revision History

| Version | Date | Changes |
|---------|------|---------|
| v1.0 draft | May 2026 | Initial draft (personal project trial) |

---

> This draft is based on 2 months of personal environment testing.
> For organizational adoption, formal review by legal and information security teams is required.

---

---

## 日本語版

> 以下は日本語での概要です。英語版と同等の内容を含みます。

**ドラフト — 個人プロジェクト内試行版**
本文書は個人プロジェクト（Claude Code環境）で試行したAI利活用ルールを、組織展開を想定した形式にまとめたものです。正式ポリシーとして承認されたものではありません。

**作成日**: 2026年5月
**対象**: 生成AIエージェント（LLM）を業務で利用する組織・チーム向け
**ガバナンス準拠**: ISO/IEC 27001（情報セキュリティ）およびISO/IEC 20000（ITサービスマネジメント）の軽量版

---

### 1. 目的

本ガイドラインは、生成AI（大規模言語モデル）を業務利用する際のセキュリティリスク・コスト・品質を組織的に管理するためのルールを定める。ISO/IEC 27001のリスクベース原則とISO/IEC 20000のサービス管理実践に準拠して設計。

---

### 2. 適用範囲

- 業務PCおよびクラウド環境でのAIエージェント利用
- 社内データ・個人情報・機密情報をAIに入力する行為全般
- AIが生成したコード・文書の業務利用

---

### 3. 禁止事項
*ISO/IEC 27001: A.9 アクセス制御、A.8 情報資産管理*

**3.1 秘密情報の入力禁止**

以下をAIチャット・プロンプトに直接貼り付けてはならない。

| 禁止対象 | 例 |
|---------|---|
| APIキー・アクセストークン | `sk-...`, `ghp_...` |
| パスワード・認証情報 | ログインパスワード、秘密鍵 |
| 個人情報 | 顧客氏名・住所・マイナンバー |
| 未公開の財務情報 | 売上データ、M&A情報 |
| 契約・法的文書の全文 | NDA、契約書 |

**代替手段**: 秘密情報はシークレット管理ツール（1Password等）経由で参照する。AIには変数名のみ渡す。

**3.2 AI出力の無審査利用禁止**（ISO/IEC 27001: A.14）

- AIが生成したコードは、そのまま本番環境にデプロイしてはならない
- AIが生成した文書は送付前に人間がレビューする
- AI出力に含まれるURLは、アクセス前に正当性を確認する

**3.3 外部サービスへの機密データ送信禁止**（ISO/IEC 27001: A.13）

- クラウドAIサービスに社外秘以上の情報を送信してはならない

---

### 4. 技術的統制
*ISO/IEC 27001: A.12 運用のセキュリティ、A.9 アクセス制御*

**4.1 PreToolUse ガードレール**

AIエージェントがツールを呼び出す前に自動検査するhookを実装。

```bash
# 検出・ブロック対象
- .env / *.key / *.pem ファイルの内容読み取りコマンド
- 環境変数経由のcredential表示（echo $TOKEN 等）
- URLパラメータへのcredential埋め込み
- 環境変数全ダンプ（printenv / env コマンド）
```

検出時は即座にブロックし、代替手段を提示する。

**4.2 Commit前自動スキャン**（ISO/IEC 27001: A.12.1）

`git commit`実行時にgitleaksで自動スキャン。14種類のパターンを検出したらcommitをブロック。

**4.3 秘密情報管理の標準化**（ISO/IEC 27001: A.9.4）

```
❌ 禁止: .envファイルにAPIキーを直書き
✅ 推奨: シークレット管理ツールで格納 → op://vault/item/field で参照
         実行: op run --env-file=.env.template -- <command>
```

---

### 5. インシデント管理
*ISO/IEC 27001: A.16 情報セキュリティインシデント管理; ISO/IEC 20000: インシデント・問題管理*

**発生時の対応フロー**:

```
発見 → 即座にトークン無効化（revoke）
     → インシデント記録（発見日時・影響範囲・暫定対処）
     → 根本原因分析（RCA）
     → 恒久対処の実装・テスト
     → 再発防止ルールの文書化・周知
```

ISO/IEC 20000のインシデント→問題→変更サイクルに従い、継続的改善提案（CIP）で恒久解消を追跡する。

---

### 6. トレーサビリティと監査対応
*ISO/IEC 27001: A.12.4 ログ取得・監視; ISO/IEC 20000: サービスレポーティング*

すべてのガバナンス成果物をGitHubとObsidianでデュアルトラッキングし、完全なトレーサビリティと月次監査対応を実現。

| 記録種別 | ツール | 保持方針 |
|---------|--------|---------|
| インシデント・問題・変更ログ | GitHub Issues | 永続保存（不変・タイムスタンプ付き）|
| ポリシー・設定変更履歴 | git log | 永続保存（作成者・日時・理由）|
| RCA結果・教訓 | Obsidian（LLM-Wiki）| 継続更新・相互リンク |
| 月次SLOレビュー | GitHub Issues | 月次・ベースラインと照合 |

**リスク判定・スコアリング**: 各インシデントおよび改善提案をObsidianで発生可能性×影響度マトリクスによりスコアリング。スコアがCIPの優先度決定に反映され、月次監査レビューへフィードバックされる。

| スコア | 発生可能性 | 影響度 | 対応方針 |
|-------|-----------|--------|---------|
| P0（致命）| 高 | 高 | 即時対処・作業停止 |
| P1（高）| 高 or 高 | 中 or 高 | 当サイクル内でCIP |
| P2（中）| 中 | 中 | スケジュールCIP |
| P3（低）| 低 | 任意 | バックログ |

**月次監査サイクル**: オープンインシデント・CIP進捗・SLO計測値・リスクスコアを月次でガバナンスベースラインと照合し、内部監査またはコンプライアンスレビューに対応可能なクローズドループ記録を生成。

---

### 7. コスト管理
*ISO/IEC 20000: キャパシティ管理、継続的サービス改善*

- AI利用コストを月次でモニタリングし、SLOを設定する
- 用途に応じてモデルを使い分ける（重い判断→高性能モデル、単純変換→軽量モデル）
- 不要なコンテキストの自動読み込みを排除する

---

### 8. 改訂履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|---------|
| v1.0 draft | 2026年5月 | 初版作成（個人プロジェクト内試行版）|

> 本草案は個人環境での2ヶ月間の試行を元に作成。組織導入時は法務・情報セキュリティ部門のレビューを経て正式化すること。
