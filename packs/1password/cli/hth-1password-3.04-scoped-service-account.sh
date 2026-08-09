#!/usr/bin/env bash
# HTH 1Password Control 3.4: Scope and Inventory Service Accounts
# Profile: L2 | CIS Controls: 5.4, 6.8 | NIST 800-53: AC-6, AC-2
# https://howtoharden.com/guides/1password/#34-scope-and-inventory-service-accounts
#
# Creates a least-privilege 1Password Service Account with the first-party
# CLI (op): access to exactly one vault, read-only, with a bounded lifetime.
# Requires: op CLI signed in as an Owner/Administrator (op signin).
# Verified against: https://www.1password.dev/cli/reference/management-commands/service-account/
set -euo pipefail

command -v op >/dev/null || { echo "ERROR: 1Password CLI (op) not found" >&2; exit 1; }

SA_NAME="${1:?Usage: $0 <service-account-name> <vault-name>}"
SA_VAULT="${2:?Usage: $0 <service-account-name> <vault-name>}"

# HTH Guide Excerpt: begin cli-create-scoped-service-account
# One service account per workload, scoped to a single vault, read-only,
# and expiring — never a human account reused for automation.
#
# --vault syntax: <vault-name>:<permission>[,<permission>]
#   Available permissions: read_items, write_items, share_items
# --expires-in bounds the credential's lifetime so a leaked CI secret
#   does not live forever. --raw prints only the token, so it can be
#   piped straight into your secrets manager without touching the log.
op service-account create "${SA_NAME}" \
  --vault "${SA_VAULT}:read_items" \
  --expires-in 90d \
  --raw
# HTH Guide Excerpt: end cli-create-scoped-service-account

# HTH Guide Excerpt: begin cli-service-account-scoping-rules
# Scoping rules for review (the tenant ceiling is 100 service accounts):
#  - grant write_items or share_items only when the workload writes/shares
#  - never pass --can-create-vaults unless vault creation IS the workload
#  - one vault per --vault flag; repeat the flag for each required vault
# Example: a deploy job that reads its own secrets and writes rotation
# results into a dedicated rotation vault, nothing else:
#   op service-account create "deploy-rotator" \
#     --vault "CI-Secrets:read_items" \
#     --vault "Rotation-Results:read_items,write_items" \
#     --expires-in 30d --raw
# HTH Guide Excerpt: end cli-service-account-scoping-rules
