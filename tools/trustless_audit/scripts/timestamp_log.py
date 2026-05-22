#!/usr/bin/env python3
"""
timestamp_log.py — CLI for RFC 3161 timestamping of audit log files

Usage:
    python scripts/timestamp_log.py --log tools/itil5-ai-governance/approvals.log
    python scripts/timestamp_log.py --log approvals.log --tsa https://freetsa.org/tsr
    python scripts/timestamp_log.py --log approvals.log --verify-only
"""
import argparse
import sys
from pathlib import Path

# Allow running from repo root or from scripts/ directory
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
    from src.timestamp import timestamp_log_file, load_and_verify_timestamp, DEFAULT_TSA_URL
except ImportError:
    from tools.trustless_audit.src.timestamp import (
        timestamp_log_file, load_and_verify_timestamp, DEFAULT_TSA_URL
    )


def main():
    parser = argparse.ArgumentParser(description="RFC 3161 timestamp for audit log files")
    parser.add_argument("--log", required=True, help="Path to log file to timestamp")
    parser.add_argument("--tsa", default=DEFAULT_TSA_URL, help=f"TSA URL (default: {DEFAULT_TSA_URL})")
    parser.add_argument("--verify-only", action="store_true",
                        help="Only verify existing .tsr token, do not request new one")
    args = parser.parse_args()

    if args.verify_only:
        print(f"Verifying timestamp for: {args.log}")
        result = load_and_verify_timestamp(args.log)
        if result["valid"]:
            ts = result.get("timestamp")
            print(f"✓ VALID — timestamped at: {ts}")
            if result.get("reason"):
                print(f"  Note: {result['reason']}")
        else:
            print(f"✗ INVALID — {result.get('reason', 'unknown error')}")
            sys.exit(1)
    else:
        print(f"Requesting timestamp for: {args.log}")
        print(f"TSA: {args.tsa}")
        token_path = timestamp_log_file(args.log, tsa_url=args.tsa)
        print(f"Token saved: {token_path}")


if __name__ == "__main__":
    main()
