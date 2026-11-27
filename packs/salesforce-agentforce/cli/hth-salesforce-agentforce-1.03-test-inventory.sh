#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: salesforce-agentforce-1.3
#   guide: https://howtoharden.com/guides/salesforce-agentforce/#13-inventory-release-tests-before-activation
#   profile: L1
#   mode: read-only
#   requires: bash, Salesforce CLI, authenticated development org alias
# Source (checked 2026-11-27): https://developer.salesforce.com/docs/platform/salesforce-cli-reference/guide/cli_reference_agent_test_list.html
# HTH Control 1.3: Inventory release tests before activation (SA-11) (L1)
# Guide: https://howtoharden.com/guides/salesforce-agentforce/
# Requires first-party Salesforce CLI and an authenticated development org alias.
# Lists test definitions; does not run tests, activate an agent or write configuration.

# HTH Guide Excerpt: begin salesforce-agentforce-evidence
set +x
set -euo pipefail
: "${HTH_SF_TARGET_ORG:?Set a development org alias explicitly}"
if [[ ! "$HTH_SF_TARGET_ORG" =~ ^[A-Za-z0-9][A-Za-z0-9._@+-]*$ ]]; then
  printf 'Invalid Salesforce org alias.\n' >&2
  exit 2
fi
sf agent test list --target-org "$HTH_SF_TARGET_ORG" --json
# HTH Guide Excerpt: end salesforce-agentforce-evidence
