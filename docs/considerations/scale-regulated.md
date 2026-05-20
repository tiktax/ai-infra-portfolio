# Deployment Considerations: Regulated Industries

> **Disclaimer**: This document provides a general overview of regulatory considerations.
> It does not constitute legal or compliance advice. Regulatory requirements vary by
> jurisdiction, organization type, and specific use case. Always verify with qualified
> legal, compliance, and regulatory professionals before deployment.

> **Builds on**: The appropriate scale document (startup/SMB/enterprise/large-enterprise).
> This document covers what changes when operating in regulated industries,
> regardless of organization size.

**Industries covered**: Financial services, healthcare, insurance, public sector
**Additional deployment time**: Add 3–12 months to the base scale estimate
**Key principle**: This harness addresses the **technical control layer** only.
Regulatory compliance requires organizational controls, legal agreements, and
governance structures that extend well beyond this repository.

---

## 1. International Framework

### ISO/IEC 27001 — Information Security Management

**What this harness covers**:
- A.9 Access Control: role-based CLAUDE.md + permission enforcement via hooks
- A.12 Operations Security: audit logging of all tool invocations, gitleaks CI
- A.16 Incident Management: INC→CIP cycle with documented RCA and resolution

**What organizations must add**:
- Formal ISMS certification process (this harness alone does not achieve certification)
- Asset inventory and risk register that includes AI tools
- Supplier/vendor management process for Anthropic as a data processor

---

### ISO/IEC 20000 — IT Service Management

**What this harness covers**:
- Incident and Problem Management: INC→P→CIP→C cycle
- Continual Improvement: CIP-based improvement tracking
- Service Reporting: SLO metrics and monthly dashboard

**What organizations must add**:
- Formal service catalogue entry for AI tools
- SLA definitions with business stakeholders
- Integration with enterprise ITSM platform (ServiceNow, etc.)

---

### PCI-DSS — Payment Card Industry Data Security Standard

**What this harness covers**:
- Requirement 7 (Access Control): role-based CLAUDE.md
- Requirement 10 (Audit Logging): hook event logging
- Requirement 12 (Security Policy): ai-usage-policy-draft.md as baseline

**What organizations must add**:
- Explicit prohibition on cardholder data in AI prompts (enforce at network/DLP layer)
- Cardholder data environment (CDE) scope assessment for AI tools
- QSA (Qualified Security Assessor) review of AI system controls
- Anthropic must be assessed as a third-party service provider under PCI-DSS

---

### SOC 2 Type II — Vendor Trust Assessment

**What this harness covers**:
- Documented security controls (policy, hooks, CI)
- Incident response and change management processes

**What organizations must add**:
- Request and review Anthropic's SOC 2 Type II report (available under NDA)
- Assess controls relevant to your trust service criteria (Security, Availability, Confidentiality)
- Annual re-assessment cycle for Anthropic as a vendor

---

### GDPR-Aligned Principles (Reference)

Even outside GDPR jurisdiction, these principles apply as best practice:

| Principle | Harness coverage | Gap |
|-----------|-----------------|-----|
| Purpose limitation | CLAUDE.md role restrictions | No enforcement at data level |
| Data minimization | Hook blocks PII file reads | No data classification enforcement |
| Accountability | Audit trail via GitHub + git | No formal DPA with Anthropic |
| Security | 9 hooks + gitleaks CI | No encryption at rest for hook logs |

---

## 2. Japan-Specific Considerations

> Note: The following reflects the regulatory landscape as understood at the time of writing.
> Regulations evolve; verify current requirements with qualified Japanese legal counsel.

### 金融庁 AI リスク管理ガイドライン (Financial Services Agency)

**What this harness covers**:
- Governance documentation (ai-usage-policy-draft.md as baseline)
- Incident management with audit trail
- Risk scoring (P0–P3 matrix aligned with risk-based approach)

**What organizations must add**:
- 「AIリスク管理態勢」の整備（経営レベルでの方針決定）
- AIシステムの説明可能性（explainability）の担保
- 監督当局への報告体制の整備
- 定期的なAIリスク評価と取締役会への報告

---

### FISC 安全対策基準 (Center for Financial Industry Information Systems)

**What this harness covers**:
- Access control by role
- Audit log maintenance
- Incident response procedures

**What organizations must add**:
- FISC基準に準拠したシステム分類とAIツールの位置づけ確認
- 外部クラウドサービス利用時の安全対策（Anthropic APIの利用形態の明確化）
- 第三者評価・監査の受入体制

---

### 個人情報保護法 (Personal Information Protection Act)

**What this harness covers**:
- Hook blocks reading files with credential/PII patterns
- Policy document prohibiting PII in AI prompts

**What organizations must add**:
- 「要配慮個人情報」（病歴・犯罪歴等）のAI送信禁止を技術的に強制（DLP連携）
- Anthropicとの委託契約・個人情報取扱いの明確化
- 越境移転規制への対応（Anthropic APIが米国サーバーを使用する場合）
- プライバシーポリシーへのAI利用の明記

---

### マイナンバー法 (My Number Act)

**Critical gap**: This harness **cannot adequately protect My Number (特定個人情報)** data.

- My Number data has strict statutory controls that prohibit cloud processing in most cases
- Current cloud-based Claude API implementation is incompatible with My Number handling
- Recommendation: Prohibit My Number input via policy + DLP enforcement; do not rely on hooks alone

---

### 医療情報システムの安全管理に関するガイドライン (Healthcare)

**What this harness covers**:
- Access control, audit logging, incident management (aligned with guideline requirements)

**What organizations must add**:
- 診療情報のAI入力に関する明示的な禁止ルール（DLP強制）
- 外部クラウドサービスとしてのAnthropicの安全性評価
- 患者への説明と同意プロセスの整備（AI利用の透明性）

---

## 3. United States-Specific Considerations

> Note: US regulatory landscape for AI is evolving rapidly. Verify current requirements
> with qualified US legal counsel, particularly for SEC and FINRA guidance.

### SR 11-7 — Model Risk Management (Federal Reserve)

**What this harness covers**:
- Documentation of AI tool behavior (CLAUDE.md as behavioral spec)
- Incident tracking and root cause analysis
- Change management with audit trail

**What organizations must add**:
- Formal model inventory that includes Claude as a third-party model
- Model validation by independent internal or external team
- Ongoing performance monitoring against defined use cases
- Board-level model risk reporting

**Key gap**: SR 11-7 requires validation of the model itself — not just the controls around it.
Anthropic's model must be assessed for fitness-of-purpose in specific use cases.

---

### SOX Section 302/404 — Financial Reporting Controls

**What this harness covers**:
- Audit trail for AI-assisted work (git log + GitHub Issues)
- Access controls on AI tool permissions

**What organizations must add**:
- Scoping assessment: does AI use touch financial reporting processes?
- External auditor review of AI controls if in-scope
- Management attestation process for AI-assisted financial work

---

### HIPAA — Health Insurance Portability and Accountability Act

**What this harness covers**:
- Policy prohibiting PHI in AI prompts
- Audit logging of AI tool use

**Critical gaps**:
- A Business Associate Agreement (BAA) with Anthropic is required before any PHI can be processed
- As of writing, verify whether Anthropic offers a BAA for your use case
- Hook-level PHI detection is not sufficient — DLP integration is required
- Encryption at rest for all hook logs containing any PHI references

---

### SEC / FINRA — AI Guidance for Financial Services

**What this harness covers**:
- Human-in-the-loop enforcement via policy (ai-usage-policy-draft.md)
- Audit trail for AI-assisted decisions

**What organizations must add**:
- Human review requirement for AI-assisted customer communications (technically enforced)
- Explainability documentation for AI-assisted investment decisions
- Regular testing for bias and fairness in AI outputs
- Customer disclosure when AI is used in advisory interactions

---

### FTC Act Section 5 — Unfair or Deceptive Acts

**What this harness covers**:
- Policy framework for appropriate AI use

**What organizations must add**:
- Review AI outputs for false or misleading claims before publication
- Processes to detect and correct AI hallucinations in customer-facing content

---

## 4. Cross-Cutting Gaps (All Regulated Industries)

These gaps exist regardless of jurisdiction:

| Area | Gap | Harness provides | Organization must add |
|------|-----|-----------------|----------------------|
| Data sovereignty | Claude API sends data to Anthropic's servers | Policy prohibition | DPA/contract with Anthropic; data residency verification |
| Model explainability | Black-box LLM outputs | None | External explainability layer or use-case restrictions |
| Bias/fairness | No bias controls | None | Regular bias audits; use-case limitation |
| Human oversight | Policy only | Audit trail | Technically enforced human review gates |
| Third-party risk | Anthropic dependency | Vendor assessment guide | Full vendor lifecycle management |
| Encryption at rest | Not implemented | None | Encrypt hook logs and config files |

---

## 5. Recommended Pre-Deployment Checklist (Regulated Industries)

- [ ] Legal review of Anthropic Terms of Service and Data Processing Agreement
- [ ] Data classification assessment: what can/cannot go to Claude API
- [ ] Regulatory mapping: identify applicable regulations and control gaps
- [ ] DPA/BAA with Anthropic (if processing personal/health data)
- [ ] Data residency verification (where does Anthropic process data?)
- [ ] Third-party security assessment of Anthropic (SOC 2 Type II review)
- [ ] Prohibit high-risk data types via DLP (not just policy)
- [ ] Employee training on AI acceptable use in regulated context
- [ ] Incident response plan for AI-specific incidents (model failure, data leak)
- [ ] Board/executive sign-off on AI governance framework
- [ ] Regulatory notification assessment (do regulators need to be informed?)
- [ ] Annual re-assessment schedule

---

---

## 日本語版

**対象**: 規制産業（金融・医療・保険・公共）| **追加展開期間**: 3〜12ヶ月

> **免責事項**: 本資料は概要情報の提供を目的とし、法的・コンプライアンスアドバイスを構成しません。規制要件は管轄・組織・用途によって異なります。実際の対応には適格な専門家への確認が必要です。

### 基本方針

**このharnessが提供するのは技術統制レイヤーのみ。**
規制遵守には、組織的統制・法的契約・ガバナンス体制が追加で必要。

### 国際フレームワーク（全産業共通）

| 標準 | harnessが対応する部分 | 組織が追加すべき部分 |
|------|---------------------|-------------------|
| ISO/IEC 27001 | A.9アクセス制御・A.12運用・A.16インシデント | 正式ISMS認証・資産台帳・ベンダー管理 |
| ISO/IEC 20000 | INC→CIPサイクル・SLOモニタリング | サービスカタログ・SLA定義・ITSM統合 |
| PCI-DSS | ロール別アクセス・監査ログ・ポリシー文書 | QSA評価・CDE範囲査定・DLP強制 |
| SOC 2 Type II | セキュリティ統制の文書化 | AnthropicのSOC 2レポート取得・年次再評価 |

### 日本規制への対応状況

| 規制 | harness対応 | 主要ギャップ |
|------|-----------|------------|
| 金融庁AIガイドライン | ガバナンス文書・インシデント管理・リスクスコアリング | AIリスク管理態勢（経営レベル）・説明可能性・監督当局報告 |
| FISC安全対策基準 | アクセス制御・監査ログ・インシデント対応 | 外部クラウド安全対策・第三者評価受入 |
| 個人情報保護法 | hookによるPII読取ブロック・ポリシー文書 | Anthropicとの委託契約・越境移転対応・DLP強制 |
| マイナンバー法 | **対応不可** | クラウドAPIでの処理は原則禁止 → DLP+ポリシーで禁止必須 |
| 医療情報安全管理GL | アクセス制御・監査 | Anthropicの安全性評価・患者説明・DLP強制 |

### 米国規制への対応状況

| 規制 | harness対応 | 主要ギャップ |
|------|-----------|------------|
| SR 11-7 | 文書化・インシデント追跡・変更管理 | モデル検証（独立評価）・モデルインベントリ |
| SOX 302/404 | 監査証跡・アクセス制御 | 外部監査レビュー・AI利用のスコープ評価 |
| HIPAA | ポリシー文書・監査ログ | BAA必須・DLP強制・ログ暗号化 |
| SEC/FINRA | ポリシー・監査証跡 | 人間レビューの技術的強制・説明可能性文書 |

### 展開前チェックリスト（規制産業向け）

- [ ] Anthropic利用規約・データ処理契約のレビュー
- [ ] データ分類アセスメント（何をClaudeに渡してよいか）
- [ ] 規制マッピング（適用される規制と統制ギャップの特定）
- [ ] 個人情報・医療情報を扱う場合はDPA/BAA締結
- [ ] データ残留確認（Anthropicがどの国でデータを処理するか）
- [ ] AnthropicのSOC 2 Type IIレポート取得・レビュー
- [ ] 高リスクデータのDLP強制（ポリシーだけでは不十分）
- [ ] 従業員向け規制対応AI研修
- [ ] AI固有インシデントの対応計画（モデル障害・データ漏洩）
- [ ] 取締役会・経営層によるAIガバナンス承認
- [ ] 規制当局への届出要否の確認
- [ ] 年次再評価スケジュールの設定
