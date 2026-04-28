#!/usr/bin/env bash
# HTH Workato Control 7.03: Implement CI/CD Pipeline Integration
# Profile: L3 | NIST: SA-10, CM-3
# https://howtoharden.com/guides/workato/#73-implement-cicd-pipeline-integration
#
# Uses the first-party Workato Connector SDK CLI (Ruby gem) to develop,
# validate, and push custom connectors as part of a hardened CI/CD pipeline.
# See https://docs.workato.com/developing-connectors/sdk/cli.html

set -euo pipefail

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
workato push --connector my-connector --token "$WORKATO_API_TOKEN"
# HTH Guide Excerpt: end cli-workato-connector-dev
