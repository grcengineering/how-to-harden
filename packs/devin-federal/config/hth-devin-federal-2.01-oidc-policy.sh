#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-federal-2.1
#   guide: https://howtoharden.com/guides/devin-federal/#21-require-air-gapped-oidc-when-license-only-access-is-insufficient
#   profile: L2
#   mode: read-only
#   requires: jq; confirmed issuer, public client ID and required group; reviewed deployment separately
# Source: https://docs.devin.ai/federal/air-gapped/sso (2026-11-05)
# HTH Guide Excerpt: begin oidc-policy
set +x
set -Eeuo pipefail
umask 077
unknown() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
case "${HTH_PROFILE_LEVEL:-1}" in 2|3|4) ;; *) unknown 'HTH_PROFILE_LEVEL=2..4 required before generation' ;; esac
command -v jq >/dev/null || unknown 'jq required'
[[ "${DEVIN_OIDC_ISSUER:-}" =~ ^https://[A-Za-z0-9][A-Za-z0-9.:-]*(/[A-Za-z0-9._~/-]*)?$ ]] || unknown 'issuer must be confirmed HTTPS without credentials, query or fragment'
[[ -n ${DEVIN_OIDC_CLIENT_ID:-} && -n ${DEVIN_OIDC_REQUIRED_GROUP:-} ]] || unknown 'set public client ID and explicit required group'
jq -n --arg issuer "$DEVIN_OIDC_ISSUER" --arg client "$DEVIN_OIDC_CLIENT_ID" --arg group "$DEVIN_OIDC_REQUIRED_GROUP" \
 '{schema_version:0,mode:"sso",issuer:$issuer,client_id:$client,scopes:["openid","profile","email"],groups_claim:"groups",required_group:$group,additional_endpoint_hosts:[]}'
printf 'EMITTED ONLY: review, deploy to protected auth.json, and test required-group denial with the real IdP.\n' >&2
# HTH Guide Excerpt: end oidc-policy
