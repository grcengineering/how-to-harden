#!/usr/bin/env bash
# HTH 1Password Control 3.1: Configure Vault Permissions
# Profile: L1 | CIS Controls: 3.3 | NIST 800-53: AC-3
# https://howtoharden.com/guides/1password/#31-configure-vault-permissions
#
# Audits who (users and groups) can reach a vault, using the first-party
# 1Password CLI (op). Requires: op CLI signed in to the account (op signin).
# Verified against: https://www.1password.dev/cli/reference/management-commands/vault/
set -euo pipefail

command -v op >/dev/null || { echo "ERROR: 1Password CLI (op) not found" >&2; exit 1; }

# HTH Guide Excerpt: begin cli-vault-access-inventory
# Inventory all vaults the signed-in account can read, then list the users
# and groups with access to one vault. Review each sensitive vault against
# the least-privilege structure in the guide (private / team /
# infrastructure / executive).
echo "== All vaults =="
op vault list

VAULT="${1:?Usage: $0 <vault-name-or-id> [user-email]}"
echo ""
echo "== Vault: ${VAULT} — users with direct access =="
op vault user list "${VAULT}"

echo ""
echo "== Vault: ${VAULT} — groups with access =="
op vault group list "${VAULT}"
# HTH Guide Excerpt: end cli-vault-access-inventory

# HTH Guide Excerpt: begin cli-vaults-reachable-by-member
# Reverse view for access reviews and offboarding: every vault a specific
# user can reach, then only the vaults where that user can manage the
# vault itself (granular Business permission: manage_vault).
if [ -n "${2:-}" ]; then
  MEMBER="${2}"
  echo "== Vaults reachable by ${MEMBER} =="
  op vault list --user "${MEMBER}"

  echo ""
  echo "== Vaults where ${MEMBER} holds manage_vault =="
  op vault list --user "${MEMBER}" --permission manage_vault
fi
# HTH Guide Excerpt: end cli-vaults-reachable-by-member
