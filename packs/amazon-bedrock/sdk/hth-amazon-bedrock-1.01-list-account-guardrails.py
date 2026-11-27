# HTH Pack Contract: v1
#   control: amazon-bedrock-1.1
#   guide: https://howtoharden.com/guides/amazon-bedrock/#11-enforce-a-reviewed-guardrail-version
#   profile: L2
#   mode: read-only
#   requires: AWS CLI v2 (or boto3 for SDK), scoped credentials and target Region
# HTH amazon-bedrock 1.1: Enforce a reviewed guardrail version
# Profile: L2 (Walk)
# Guide: https://howtoharden.com/guides/amazon-bedrock/
# Reference: https://docs.aws.amazon.com/boto3/latest/reference/services/bedrock/client/list_enforced_guardrails_configuration.html
# HTH Guide Excerpt: begin list-account-guardrails
import json
import os
import boto3

client = boto3.client("bedrock", region_name=os.environ["AWS_REGION"])
pages = client.get_paginator("list_enforced_guardrails_configuration").paginate()
for page in pages:
    for item in page["guardrailsConfig"]:
        print(json.dumps(item, default=str))
# HTH Guide Excerpt: end list-account-guardrails
