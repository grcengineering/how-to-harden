#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: alertmedia-1.3
#   guide: https://howtoharden.com/guides/alertmedia/#13-check-the-assigned-entra-enterprise-app-binding
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, authorized Microsoft Graph read token and confirmed Entra service principal
# Source (checked 2026-11-27): https://learn.microsoft.com/graph/api/serviceprincipal-get
# Review locally; protect evidence from unnecessary disclosure.

# HTH Guide Excerpt: begin alertmedia-evidence
set +x
set -euo pipefail
: "${HTH_ALERTMEDIA_SLUG:?Set the operator-verified AlertMedia tenant subdomain.}"
: "${HTH_ALERTMEDIA_SP_OBJECT_ID:?Set the Entra enterprise application object ID, not the app ID.}"
: "${HTH_ALERTMEDIA_APP_ID:?Set the independently verified Entra Application ID.}"
: "${HTH_ALERTMEDIA_GRAPH_TOKEN:?Set an approved Microsoft Graph token from the intended Entra directory.}"
[[ "$HTH_ALERTMEDIA_SLUG" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ &&
   "$HTH_ALERTMEDIA_SP_OBJECT_ID" =~ ^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$ &&
   "$HTH_ALERTMEDIA_APP_ID" =~ ^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$ &&
   "$HTH_ALERTMEDIA_GRAPH_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] ||
  { printf 'Invalid tenant slug, object ID or token.\n' >&2; exit 2; }
target="https://$HTH_ALERTMEDIA_SLUG.alertmedia.com"
printf 'Authorization: Bearer %s\n' "$HTH_ALERTMEDIA_GRAPH_TOKEN" |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @-     "https://graph.microsoft.com/v1.0/servicePrincipals/$HTH_ALERTMEDIA_SP_OBJECT_ID?\$select=id,appId,replyUrls,servicePrincipalNames,appRoleAssignmentRequired" |
  jq -es --arg id "$HTH_ALERTMEDIA_SP_OBJECT_ID" --arg app "$HTH_ALERTMEDIA_APP_ID" --arg target "$target" '
    if length == 1 and .[0].id == $id and .[0].appId == $app and (.[0].appRoleAssignmentRequired | type) == "boolean"
      and (.[0].replyUrls | type) == "array" and (.[0].servicePrincipalNames | type) == "array"
      then .[0] | {id, appId, assignment_required:.appRoleAssignmentRequired,
        alertmedia_issuer_present:(.servicePrincipalNames | index($target) != null),
        only_expected_reply_url:(.replyUrls == [($target + "/api/sso/saml/")])}
      else error("Unexpected enterprise application response") end'
# HTH Guide Excerpt: end alertmedia-evidence
