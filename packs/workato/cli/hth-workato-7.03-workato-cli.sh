#!/usr/bin/env bash
# HTH Workato Control 7.03: Implement CI/CD Pipeline Integration
# Profile: L3 | NIST: SA-10, CM-3
# https://howtoharden.com/guides/workato/#73-implement-cicd-pipeline-integration

# HTH Guide Excerpt: begin cli-github-actions-pipeline
# .github/workflows/workato-deploy.yml
# ---
# name: Workato Recipe Deployment
# on:
#   push:
#     branches: [main]
#     paths: ['workato/**']
#
# jobs:
#   validate:
#     runs-on: ubuntu-latest
#     steps:
#       - uses: actions/checkout@v4
#       - name: Validate recipe package
#         run: |
#           curl -sf "https://www.workato.com/api/packages/export/$MANIFEST_ID" \
#             -H "Authorization: Bearer $WORKATO_DEV_TOKEN" -o package.zip
#           test -s package.zip || exit 1
#
#   deploy:
#     needs: validate
#     runs-on: ubuntu-latest
#     environment: production
#     steps:
#       - uses: actions/checkout@v4
#       - name: Export package from DEV
#         run: |
#           curl -sf -X POST \
#             "https://www.workato.com/api/packages/export/$MANIFEST_ID" \
#             -H "Authorization: Bearer $WORKATO_DEV_TOKEN" -o package.zip
#       - name: Import package to PROD
#         run: |
#           curl -sf -X POST \
#             "https://www.workato.com/api/packages/import/$PROD_FOLDER_ID" \
#             -H "Authorization: Bearer $WORKATO_PROD_TOKEN" \
#             -H "Content-Type: application/octet-stream" \
#             --data-binary @package.zip
#       - name: Verify deployment
#         run: |
#           curl -sf "https://www.workato.com/api/recipes?folder_id=$PROD_FOLDER_ID" \
#             -H "Authorization: Bearer $WORKATO_PROD_TOKEN" | \
#             jq '.result[] | {name, running, updated_at}'
# HTH Guide Excerpt: end cli-github-actions-pipeline

# HTH Guide Excerpt: begin cli-workato-connector-dev
# Install Workato Connector SDK (Ruby gem)
gem install workato-connector-sdk

# Generate a new connector scaffold
workato generate connector my-connector

# Validate connector code locally
workato exec actions.my_action \
  --connector my-connector \
  --input '{"key": "value"}'

# Run connector test suite
workato generate test --connector my-connector
workato exec triggers.my_trigger --connector my-connector

# Push validated connector to Workato workspace
workato push --connector my-connector --token $WORKATO_API_TOKEN
# HTH Guide Excerpt: end cli-workato-connector-dev
