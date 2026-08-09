#!/usr/bin/env bash
# HTH 1Password Control 2.4: Implement Role-Based Access
# Profile: L1 | CIS Controls: 5.4 | NIST 800-53: AC-6(1)
# https://howtoharden.com/guides/1password/#24-implement-role-based-access
#
# Audits privileged group membership with the first-party 1Password CLI (op).
# Requires: op CLI signed in to the account (op signin).
# Verified against: https://www.1password.dev/cli/reference/management-commands/group/
#                   https://www.1password.dev/cli/reference/management-commands/user/
set -euo pipefail

command -v op >/dev/null || { echo "ERROR: 1Password CLI (op) not found" >&2; exit 1; }

# HTH Guide Excerpt: begin cli-audit-privileged-groups
# Enumerate every group in the account, then list the members of the two
# built-in privileged groups. Keep Owners to 1-2 people and grant
# Administrators only to working IT/security staff.
echo "== All groups in the account =="
op group list

for GROUP in "Owners" "Administrators"; do
  echo ""
  echo "== Members of ${GROUP} (with their role in the group) =="
  # --group filters to users belonging to the group; the output includes
  # each user's role within that group.
  op user list --group "${GROUP}"
done
# HTH Guide Excerpt: end cli-audit-privileged-groups

# HTH Guide Excerpt: begin cli-review-group-membership-detail
# Pull the full record for every member of a privileged group for an access
# review (documented pattern: pipe list JSON into 'op user get -').
GROUP="${1:-Administrators}"
echo "== Detailed member records for ${GROUP} =="
op user list --group "${GROUP}" --format=json | op user get -
# HTH Guide Excerpt: end cli-review-group-membership-detail
