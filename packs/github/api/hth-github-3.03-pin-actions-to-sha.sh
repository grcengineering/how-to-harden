#!/usr/bin/env bash
# HTH GitHub Control 3.03: Pin Actions to SHA
# Profile: L2 | NIST: SA-12, SI-7
# https://howtoharden.com/guides/github/#31-restrict-third-party-github-actions-to-verified-creators-only
#
# Requires the repository to reject tag- and branch-referenced actions
# (sha_pinning_required), leaving its allowed-actions policy unchanged, then audits
# the workflow files for references that the setting will now reject.
source "$(dirname "$0")/common.sh"

banner "3.03: Require Actions Pinned to Full-Length SHA"
should_apply 2 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:?Set GITHUB_REPO (repository to harden)}"

# HTH Guide Excerpt: begin api-audit-sha-pinning
# Read the repository's current Actions permissions (fails closed if unreadable)
PERMS=$(gh_get "/repos/${GITHUB_ORG}/${REPO}/actions/permissions") || {
  fail "3.03 Unable to read Actions permissions for ${GITHUB_ORG}/${REPO}"
  increment_failed
  summary
  exit 1
}
ENABLED=$(echo "${PERMS}" | jq -r '.enabled')
ALLOWED=$(echo "${PERMS}" | jq -r '.allowed_actions // "all"')

# Enforce: reject actions referenced by tag or branch; keep enabled/allowed_actions as they are
if [ "$(echo "${PERMS}" | jq -r '.sha_pinning_required // false')" != "true" ]; then
  gh_put "/repos/${GITHUB_ORG}/${REPO}/actions/permissions" \
    "{\"enabled\": ${ENABLED}, \"allowed_actions\": \"${ALLOWED}\", \"sha_pinning_required\": true}" >/dev/null || {
    fail "3.03 Unable to require SHA pinning on ${GITHUB_ORG}/${REPO}"
    increment_failed
    summary
    exit 1
  }
fi

# Audit: list tag- or branch-referenced actions that the setting now rejects
HTTP=$(curl -s -o "${TMPDIR:-/tmp}/hth-3.03-workflows.json" -w '%{http_code}' \
  "${GH_API}/repos/${GITHUB_ORG}/${REPO}/contents/.github/workflows" \
  -H "${AUTH_HEADER}" -H "Accept: application/vnd.github+json")
case "${HTTP}" in
  200) WORKFLOWS=$(cat "${TMPDIR:-/tmp}/hth-3.03-workflows.json") ;;
  404) WORKFLOWS="[]" ;;
  *) fail "3.03 Unable to list workflow files (HTTP ${HTTP:-none})"
     increment_failed
     summary
     exit 1 ;;
esac

UNPINNED=0
for NAME in $(echo "${WORKFLOWS}" | jq -r '.[].name'); do
  CONTENT=$(gh_get "/repos/${GITHUB_ORG}/${REPO}/contents/.github/workflows/${NAME}" \
    | jq -r '.content' | base64 -d) || {
    fail "3.03 Unable to read ${NAME}"
    increment_failed
    summary
    exit 1
  }
  REFS=$(echo "${CONTENT}" | grep -cE 'uses:[[:space:]]+[^.[:space:]][^@[:space:]]*@([^0-9a-f[:space:]]|[0-9a-f]{0,39}([^0-9a-f]|$))' || true)
  if [ "${REFS}" -gt 0 ]; then
    warn "3.03 ${NAME}: ${REFS} action reference(s) not pinned to a full-length SHA"
    UNPINNED=$((UNPINNED + REFS))
  fi
done
# HTH Guide Excerpt: end api-audit-sha-pinning

if [ "${UNPINNED}" -gt 0 ]; then
  warn "3.03 Pin them: npx pin-github-action@3.5.2 .github/workflows/*.yml"
  increment_failed
else
  pass "3.03 SHA pinning required and no unpinned action references found"
  increment_applied
fi

summary
