#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: amazon-bedrock-2.1
#   guide: https://howtoharden.com/guides/amazon-bedrock/#21-route-production-inference-through-privatelink
#   profile: L2
#   mode: read-only
#   requires: AWS CLI v2 (or boto3 for SDK), scoped credentials and target Region
# HTH amazon-bedrock 2.1: Route production inference through PrivateLink
# Profile: L2 (Walk)
# Guide: https://howtoharden.com/guides/amazon-bedrock/
# Reference: https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-vpc-endpoints.html
# HTH Guide Excerpt: begin describe-runtime-endpoint
set -euo pipefail
: "${AWS_REGION:?Set the intended AWS Region}"
: "${BEDROCK_VPC_ENDPOINT_ID:?Set the approved endpoint ID}"
aws ec2 describe-vpc-endpoints --region "$AWS_REGION" \
  --vpc-endpoint-ids "$BEDROCK_VPC_ENDPOINT_ID" --output json --no-cli-pager
# HTH Guide Excerpt: end describe-runtime-endpoint
