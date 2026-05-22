"""
worm_storage.py — AWS S3 Object Lock (WORM) storage for immutable audit logs

WORM = Write Once, Read Many
S3 Object Lock COMPLIANCE mode prevents deletion or overwrite for the retention period,
even by root/admin users, providing 7-year immutability guarantee.

Requires: pip install boto3>=1.34.0
AWS credentials: use 1Password via op run (never hardcode)

Example:
    op run --env-file=tools/trustless_audit/.env.aws.1password -- \\
      python tools/trustless_audit/scripts/worm_upload.py \\
        --log tools/itil5-ai-governance/approvals.log \\
        --bucket my-audit-worm-bucket \\
        --key 2026/approvals.log
"""

from datetime import datetime, timezone, timedelta
from pathlib import Path

# Lazy import — boto3 not required for generate_worm_config_example()
try:
    import boto3
    from botocore.exceptions import ClientError
    _BOTO3_AVAILABLE = True
except ImportError:
    _BOTO3_AVAILABLE = False


def _require_boto3() -> None:
    if not _BOTO3_AVAILABLE:
        raise ImportError(
            "WORM storage requires boto3. "
            "Run: pip install boto3>=1.34.0"
        )


def upload_to_worm(
    file_path: str,
    bucket: str,
    key: str,
    retention_years: int = 7,
    region: str = "ap-northeast-1",
) -> dict:
    """
    Upload a file to S3 with Object Lock COMPLIANCE mode.

    The file cannot be deleted or overwritten until the retention period expires,
    even by the bucket owner or AWS root.

    Args:
        file_path:       Local file to upload
        bucket:          S3 bucket name (must have Object Lock enabled)
        key:             S3 object key (path within bucket)
        retention_years: Retention period in years (default: 7)
        region:          AWS region (default: ap-northeast-1 / Tokyo)

    Returns:
        {
            "s3_url": str,
            "etag": str,
            "version_id": str,
            "retain_until": datetime,
            "size_bytes": int,
        }

    Raises:
        ImportError: if boto3 is not installed
        ClientError: if S3 upload fails (bucket not found, permissions, etc.)
    """
    _require_boto3()

    retain_until = datetime.now(timezone.utc) + timedelta(days=365 * retention_years)

    s3 = boto3.client("s3", region_name=region)
    file_data = Path(file_path).read_bytes()

    response = s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=file_data,
        ContentType="application/jsonl",
        ObjectLockMode="COMPLIANCE",
        ObjectLockRetainUntilDate=retain_until,
    )

    s3_url = f"s3://{bucket}/{key}"
    return {
        "s3_url": s3_url,
        "etag": response.get("ETag", "").strip('"'),
        "version_id": response.get("VersionId", ""),
        "retain_until": retain_until,
        "size_bytes": len(file_data),
    }


def verify_worm_protection(bucket: str, key: str, region: str = "ap-northeast-1") -> dict:
    """
    Check Object Lock configuration for an S3 object.

    Returns:
        {
            "locked": bool,
            "mode": str or None,       # "COMPLIANCE" or "GOVERNANCE"
            "retain_until": datetime or None,
        }
    """
    _require_boto3()

    s3 = boto3.client("s3", region_name=region)
    try:
        response = s3.get_object_retention(Bucket=bucket, Key=key)
        retention = response.get("Retention", {})
        retain_until = retention.get("RetainUntilDate")
        mode = retention.get("Mode")
        return {
            "locked": mode is not None,
            "mode": mode,
            "retain_until": retain_until,
        }
    except ClientError as e:
        code = e.response["Error"]["Code"]
        return {
            "locked": False,
            "mode": None,
            "retain_until": None,
            "error": code,
        }


def generate_worm_config_example() -> str:
    """
    Return a CloudFormation template snippet for an S3 WORM bucket.
    No boto3 or AWS credentials required — pure string output.

    Returns:
        CloudFormation YAML string
    """
    return """# AWS CloudFormation — S3 WORM Bucket for Audit Log Immutability
# Deploy: aws cloudformation deploy --template-file worm-bucket.yaml --stack-name audit-worm

AWSTemplateFormatVersion: "2010-09-09"
Description: "S3 WORM bucket for ITIL 5 audit log immutability (7-year retention)"

Parameters:
  BucketName:
    Type: String
    Default: "my-ai-audit-worm"
    Description: "Must be globally unique"
  RetentionYears:
    Type: Number
    Default: 7
    Description: "Retention period in years (COMPLIANCE mode = cannot be shortened)"

Resources:
  AuditWormBucket:
    Type: AWS::S3::Bucket
    DeletionPolicy: Retain          # Bucket survives stack deletion
    Properties:
      BucketName: !Ref BucketName
      VersioningConfiguration:
        Status: Enabled             # Required for Object Lock
      ObjectLockConfiguration:
        ObjectLockEnabled: Enabled
        Rule:
          DefaultRetention:
            Mode: COMPLIANCE        # Cannot be overridden, even by root
            Years: !Ref RetentionYears
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: aws:kms
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      Tags:
        - Key: Purpose
          Value: "ITIL5-AuditLog-WORM"
        - Key: RetentionPolicy
          Value: "7-years-compliance"

Outputs:
  BucketArn:
    Value: !GetAtt AuditWormBucket.Arn
  BucketName:
    Value: !Ref AuditWormBucket
"""
