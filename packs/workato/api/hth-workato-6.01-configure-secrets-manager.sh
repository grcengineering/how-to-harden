#!/usr/bin/env bash
# HTH Workato Control 6.01: Configure External Secrets Manager Integration
# Profile: L3 | NIST: SC-12, IA-5(7)
# https://howtoharden.com/guides/workato/#61-configure-external-secrets-manager-integration

# HTH Guide Excerpt: begin api-store-secret
# Store a connection credential in AWS Secrets Manager
aws secretsmanager create-secret \
  --name "workato/connections/salesforce-prod" \
  --description "Workato Salesforce production connection credentials" \
  --secret-string '{
    "client_id": "3MVG9...",
    "client_secret": "...",
    "refresh_token": "..."
  }' \
  --tags Key=Application,Value=Workato Key=Connection,Value=Salesforce

# Enable automatic rotation (90-day cycle)
aws secretsmanager rotate-secret \
  --secret-id "workato/connections/salesforce-prod" \
  --rotation-rules AutomaticallyAfterDays=90
# HTH Guide Excerpt: end api-store-secret
