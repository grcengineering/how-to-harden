#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 1.5: Audit Third-Party Integrations and OAuth Grants
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-6, SA-12, CM-8
# Source: https://howtoharden.com/guides/vercel/#15-audit-third-party-integrations
# Driver: Vercel April 2026 incident - compromised Context.ai OAuth token
#         enabled lateral movement into Vercel internal environment.
#         See: https://vercel.com/kb/bulletin/vercel-april-2026-security-incident
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin api

# --- List all installed Vercel Marketplace integrations for the team ---
echo "=== Installed Vercel Integrations ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v1/integrations/configurations?teamId=${VERCEL_TEAM_ID}&view=account" | \
  jq '.configurations[]? | {
    id,
    integrationId,
    slug,
    projects: (.projects | length),
    createdAt,
    installerEmail: .ownerId
  }'

# --- List all connected Git accounts (GitHub/GitLab/Bitbucket) ---
echo ""
echo "=== Connected Git Accounts (review for unused or stale links) ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v1/integrations/git-namespaces?teamId=${VERCEL_TEAM_ID}" | \
  jq '.[]? | {
    provider,
    name,
    slug,
    installationId
  }'

# --- List projects with fork-protection disabled (supply chain risk) ---
echo ""
echo "=== Projects WITHOUT Git Fork Protection (review immediately) ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v10/projects?teamId=${VERCEL_TEAM_ID}&limit=100" | \
  jq '.projects[] | select(.gitForkProtection != true) | {id, name, gitForkProtection}'

# --- List deploy hooks across projects (any hook URL == credential) ---
echo ""
echo "=== Deploy Hooks Inventory (each URL is an unauthenticated trigger) ==="
for project_id in $(curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v10/projects?teamId=${VERCEL_TEAM_ID}&limit=100" | \
  jq -r '.projects[].id'); do
  hooks=$(curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
    "https://api.vercel.com/v1/projects/${project_id}/deploy-hooks?teamId=${VERCEL_TEAM_ID}" | \
    jq -r '.[]? | "\(.id)\t\(.name)\t\(.ref)\t\(.createdAt)"' 2>/dev/null || true)
  if [ -n "${hooks}" ]; then
    echo "Project: ${project_id}"
    echo "${hooks}"
  fi
done

# --- Check Protection Bypass for Automation configuration ---
echo ""
echo "=== Projects with Protection Bypass for Automation Enabled ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v10/projects?teamId=${VERCEL_TEAM_ID}&limit=100" | \
  jq '.projects[] | select(.passwordProtection != null or .vercelAuthentication != null) | {
    id, name,
    vercelAuthentication: .vercelAuthentication.deploymentType,
    passwordProtection: .passwordProtection.deploymentType,
    bypassEnabled: (.protectionBypass != null and (.protectionBypass | keys | length > 0))
  }'

# --- External audit checklist: OAuth grants in other identity providers ---
echo ""
echo "=== EXTERNAL AUDIT CHECKLIST (perform in each system) ==="
cat <<'CHECKLIST'
Google Workspace:
  admin.google.com -> Security -> API Controls -> Third-party app access
  Revoke: unrecognized apps, any with "View and manage all Google Drive files" or
          "See, edit, create, and delete Google Drive files" that are not business-critical.

GitHub Organization:
  github.com/organizations/<org>/settings/oauth_application_policy
  Review: installed OAuth apps and installed GitHub Apps (incl. Vercel app scope).
  Restrict Vercel GitHub App to specific repositories, not all-org.

Microsoft Entra ID:
  entra.microsoft.com -> Enterprise applications
  Filter by "Application type = Enterprise applications" and review consented permissions.

Slack:
  <workspace>.slack.com/apps/manage -> Installed apps
  Audit scopes for each app; remove any unused integrations.
CHECKLIST

# HTH Guide Excerpt: end api
