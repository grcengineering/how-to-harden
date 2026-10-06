#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 1.5: Audit Third-Party Integrations and OAuth Grants
# Profile Level: L1 (Crawl)
# Frameworks: NIST AC-6, SA-12, CM-8
# Source: https://howtoharden.com/guides/vercel/#15-audit-third-party-integrations
# Driver: Vercel April 2026 incident - compromised Context.ai OAuth token
#         enabled lateral movement into Vercel internal environment.
#         See: https://vercel.com/kb/bulletin/vercel-april-2026-security-incident
# API: GET /v1/integrations/configurations (returns a top-level ARRAY),
#      GET /v1/integrations/git-namespaces, GET /v10/projects (every page),
#      GET /v9/projects/{id} (link.deployHooks). Read-only. The identity-provider
#      half of this control (Google Workspace, GitHub, Entra, Slack) is in the
#      guide's ClickOps steps.
# Paging: pagination.next is a timestamp (sent back as `until`, the first-party
#      CLI's convention) or a continuation token (sent back as `from`, the
#      parameter the spec documents for getProjects).
# Exit: 2 when the project list cannot be read completely (the cursor does not
#      advance, an unknown cursor type, or more than 100 pages).
# =============================================================================

set -euo pipefail

: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"

# HTH Guide Excerpt: begin api

# curl -f: an HTTP 4xx/5xx aborts the audit instead of printing an empty inventory.
vercel_get() {
  curl -fsS -H "Authorization: Bearer ${VERCEL_TOKEN}" "https://api.vercel.com$1"
}

# --- Installed Vercel Marketplace integrations (response is a JSON array) ---
echo "=== Installed Vercel Integrations ==="
vercel_get "/v1/integrations/configurations?view=account&teamId=${VERCEL_TEAM_ID}" | \
  jq '.[] | {id, integrationId, slug, status, projects: (.projects // [] | length), scopes, createdAt, ownerId}'

# --- Connected Git namespaces (GitHub/GitLab/Bitbucket) ---
echo ""
echo "=== Connected Git Accounts (review for unused or stale links) ==="
vercel_get "/v1/integrations/git-namespaces" | \
  jq '.[] | {provider, name, slug, installationId, isAccessRestricted}'

# --- One project listing, EVERY page, feeds the three per-project audits below.
#     A walk that cannot finish exits 2 rather than audit a partial list. ---
PROJECTS='[]'
cursor=""
pages=0
while :; do
  pages=$((pages + 1))
  if [ "${pages}" -gt 100 ]; then
    echo "ERROR: /v10/projects paging did not finish within 100 pages -- the audit would be partial (exit 2)." >&2
    exit 2
  fi
  page="$(vercel_get "/v10/projects?teamId=${VERCEL_TEAM_ID}&limit=100${cursor}")"
  merged="$(printf '%s\n%s\n' "${PROJECTS}" "${page}" | jq -c -s '
    (reduce .[0][] as $p ({}; .[$p.id] = true)) as $seen
    | [.[1].projects[] | {id, name, gitForkProtection} | select($seen[.id] | not)] as $new
    | {projects: (.[0] + $new), added: ($new | length)}')"
  PROJECTS="$(printf '%s' "${merged}" | jq -c '.projects')"
  next_type="$(printf '%s' "${page}" | jq -r '.pagination.next | type')"
  [ "${next_type}" = "null" ] && break
  if [ "$(printf '%s' "${merged}" | jq -r '.added')" -eq 0 ]; then
    echo "ERROR: /v10/projects page ${pages} added no new project although pagination.next is set -- paging did not advance (exit 2)." >&2
    exit 2
  fi
  case "${next_type}" in
    number) cursor="&until=$(printf '%s' "${page}" | jq -r '.pagination.next')" ;;
    string) cursor="&from=$(printf '%s' "${page}" | jq -r '.pagination.next | @uri')" ;;
    *) echo "ERROR: unexpected pagination.next type (${next_type}) from /v10/projects (exit 2)." >&2; exit 2 ;;
  esac
done
echo ""
echo "=== Projects audited: $(printf '%s' "${PROJECTS}" | jq 'length') (${pages} page(s)) ==="

echo ""
echo "=== Projects WITHOUT Git Fork Protection (review immediately) ==="
printf '%s' "${PROJECTS}" | \
  jq '.[] | select(.gitForkProtection != true) | {id, name, gitForkProtection}'

# --- Per project (GET /v9/projects/{id}): deploy hooks, Deployment Protection,
#     and Protection Bypass for Automation. Each hook URL is an unauthenticated
#     deploy trigger, so the URL itself is never printed. ---
echo ""
echo "=== Deploy Hooks and Deployment Protection per Project ==="
PROJECT_IDS="$(printf '%s' "${PROJECTS}" | jq -r '.[].id')"
for project_id in ${PROJECT_IDS}; do
  project_json="$(vercel_get "/v9/projects/${project_id}?teamId=${VERCEL_TEAM_ID}")"
  echo "${project_json}" | jq '{
    id, name,
    deployHooks: [.link.deployHooks[]? | {id, name, ref, createdAt}],
    vercelAuthentication: .ssoProtection.deploymentType,
    passwordProtection: .passwordProtection.deploymentType,
    automationBypassEnabled: ((.protectionBypass // {}) | length > 0)
  }'
done

# HTH Guide Excerpt: end api
