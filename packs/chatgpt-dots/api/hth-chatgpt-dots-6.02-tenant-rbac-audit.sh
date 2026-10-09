#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-dots-6.2
#   guide:   https://howtoharden.com/guides/chatgpt-dots/#62-alert-on-governance-changes-that-widen-what-dots-can-reach
#   profile: L2
#   mode:    read-only
#   requires: OPENAI_ADMIN_KEY(API Platform Admin key, for --feed tenant), CHATGPT_ADMIN_KEY(workspace Admin key with the AUDIT_LOG read scope, for --feed chatgpt), CHATGPT_WORKSPACE_ID(UUID, for --feed chatgpt), HTH_AUDIT_SINCE(optional ISO 8601, default 24h ago), HTH_TENANT_EVENT_TYPES(optional), HTH_ROLE_EVENT_TYPES(optional), HTH_TENANT_FEED_VERIFIED(optional, yes once the tenant feed has carried a known test change), curl, jq
# =============================================================================
# HTH ChatGPT Dots Control 6.2: Alert on governance changes that widen what
#   dots can reach
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls v8 8.11, 6.8; NIST 800-53 AU-6, CM-3, AC-2(4), SI-4;
#   SOC 2 CC7.2, CC8.1; no benchmark equivalent yet
#
# Sources (fetched 2026-10-08):
#   https://developers.openai.com/api/reference/resources/admin/subresources/organization/subresources/audit_logs/methods/list
#     GET https://api.openai.com/v1/organization/audit_logs, Bearer $OPENAI_ADMIN_KEY;
#     tenant_only, event_types, effective_at{gt,gte,lt,lte} (Unix seconds),
#     limit 1-100 (default 20), after (object ID); returns data[], has_more, last_id
#   https://github.com/openai/openai-python/blob/main/src/openai/types/admin/organization/audit_log_list_params.py
#   https://github.com/openai/openai-python/blob/main/src/openai/_client.py
#     the client builds Querystring(array_format="brackets"), so arrays go as
#     `event_types[]=`; _qs.py (nested_format default "brackets") sends objects as
#     `effective_at[gte]=` (fetched 2026-10-09)
#   https://github.com/openai/openai-python/blob/main/src/openai/_qs.py
#   https://chatgpt.com/public/admin/api-reference   (Admin API v2.5.37, tag Audit:
#     event_type AUDIT_LOG, fine-grained scope
#     chatgpt.enterprise.compliance_logs_platform.audit_log.read; record fields
#     action, action_result, action_privilege, action_data; "API key actions"
#     section; tag Workspace Users: UPDATE_WORKSPACE_USER; re-read 2026-10-09)
#
# WHY TWO FEEDS. The ChatGPT Audit tag says: "Many of these permissions and role
# changes have been moved to a shared RBAC system. These logs must be enabled
# and then are accessible through API Platform." A dots grant can therefore
# surface in either place, and the two are read with different keys:
#   --feed tenant   API Platform audit logs, tenant RBAC events (OPENAI_ADMIN_KEY)
#   --feed chatgpt  Compliance Logs Platform AUDIT_LOG governance actions (CHATGPT_ADMIN_KEY)
#   --feed both     default
#
# TRAPS
#  1. NO DOTS IDENTIFIER. The permission strings for Use dots (Beta), Add dots to
#     Slack and Microsoft Teams, Allow local computer access, Use custom rules for
#     dots and the Cloud computer capabilities are undocumented (UI labels only).
#     This pack matches the event/action, never a permission name, and routes
#     every change to review. Capture the real strings in a live tenant.
#  2. tenant.* EVENTS HAVE NO DOCUMENTED PAYLOAD. They appear only as enum values
#     in event_types / type. role.updated is the only audit-log type with a
#     documented permission diff (changes_requested.permissions_added /
#     permissions_removed); tenant.custom_role.updated documents nothing. Which
#     family (role.* or tenant.custom_role.*) carries a dots grant is
#     undocumented, so both are printed raw for review. Some role.* events are
#     API Platform organization or project roles (resource_type, e.g.
#     api.organization or api.project), not ChatGPT workspace roles.
#  3. tenant_only=true "Required for tenant-scoped events such as
#     role.bound_to_resource and role.unbound_from_resource. When true, all
#     supplied event types must be tenant-scoped." The docs do not say which
#     tenant.* types are tenant-scoped, so EACH type is queried in its own
#     request: a 400 on one type is reported and the run ends INCOMPLETE (exit 2)
#     without blinding the others. The role.* types are tried with tenant_only
#     first and, if rejected, once without it (scope column "org").
#  4. "These logs must be enabled" — API Platform audit logging is off until an
#     owner turns it on; an empty tenant feed proves nothing until it is. When the
#     tenant feed returns nothing and nothing else was found, the pack exits 3
#     (UNVERIFIED) unless HTH_TENANT_FEED_VERIFIED=yes records that the feed has
#     been seen to carry a known test change.
#  5. TWO KEYS, NEVER SWAP THEM. OPENAI_ADMIN_KEY is an API Platform key; the
#     ChatGPT feed needs a workspace Admin key from Credentials > Admin keys.
#     For the ChatGPT key, grant only the AUDIT_LOG fine-grained scope; its UI
#     label is undocumented, and the documented label "Compliance logging
#     platform > Read" grants every log type, conversation content included.
#  6. ADMIN API CALLS EMIT THE "API KEY ACTIONS". The Audit tag says "Compliance
#     API endpoint requests and Admin API endpoint requests use the actions
#     documented in this section" (actor.type API_KEY). An Admin API Add Group User
#     is therefore audited as ADD_WORKSPACE_DIRECTORY_GROUP_USER (workspace_id,
#     group_id, user_id), and Update Workspace User (built-in role or seat) as
#     UPDATE_WORKSPACE_USER. Console additions appear as GROUP_ADD_USERS (bulk, by
#     email) or GROUP_EDIT (added_user_id). No action is documented for Bulk Add
#     Group Users or for SCIM-driven membership; tenant.group.member.added is the
#     cross-check for those. Removals (GROUP_REMOVE_USER,
#     DELETE_WORKSPACE_DIRECTORY_GROUP_USER) are left out as leaver noise, like
#     the 6.02 Sigma rule; pull them with pack 6.01 (HTH_CLP_EVENT_TYPES=AUDIT_LOG).
#     Under the explicit-Off reading of how roles combine (guide 8.1 row f),
#     ROLE_UNASSIGN and ROLE_DELETE can widen access, so they ARE matched.
#  7. LATENCY AND WINDOWS. The ChatGPT feed has a p99 under 30 minutes and
#     filters FILES on end_time, so the pack also filters events on their own
#     timestamp. Re-run with an overlapping HTH_AUDIT_SINCE; duplicates are
#     removed on event_id.
#  8. PLAN. ChatGPT AUDIT_LOG is Enterprise/Edu only. Business Premium and Pro
#     dots have no admin audit feed.
#
# Usage: hth-chatgpt-dots-6.02-tenant-rbac-audit.sh [--feed tenant|chatgpt|both]
# Output: matching events as NDJSON on stdout; a review summary on stderr.
# Exit codes: 0 no governance change in the window | 1 change(s) found — review
#   | 2 precondition, or an event type could not be read (INCOMPLETE)
#   | 3 nothing found but the tenant feed is unverified (TRAP 4)
# =============================================================================

set -euo pipefail
HTH_PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=common.sh
. "${HTH_PACK_DIR}/common.sh"

FEED="both"
case "${1:-}" in
  "") ;;
  --feed) FEED="${2:-}" ;;
  *) echo "usage: $(basename "$0") [--feed tenant|chatgpt|both]" >&2; exit 2 ;;
esac
case "${FEED}" in tenant|chatgpt|both) ;; *) cgpt_die "--feed must be tenant, chatgpt or both" ;; esac

cgpt_require_tools
SINCE="${HTH_AUDIT_SINCE:-$(hth_iso_hours_ago 24)}"
SINCE_EPOCH="$(hth_iso_to_epoch "${SINCE}")"
CHANGES=0
INCOMPLETE=0
TENANT_FOUND=-1      # -1 = tenant feed not queried

# HTH Guide Excerpt: begin tenant-rbac-audit-log
# API Platform audit logs: tenant RBAC events (custom roles, role assignments,
# group membership, resource role bindings) and the role.* family. Read-only GET,
# one event type per request (TRAP 3).
OPENAI_API_BASE="${OPENAI_API_BASE:-https://api.openai.com/v1}"
TENANT_TYPES="${HTH_TENANT_EVENT_TYPES:-tenant.custom_role.created,tenant.custom_role.updated,tenant.custom_role.deleted,tenant.role_assignment.created,tenant.role_assignment.deleted,tenant.group.member.added,tenant.group.member.removed,tenant.resource_role_assignment.created,tenant.resource_role_assignment.deleted,role.bound_to_resource,role.unbound_from_resource}"
ROLE_TYPES="${HTH_ROLE_EVENT_TYPES:-role.created,role.updated,role.deleted,role.assignment.created,role.assignment.deleted}"

_oai_auth() { printf 'header = "Authorization: Bearer %s"\n' "${OPENAI_ADMIN_KEY}"; }

# tenant_query <event_type> <tenant_only: true|false> <scope label>
# Prints every page's events as NDJSON on stdout and a summary on stderr; adds
# the count to TQ_FOUND. Returns 1 (after reporting) on a rejected type, so the
# caller can retry or record it; 401/403/no response stop the run.
TQ_FOUND=0
tenant_query() {
  local t="$1" only="$2" scope="$3" after="" pages=0 code rc snippet n
  local tenant_arg=()
  [ "${only}" = "true" ] && tenant_arg=(--data-urlencode "tenant_only=true")
  while :; do
    local page=()
    [ -z "${after}" ] || page=(--data-urlencode "after=${after}")
    set +e
    code="$(_oai_auth | curl -sS -g -G -K - -o "${CGPT_BODY}" -w '%{http_code}' \
      "${OPENAI_API_BASE}/organization/audit_logs" \
      ${tenant_arg[@]+"${tenant_arg[@]}"} --data-urlencode "event_types[]=${t}" \
      --data-urlencode "effective_at[gte]=${SINCE_EPOCH}" --data-urlencode "limit=100" \
      ${page[@]+"${page[@]}"} 2>/dev/null)"
    rc=$?
    set -e
    [ "${rc}" -eq 0 ] || cgpt_die "GET /organization/audit_logs — no HTTP response (curl exit ${rc})"
    if [ "${code}" != "200" ]; then
      snippet="$(head -c 300 "${CGPT_BODY}" | tr '\n' ' ')"
      case "${code}" in
        401|403) cgpt_die "audit_logs HTTP ${code} — OPENAI_ADMIN_KEY is invalid or not an organization Admin key, or audit logging is not enabled (TRAP 4). Body: ${snippet}" ;;
        *) echo "  ${t} (tenant_only=${only}): HTTP ${code} — ${snippet}" >&2; return 1 ;;
      esac
    fi
    jq -e '(.data | type == "array") and (.has_more | type == "boolean")' "${CGPT_BODY}" >/dev/null 2>&1 \
      || cgpt_die "audit_logs returned HTTP 200 without the documented {data[], has_more} shape"
    jq -c '.data[]' "${CGPT_BODY}"
    jq -r --arg scope "${scope}" '.data[] | "  \(.effective_at | todate)  \(.type)  scope=\($scope)  actor="
           + "\(.actor.session.user.email // .actor.api_key.user.email // .actor.api_key.service_account.id // .actor.api_key.id // "?")"
           + "  details=\(.[.type] // "(no documented payload — TRAP 2)" | tojson | .[0:300])"' "${CGPT_BODY}" >&2
    n="$(jq '.data | length' "${CGPT_BODY}")"
    TQ_FOUND=$((TQ_FOUND + n))
    pages=$((pages + 1))
    [ "$(jq -r '.has_more' "${CGPT_BODY}")" = "true" ] || break
    after="$(jq -r '.last_id // ""' "${CGPT_BODY}")"
    [ -n "${after}" ] || cgpt_die "audit_logs: has_more is true but last_id is null — cannot page safely"
    [ "${pages}" -lt 1000 ] || cgpt_die "audit_logs: more than 1000 pages — runaway guard"
  done
}

tenant_audit() {
  [ -n "${OPENAI_ADMIN_KEY:-}" ] || cgpt_die "set OPENAI_ADMIN_KEY — an API Platform Admin key (needed for --feed tenant)"
  local t types=() roles=()
  IFS=',' read -r -a types <<<"${TENANT_TYPES}"
  IFS=',' read -r -a roles <<<"${ROLE_TYPES}"
  for t in ${types[@]+"${types[@]}"} ${roles[@]+"${roles[@]}"}; do
    [[ "${t}" =~ ^[a-z_.]+$ ]] || cgpt_die "event type '${t}' is not a lower-case audit-log type"
  done
  echo "=== Tenant RBAC audit log (API Platform), effective_at >= ${SINCE} ===" >&2
  TQ_FOUND=0
  for t in ${types[@]+"${types[@]}"}; do
    tenant_query "${t}" true tenant || INCOMPLETE=1
  done
  # role.* may not be tenant-scoped: try tenant_only first, then once without it.
  for t in ${roles[@]+"${roles[@]}"}; do
    tenant_query "${t}" true tenant || tenant_query "${t}" false org || INCOMPLETE=1
  done
  echo "  ${TQ_FOUND} tenant RBAC / role event(s)" >&2
  TENANT_FOUND="${TQ_FOUND}"
  CHANGES=$((CHANGES + TQ_FOUND))
}
# HTH Guide Excerpt: end tenant-rbac-audit-log

# HTH Guide Excerpt: begin chatgpt-audit-log-governance
# ChatGPT Compliance Logs Platform AUDIT_LOG: the governance actions that can
# widen dots' reach (role permissions and assignments, role deletion, member
# role and seat updates, group membership by console or Admin API, app access,
# publication and action controls, plugin sharing and installation policy,
# feature toggles, Agent Security policy saves). A superset of the two 6.02
# Sigma rules plus APP_SET_ENABLED_ACTIONS (2.01 rule) and WORKSPACE_SET_POLICY
# (4.02 rule). Removals of a user from a group are left out (TRAP 6). Read-only.
GOVERNANCE_ACTIONS='["ROLE_CREATE","ROLE_UPDATE","ROLE_DELETE","ROLE_ASSIGN","ROLE_UNASSIGN",
  "USER_ROLE_UPDATED","UPDATE_WORKSPACE_USER",
  "ROLE_SET_PLUGIN_PERMISSIONS","ROLE_SET_CONNECTOR_PERMISSIONS","ROLE_SET_ALL_CONNECTOR_PERMISSIONS",
  "ROLE_UPDATE_BINDING_PERMISSIONS","GROUP_ADD_USERS","GROUP_EDIT","ADD_WORKSPACE_DIRECTORY_GROUP_USER",
  "APP_UPDATE_ACCESS_POLICY","APP_ALLOW_USER","APP_PUBLISH","APP_SET_ENABLED_ACTIONS",
  "PLUGIN_SHARE","PLUGIN_UPDATE_INSTALLATION_POLICY","WORKSPACE_TOGGLE_FEATURE","WORKSPACE_SET_POLICY"]'

chatgpt_audit() {
  cgpt_require
  CGPT_SCOPE_HINT="chatgpt.enterprise.compliance_logs_platform.audit_log.read"
  local raw="${CGPT_TMPDIR}/audit-raw.jsonl" ded="${CGPT_TMPDIR}/audit.ndjson" hits="${CGPT_TMPDIR}/audit-hits.ndjson" n
  : > "${raw}"
  echo "=== ChatGPT AUDIT_LOG governance actions, files after ${SINCE} ===" >&2
  clp_pull AUDIT_LOG "${SINCE}" "" "${raw}"
  clp_dedupe "${raw}" "${ded}"
  jq -c --argjson acts "${GOVERNANCE_ACTIONS}" --argjson since "${SINCE_EPOCH}" '
      select(.action as $a | $acts | any(.[]; . == $a))
      | select(((try (.timestamp | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601) catch null) // $since) >= $since)' \
      "${ded}" > "${hits}"
  cat "${hits}"
  jq -r '"  \(.timestamp)  \(.action)  result=\(.action_result // "?")  actor=\(.actor.user_email // .actor.redacted_id // .actor.type // "?")"
         + "  data=\(.action_data // {} | tojson | .[0:300])"' "${hits}" >&2
  n="$(wc -l < "${hits}" | tr -d ' ')"
  echo "  ${n} governance action(s) from ${CLP_FILES} AUDIT_LOG file(s)" >&2
  if [ -n "${CLP_LAST_END_TIME}" ]; then
    echo "  checkpoint: next run HTH_AUDIT_SINCE='${CLP_LAST_END_TIME}' (keep an overlap — TRAP 7)" >&2
  fi
  CHANGES=$((CHANGES + n))
}
# HTH Guide Excerpt: end chatgpt-audit-log-governance

case "${FEED}" in
  tenant)  tenant_audit ;;
  chatgpt) chatgpt_audit ;;
  both)    tenant_audit; chatgpt_audit ;;
esac

if [ "${INCOMPLETE}" -eq 1 ]; then
  echo "INCOMPLETE: at least one event type could not be read (TRAP 3); review the ${CHANGES} event(s) above, but do not treat this window as clean" >&2
  exit 2
fi
if [ "${CHANGES}" -gt 0 ]; then
  echo "REVIEW: ${CHANGES} governance change(s) — confirm each against an approved change; dots identifiers are undocumented (TRAP 1)" >&2
  exit 1
fi
if [ "${TENANT_FOUND}" -eq 0 ] && [ "${HTH_TENANT_FEED_VERIFIED:-}" != "yes" ]; then
  echo "UNVERIFIED: no governance change, but the tenant feed returned nothing and has not been shown to carry a known test change; an empty feed looks the same as audit logging that is off (TRAP 4). Set HTH_TENANT_FEED_VERIFIED=yes once it has" >&2
  exit 3
fi
echo "No governance change in the window" >&2
exit 0
