#!/usr/bin/env bash
# Control: 5.2 Stream Audit Logs Continuously to S3
# Profile Level: L2 (Walk)
# Frameworks: NIST 800-53 AU-9/AU-4, CIS Controls v8 8, SOC 2 CC7.2
# Guide: https://howtoharden.com/guides/kernel/
# Interface: Kernel CLI (first-party) — https://www.kernel.sh/docs/reference/cli/audit-logs
# Plan: continuous S3 export requires an active Enterprise plan.
set -euo pipefail

# HTH Guide Excerpt: begin create-export-destination
# 1. Create the destination — it starts PAUSED by design.
kernel audit-logs export create \
  --region us-east-1 \
  --bucket customer-audit-logs \
  --prefix kernel/audit \
  --role-arn arn:aws:iam::123456789012:role/kernel-audit-export

# 2. The response returns kernel_role_arn and external_id. Update YOUR
#    IAM role's trust policy to allow that kernel_role_arn to assume it,
#    WITH the sts:ExternalId condition set to the returned external_id —
#    the documented defense against confused-deputy access to your bucket.
#    Grant the role S3 write (and KMS, if the bucket is KMS-encrypted).
# HTH Guide Excerpt: end create-export-destination

# HTH Guide Excerpt: begin test-then-activate
# 3. Test BEFORE activating: Kernel assumes the configured role and
#    uploads a probe object with the same request metadata as a real delivery.
kernel audit-logs export test dest_01example

# 4. Activate once the test passes; delivery writes partitioned jsonl.gz
#    objects under .../date=YYYY-MM-DD/hour=HH/ prefixes.
kernel audit-logs export resume dest_01example

# Operate: list, inspect, pause, or remove destinations.
kernel audit-logs export list
kernel audit-logs export get dest_01example
# HTH Guide Excerpt: end test-then-activate
