#!/usr/bin/env bash
# HTH Keeper Control 2.5: Enable Account Transfer for Departed Employees
# Profile: L1 | CIS Controls: 5.3, 6.2 | NIST 800-53: AC-2, CP-2
# https://howtoharden.com/guides/keeper/#25-enable-account-transfer-for-departed-employees
#
# Interface: Keeper Commander CLI (first-party).
#   transfer-user + action-report: https://docs.keeper.io/en/keeperpam/commander-cli/command-reference/enterprise-management-commands
#   Reporting commands:            https://docs.keeper.io/en/keeperpam/commander-cli/command-reference/reporting-commands
# Prerequisite: an authenticated Commander session with admin privileges, and the
# Account Transfer enforcement policy already enabled for the source user's role
# (transfer cannot be retrofitted after departure — see the guide).

set -euo pipefail

# HTH Guide Excerpt: begin cli-transfer-departed-user
# Transfer a departing employee's vault to an authorized recipient
# as part of the offboarding runbook, before the account is deleted.
keeper --batch-mode - <<'EOF'
transfer-user departing.user@example.com --target-user security-vault-recipient@example.com
EOF
# HTH Guide Excerpt: end cli-transfer-departed-user

# HTH Guide Excerpt: begin cli-bulk-transfer-locked-users
# action-report can act on users by status: transfer the vaults of accounts
# that have been locked for 90+ days to a designated recipient in one pass.
# Run with -n / --dry-run first to preview the affected users.
keeper --batch-mode - <<'EOF'
action-report -t locked -d 90 -a transfer --target-user security-vault-recipient@example.com --dry-run
EOF
# HTH Guide Excerpt: end cli-bulk-transfer-locked-users
