#!/usr/bin/env python3
# HTH CyberArk Control 3.03: Integrate with External Secrets Managers
# Profile: L2 | NIST: IA-5(7)
# Requires: pip install boto3
# https://howtoharden.com/guides/cyberark/#33-integrate-with-external-secrets-managers

# HTH Guide Excerpt: begin sdk-aws-secrets-sync
# Sync CyberArk credentials to AWS Secrets Manager
import boto3
from cyberark import CyberArkClient

def sync_to_aws_secrets(cyberark_client, aws_region):
    secrets_client = boto3.client('secretsmanager', region_name=aws_region)

    credentials = cyberark_client.get_credentials(safe="AWS-Credentials")

    for cred in credentials:
        secrets_client.update_secret(
            SecretId=cred['name'],
            SecretString=cred['password']
        )
# HTH Guide Excerpt: end sdk-aws-secrets-sync
