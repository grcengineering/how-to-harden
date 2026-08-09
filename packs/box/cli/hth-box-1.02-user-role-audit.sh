#!/usr/bin/env bash
# HTH Box Control 1.2: Role-Based Access
# Profile: L1 | NIST 800-53: AC-3, AC-6
# https://howtoharden.com/guides/box/#12-role-based-access
#
# Audits Box enterprise users for excessive admin/co-admin role grants using
# the first-party Box CLI (`box`).
#   CLI docs:   https://developer.box.com/guides/tooling/cli/
#   Command:    https://github.com/box/boxcli/blob/main/docs/users.md
#   Role field: https://developer.box.com/reference/get-users/ (role: admin, coadmin, user)
#
# Prerequisites: Box CLI installed and authenticated (`box configure:environments:add`),
# jq installed. The authenticated app/user must be able to list enterprise users.
set -euo pipefail

command -v box >/dev/null 2>&1 || { echo "ERROR: box CLI not found" >&2; exit 1; }
command -v jq  >/dev/null 2>&1 || { echo "ERROR: jq not found" >&2; exit 1; }

# Maximum admin+coadmin accounts before the audit flags the tenant
MAX_PRIVILEGED="${MAX_PRIVILEGED:-5}"

# HTH Guide Excerpt: begin cli-audit-user-roles
# List every enterprise user with their role and status.
# --all-users includes managed, app, and external users; --fields limits the
# response to the attributes this audit needs (role values: admin, coadmin, user).
USERS_JSON=$(box users --all-users --json --fields id,name,login,role,status)

TOTAL=$(echo "${USERS_JSON}" | jq 'length')
ADMINS=$(echo "${USERS_JSON}" | jq '[.[] | select(.role == "admin")] | length')
COADMINS=$(echo "${USERS_JSON}" | jq '[.[] | select(.role == "coadmin")] | length')

echo "Total users:   ${TOTAL}"
echo "Admins:        ${ADMINS}"
echo "Co-admins:     ${COADMINS}"

# List every privileged account for review — each of these can change
# sharing settings, reach enterprise content, or modify other accounts.
echo "Privileged accounts (admin/coadmin):"
echo "${USERS_JSON}" | jq -r \
  '.[] | select(.role == "admin" or .role == "coadmin")
       | "  \(.role)\t\(.login)\t\(.status)"'
# HTH Guide Excerpt: end cli-audit-user-roles

# HTH Guide Excerpt: begin cli-flag-inactive-privileged
# Privileged accounts that are not active should be removed, not left parked:
# a disabled co-admin is one re-enable away from full enterprise reach.
echo "Privileged accounts not in active status:"
echo "${USERS_JSON}" | jq -r \
  '.[] | select((.role == "admin" or .role == "coadmin") and .status != "active")
       | "  REVIEW: \(.role) \(.login) status=\(.status)"'
# HTH Guide Excerpt: end cli-flag-inactive-privileged

PRIVILEGED=$((ADMINS + COADMINS))
if [ "${PRIVILEGED}" -gt "${MAX_PRIVILEGED}" ]; then
  echo "FAIL: ${PRIVILEGED} privileged accounts exceed threshold of ${MAX_PRIVILEGED}" >&2
  exit 1
fi
echo "PASS: privileged account count (${PRIVILEGED}) within threshold (${MAX_PRIVILEGED})"
