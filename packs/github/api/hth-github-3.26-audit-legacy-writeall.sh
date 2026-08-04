#!/usr/bin/env bash
# HTH GitHub Control 3.2: Audit Legacy write-all GITHUB_TOKEN Permissions
# Profile: L1 | NIST: AC-6 | SLSA: Build L2
# https://howtoharden.com/guides/github/#32-use-least-privilege-workflow-permissions
#
# Identifies repositories still using the legacy write-all default for
# GITHUB_TOKEN. Repos created before Feb 2023 may have this dangerous default.
# The Shai Hulud worm (Nov 2025) spread through repos with write-all tokens.

set -euo pipefail

# HTH Guide Excerpt: begin audit-legacy-writeall
# Audit all organization repositories for dangerous legacy GITHUB_TOKEN defaults.
# Repos created before Feb 2023 may still grant write-all permissions by default.
# The Shai Hulud worm (Nov 2025) propagated through repos with this configuration.
#
# Usage: ./hth-github-3.16-audit-legacy-writeall.sh <org-name>
# Requires: gh CLI authenticated with org admin access

ORG="${1:?Usage: $0 <org-name>}"

echo "=== GITHUB_TOKEN Legacy write-all Audit ==="
echo "Organization: ${ORG}"
echo ""

# Get all repos and check their default workflow permissions
RISKY_COUNT=0
TOTAL_COUNT=0

gh api --paginate "/orgs/${ORG}/repos?per_page=100" \
  --jq '.[] | [.name, .created_at, .default_branch] | @tsv' | \
while IFS=$'\t' read -r repo_name created_at default_branch; do
  TOTAL_COUNT=$((TOTAL_COUNT + 1))

  # Check the repo's Actions permission settings
  permissions=$(gh api "/repos/${ORG}/${repo_name}/actions/permissions/workflow" \
    --jq '.default_workflow_permissions' 2>/dev/null || echo "unknown")

  if [ "$permissions" = "write" ]; then
    created_year=$(echo "$created_at" | cut -c1-4)
    echo "  [RISKY] ${repo_name} — default_workflow_permissions: write (created: ${created_at})"
    RISKY_COUNT=$((RISKY_COUNT + 1))
  fi
done

echo ""
echo "=== Audit Complete ==="
echo "Total repositories: ${TOTAL_COUNT}"
echo "Repositories with write-all default: ${RISKY_COUNT}"

if [ "$RISKY_COUNT" -gt 0 ]; then
  echo ""
  echo "REMEDIATION: For each risky repository, update the default:"
  echo "  gh api -X PUT /repos/${ORG}/<repo>/actions/permissions/workflow \\"
  echo "    -f default_workflow_permissions=read \\"
  echo "    -F can_approve_pull_request_reviews=false"
  echo ""
  echo "Or set organization-wide:"
  echo "  gh api -X PUT /orgs/${ORG}/actions/permissions/workflow \\"
  echo "    -f default_workflow_permissions=read \\"
  echo "    -F can_approve_pull_request_reviews=false"
fi
# HTH Guide Excerpt: end audit-legacy-writeall
