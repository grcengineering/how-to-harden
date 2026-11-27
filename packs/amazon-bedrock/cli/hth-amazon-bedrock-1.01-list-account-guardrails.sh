#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: amazon-bedrock-1.1
#   guide: https://howtoharden.com/guides/amazon-bedrock/#11-enforce-a-reviewed-guardrail-version
#   profile: L2
#   mode: read-only
#   requires: AWS CLI v2 (or boto3 for SDK), scoped credentials and target Region
# HTH amazon-bedrock 1.1: Enforce a reviewed guardrail version
# Profile: L2 (Walk)
# Guide: https://howtoharden.com/guides/amazon-bedrock/
# Reference: https://docs.aws.amazon.com/cli/latest/reference/bedrock/list-enforced-guardrails-configuration.html
# HTH Guide Excerpt: begin list-account-guardrails
set -euo pipefail
: "${AWS_REGION:?Set the intended AWS Region}"
aws bedrock list-enforced-guardrails-configuration --region "$AWS_REGION" \
  --output json --no-cli-pager
# HTH Guide Excerpt: end list-account-guardrails
