#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: amazon-bedrock-3.1
#   guide: https://howtoharden.com/guides/amazon-bedrock/#31-review-and-constrain-model-invocation-logging
#   profile: L2
#   mode: read-only
#   requires: AWS CLI v2 (or boto3 for SDK), scoped credentials and target Region
# HTH amazon-bedrock 3.1: Review and constrain model invocation logging
# Profile: L2 (Walk)
# Guide: https://howtoharden.com/guides/amazon-bedrock/
# Reference: https://docs.aws.amazon.com/cli/latest/reference/bedrock/get-model-invocation-logging-configuration.html
# HTH Guide Excerpt: begin read-invocation-logging
set -euo pipefail
: "${AWS_REGION:?Set the intended AWS Region}"
aws bedrock get-model-invocation-logging-configuration --region "$AWS_REGION" \
  --output json --no-cli-pager
# HTH Guide Excerpt: end read-invocation-logging
