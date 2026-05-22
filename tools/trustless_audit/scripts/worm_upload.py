#!/usr/bin/env python3
"""
worm_upload.py — CLI for uploading audit logs to S3 WORM storage

Usage (via 1Password):
    op run --env-file=tools/trustless_audit/.env.aws.1password -- \\
      python tools/trustless_audit/scripts/worm_upload.py \\
        --log tools/itil5-ai-governance/approvals.log \\
        --bucket my-audit-worm-bucket \\
        --key 2026/approvals.log

    python tools/trustless_audit/scripts/worm_upload.py --example-config
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
    from src.worm_storage import upload_to_worm, verify_worm_protection, generate_worm_config_example
except ImportError:
    from tools.trustless_audit.src.worm_storage import (
        upload_to_worm, verify_worm_protection, generate_worm_config_example
    )


def main():
    parser = argparse.ArgumentParser(description="Upload audit log to S3 WORM storage")
    parser.add_argument("--log", help="Path to log file to upload")
    parser.add_argument("--bucket", help="S3 bucket name (Object Lock enabled)")
    parser.add_argument("--key", help="S3 object key")
    parser.add_argument("--region", default="ap-northeast-1", help="AWS region")
    parser.add_argument("--retention-years", type=int, default=7)
    parser.add_argument("--verify", action="store_true",
                        help="Verify WORM protection on existing S3 object")
    parser.add_argument("--example-config", action="store_true",
                        help="Print CloudFormation config example (no AWS needed)")
    args = parser.parse_args()

    if args.example_config:
        print(generate_worm_config_example())
        return

    if not args.log or not args.bucket or not args.key:
        parser.error("--log, --bucket, and --key are required (or use --example-config)")

    if args.verify:
        print(f"Verifying WORM protection: s3://{args.bucket}/{args.key}")
        result = verify_worm_protection(args.bucket, args.key, region=args.region)
        if result.get("locked"):
            print(f"✓ LOCKED ({result['mode']}) — retain until: {result['retain_until']}")
        else:
            print(f"✗ NOT LOCKED — {result.get('error', 'no retention policy')}")
            sys.exit(1)
    else:
        print(f"Uploading {args.log} → s3://{args.bucket}/{args.key}")
        result = upload_to_worm(
            args.log, args.bucket, args.key,
            retention_years=args.retention_years,
            region=args.region,
        )
        print(f"✓ Uploaded: {result['s3_url']}")
        print(f"  ETag:         {result['etag']}")
        print(f"  Version ID:   {result['version_id']}")
        print(f"  Retain until: {result['retain_until'].isoformat()}")
        print(f"  Size:         {result['size_bytes']} bytes")


if __name__ == "__main__":
    main()
