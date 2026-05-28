# Workload Identity Federation (OIDC)

This directory contains infrastructure-as-code templates for replacing long-lived cloud
credentials with short-lived tokens issued via OpenID Connect (OIDC) federation.

## Why

The WORM audit storage (`tools/trustless_audit/src/worm_storage.py`) currently requires
AWS credentials passed via 1Password (`op run --env-file=.env.aws.1password`).
When running in CI, this means storing a long-lived IAM access key as a GitHub Secret.

Workload Identity Federation eliminates that requirement: GitHub Actions presents its
built-in OIDC token to AWS STS, which exchanges it for short-lived credentials scoped
to exactly the permissions needed. No long-lived key is ever stored anywhere.

## How It Works

```
GitHub Actions job starts
    │
    ▼
GitHub issues OIDC token (JWT, ~10 min TTL)
    │  signed by token.actions.githubusercontent.com
    ▼
aws-actions/configure-aws-credentials sends token to AWS STS
    │  AssumeRoleWithWebIdentity
    ▼
AWS validates token against registered OIDC Provider
    │  checks: aud == sts.amazonaws.com
    │  checks: sub matches repo:tiktax/ai-infra-portfolio:*
    ▼
AWS returns temporary credentials (15 min TTL)
    │  AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN set as env vars
    ▼
boto3 in worm_storage.py picks up credentials automatically
    │  standard credential chain — no code change required
    ▼
S3 PutObject with Object Lock (WORM)
```

## AWS Setup

### Option A — CloudFormation (recommended)

```bash
aws cloudformation deploy \
  --template-file tools/wif/aws/oidc-provider.yml \
  --stack-name ai-infra-wif \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    GitHubOrg=tiktax \
    GitHubRepo=ai-infra-portfolio \
    WORMBucketName=<your-worm-bucket>
```

Then set these GitHub Variables (not Secrets — ARNs contain no sensitive data):

| Variable | Value |
|----------|-------|
| `AWS_WIF_ROLE_ARN` | Output `RoleArn` from CloudFormation stack |
| `AWS_WORM_BUCKET` | Your S3 bucket name |
| `AWS_REGION` | e.g. `ap-northeast-1` (optional, defaults to ap-northeast-1) |

### Option B — Manual IAM

1. Create an OIDC Provider in IAM → Identity providers:
   - Provider URL: `https://token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`
   - Thumbprint: `6938fd4d98bab03faadb97b34396831e3780aea1`

2. Create an IAM Role with the trust policy in `aws/trust-policy-template.json`
   (replace `<ACCOUNT_ID>` with your AWS account ID).

3. Attach a policy allowing `s3:PutObject` + `s3:GetObjectRetention` on your WORM bucket.

## GCP Setup (Reference)

See `gcp/wif-config.yaml` for the equivalent GCP configuration using
`google-github-actions/auth@v2`. GCP is not currently used in this project.

## CI Workflow

Once AWS is configured, the workflow `.github/workflows/worm-audit.yml` uploads
`tools/itil5-ai-governance/approvals.log` to WORM storage on every push to that file,
and is also triggerable manually via `workflow_dispatch`.

## Security Properties

| Property | Static IAM key | OIDC federation |
|----------|---------------|-----------------|
| Credential lifetime | Long-lived (manual rotation) | 15 minutes (automatic) |
| Stored in GitHub | As a Secret | Not stored |
| Rotation required | Yes | No |
| Scope | Full IAM user permissions | Role policy only |
| Audit trail | IAM access logs | CloudTrail + OIDC claims |

---

## 日本語版

このディレクトリには、長期間有効なクラウド認証情報を OIDC フェデレーション経由の
短命トークンに置き換えるための IaC テンプレートが含まれています。

### なぜ必要か

`worm_storage.py` による S3 WORM ストレージの利用には現在 AWS 認証情報が必要です。
CI 環境では長期有効な IAM アクセスキーを GitHub Secrets に保管する必要があり、
"Trustless" の設計哲学に反します。

Workload Identity Federation により、GitHub Actions が発行する短命 OIDC トークン
（有効期限 ~10 分）を AWS STS と交換して一時クレデンシャルを取得します。
長期有効なキーをどこにも保管する必要がありません。

### 仕組み

1. GitHub Actions ジョブが起動すると、GitHub が OIDC トークン（JWT）を発行
2. `aws-actions/configure-aws-credentials` が AWS STS にトークンを送信
3. AWS が登録済み OIDC Provider に対してトークンを検証
4. 検証成功後、15 分有効の一時クレデンシャルを発行
5. boto3 の標準クレデンシャルチェーンが自動でピックアップ → **コード変更不要**

### AWS セットアップ（CloudFormation）

```bash
aws cloudformation deploy \
  --template-file tools/wif/aws/oidc-provider.yml \
  --stack-name ai-infra-wif \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    GitHubOrg=tiktax \
    GitHubRepo=ai-infra-portfolio \
    WORMBucketName=<your-worm-bucket>
```

その後、以下の GitHub Variables を設定（Secrets ではなく Variables — ARN に機密情報なし）:

| Variable | 値 |
|----------|---|
| `AWS_WIF_ROLE_ARN` | CloudFormation の `RoleArn` 出力値 |
| `AWS_WORM_BUCKET` | S3 バケット名 |
| `AWS_REGION` | リージョン（省略可、デフォルト: ap-northeast-1） |

### セキュリティ比較

| 項目 | 静的 IAM キー | OIDC フェデレーション |
|------|-------------|-------------------|
| 有効期限 | 長期（手動ローテーション） | 15 分（自動） |
| GitHub への保管 | Secret として保管 | 保管不要 |
| ローテーション | 必要 | 不要 |
| スコープ | IAM ユーザー全権限 | ロールポリシーのみ |
