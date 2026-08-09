#!/usr/bin/env bash
# =============================================================================
# HTH JFrog Control 1.2: Implement Permission Targets
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 AC-3, AC-6
# Source: https://howtoharden.com/guides/jfrog/#12-implement-permission-targets
# Reference: https://docs.jfrog.com/administration/reference/createPermission
#            https://docs.jfrog.com/administration/reference/getPermissions
#            https://docs.jfrog.com/administration/reference/getPermissionDetails
# Requires: Access API v2 (Artifactory 7.72.0+); an admin-privileged access
# token (or a scoped token with system:permissions:r for the audit region).
# Action strings used (READ, ANNOTATE) are the values documented in the
# vendor's createPermission example body.
# =============================================================================

set -euo pipefail

: "${JFROG_URL:?Set JFROG_URL (e.g. https://mycompany.jfrog.io)}"
: "${JFROG_ACCESS_TOKEN:?Set JFROG_ACCESS_TOKEN}"

# HTH Guide Excerpt: begin create-least-privilege-permission

# --- Create a read-only permission confining developers to the release repo ---
# POST /access/api/v2/permissions (Access API v2, Artifactory 7.72.0+)
echo "=== Creating permission: production-read ==="
curl -s -X POST \
  -H "Authorization: Bearer ${JFROG_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  "${JFROG_URL}/access/api/v2/permissions" \
  -d @- <<'JSON'
{
  "name": "production-read",
  "resources": {
    "artifact": {
      "actions": {
        "users": {},
        "groups": {
          "developers": ["READ", "ANNOTATE"]
        }
      },
      "targets": {
        "libs-release-local": {
          "include_patterns": ["**"],
          "exclude_patterns": []
        }
      }
    }
  }
}
JSON

# HTH Guide Excerpt: end create-least-privilege-permission

# HTH Guide Excerpt: begin audit-anonymous-and-broad-grants

# --- Audit every permission for anonymous grants and over-broad targets ---
# GET /access/api/v2/permissions lists names; each detail comes from
# GET /access/api/v2/permissions/{permissionName}
echo "=== Auditing permissions for anonymous grants ==="
PERM_NAMES=$(curl -s \
  -H "Authorization: Bearer ${JFROG_ACCESS_TOKEN}" \
  "${JFROG_URL}/access/api/v2/permissions?limit=1000" | jq -r '.permissions[].name')

while IFS= read -r name; do
  [ -z "${name}" ] && continue
  detail=$(curl -s \
    -H "Authorization: Bearer ${JFROG_ACCESS_TOKEN}" \
    "${JFROG_URL}/access/api/v2/permissions/$(jq -rn --arg n "${name}" '$n|@uri')")

  # Flag any grant to the anonymous user (artifact poisoning risk)
  anon=$(echo "${detail}" | jq -r '
    [.resources[]?.actions.users? // {} | to_entries[]
     | select(.key == "anonymous") | .value[]] | unique | join(",")')
  if [ -n "${anon}" ]; then
    echo "FLAG: ${name} grants anonymous: ${anon}"
  fi

  # Flag write-capable grants whose target include pattern is a bare "**"
  echo "${detail}" | jq -r --arg perm "${name}" '
    select(
      ([.resources.artifact.actions.users? // {}, .resources.artifact.actions.groups? // {}
        | to_entries[] | .value[]] | map(. != "READ" and . != "ANNOTATE") | any)
      and
      ([.resources.artifact.targets? // {} | to_entries[]
        | .value.include_patterns[]?] | index("**") != null)
    )
    | "REVIEW: \($perm) grants non-read actions across include pattern ** — scope it down"'
done <<< "${PERM_NAMES}"

echo "Audit complete."

# HTH Guide Excerpt: end audit-anonymous-and-broad-grants
