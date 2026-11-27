#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: businessmap-2.2
#   guide:   https://howtoharden.com/guides/businessmap/
#   profile: L2
#   mode:    read-only
#   requires: BUSINESSMAP_SUBDOMAIN, curl, jq
# First-party source: https://knowledgebase.businessmap.io/hc/en-us/articles/360012393692-Businessmap-REST-API
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
tenant=${BUSINESSMAP_SUBDOMAIN:?Set the exact tenant subdomain, not a full URL}
[[ "$tenant" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]] || exit 2

body=$(curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 "https://$tenant.kanbanize.com/openapi/json")
jq -ce --arg tenant "$tenant" '
  if ((.openapi // "") | type=="string" and test("^3\\.[0-9]+\\.[0-9]+$")) or .swagger=="2.0"
  then ["/users","/api/v2/users"] as $candidates
    | .paths as $paths
    | [$candidates[] | select(($paths[.].get|type)=="object")] as $verified
    | if ($verified|length)>0
      then {tenant:$tenant,scope:"schema-only",http_method:"GET",documented_paths:$verified}
      else error("no documented Users GET operation") end
  else error("response is not a supported OpenAPI document") end
' <<<"$body"
# HTH Guide Excerpt: end read-evidence
