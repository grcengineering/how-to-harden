#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-dots-6.2
#   guide:   https://howtoharden.com/guides/chatgpt-dots/#62-alert-on-governance-changes-that-widen-what-dots-can-reach
#   profile: L2
#   mode:    read-only
#   requires: openai CLI (verified against v1.38.0), OPENAI_ADMIN_KEY (API Platform admin key, not a ChatGPT Admin key), jq; HTH_LOOKBACK_HOURS(optional, default 24), HTH_WORKSPACE_ID(optional), HTH_TENANT_FEED_VERIFIED(optional, yes once the feed has carried a known test change)
# =============================================================================
# HTH ChatGPT Dots Control 6.2: Alert on governance changes that widen what dots
#   can reach
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls v8 8.11, 6.8; NIST 800-53 AU-6, CM-3, AC-2(4), SI-4;
#   SOC 2 CC7.2, CC8.1; no benchmark equivalent yet
# Dependencies: openai (first-party OpenAI CLI; brew install openai/tools/openai), jq
#
# Sources (every command, flag, event name and field below comes from these,
# fetched 2026-10-08 unless marked):
#   https://github.com/openai/openai-cli/blob/v1.38.0/README.md
#   https://github.com/openai/openai-cli/blob/v1.38.0/pkg/cmd/adminorganizationauditlog.go
#   https://github.com/openai/openai-cli/blob/v1.38.0/cmd/openai/command_subgroups_test.go
#   https://github.com/openai/openai-cli/blob/v1.38.0/docs/readable-output.md
#   https://developers.openai.com/api/reference/resources/admin/subresources/organization/subresources/audit_logs/methods/list
#   https://learn.chatgpt.com/docs/enterprise/dots-admin-guide
#   https://chatgpt.com/public/admin/api-reference  (AUDIT_LOG note; returns 403
#     to curl, so it comes from the research ledger's real-browser read)
#
# WHY A cli/ PACK FOR A CHATGPT PRODUCT. `openai` is OpenAI's first-party CLI for
# the API Platform and has no ChatGPT-workspace or dots commands. It belongs here
# because the audit log it reads carries ChatGPT workspace RBAC. Its own
# --resource-id help says "For ChatGPT connector role events, use the workspace
# connector resource ID shown in details.id, such as <workspace_id>__<connector_id>".
# The API reference gives role.bound_to_resource / role.unbound_from_resource the
# fields workspace_id, connector_name, permissions, enabled ("Whether the connector
# is enabled for the role") and source (role_toggle, role_connector_update,
# role_delete, workspace_permissions, connector_publish). Dots "can use supported
# existing ChatGPT app connections", so enabling a connector for a role widens what
# that role's dots can reach. The ChatGPT Admin API's AUDIT_LOG section adds: "Many
# of these permissions and role changes have been moved to a shared RBAC system.
# These logs must be enabled and then are accessible through API Platform."
#
# ── TRAP 1: two different admin keys, two different feeds ───────────────────
# This reads with an API Platform admin key (OPENAI_ADMIN_KEY). The ChatGPT Admin
# key reads the Compliance Logs Platform at api.chatgpt.com instead (ROLE_UPDATE,
# WORKSPACE_TOGGLE_FEATURE, ...), which this control's api/ and Sigma packs cover.
# Neither feed is documented as complete on its own, so run both.
#
# ── TRAP 2: no doc maps a dots grant to these events ─────────────────────────
# The tenant.* types below appear only as event-type names, with no payload
# schema. role.updated is the only audit-log type with a documented permission
# diff (changes_requested.permissions_added / permissions_removed). No OpenAI doc
# says which family (role.* or tenant.custom_role.*) a dots grant emits, and the
# dots permission identifier strings are undocumented. This pack therefore prints
# every such event for review rather than filtering for dots. Some role.* events
# concern API Platform organization or project roles (resource_type, for example
# api.organization or api.project), not ChatGPT workspace roles; the resource_type
# column shows which. Toggle Use dots (Beta) on a test role during validation and
# record the event and payload before narrowing anything.
#
# ── TRAP 3: tenant_only constrains the whole request ─────────────────────────
# --tenant-only is "Required for tenant-scoped events such as
# role.bound_to_resource and role.unbound_from_resource. When true, all supplied
# event types must be tenant-scoped." The docs do not say which tenant.* types are
# tenant-scoped, so each type is queried on its own and a rejection is reported,
# never dropped silently. The role.* types are tried with --tenant-only first and,
# if rejected, once without it (scope column "org").
#
# ── TRAP 4: an empty window is not proof ─────────────────────────────────────
# The ChatGPT note says these logs "must be enabled". An empty result can mean no
# change or logging that is off. The pack exits 3 (UNVERIFIED) on an empty window
# unless HTH_TENANT_FEED_VERIFIED=yes records that the feed has been seen to carry
# a known test change.
#
# ── TRAP 5: pipes get readable text unless you ask ───────────────────────────
# v1.38.0 prints "labeled text by default, both in a terminal and when stdout is
# piped"; scripts "must select their format explicitly". This pack passes
# --format jsonl, which prints one audit event per line. Any non-empty line that
# is not a JSON object with a `type` is counted as unparseable and the run ends
# INCOMPLETE (exit 2), so a changed output format can never read as a clean
# window. The spaced command form (openai admin organization audit-logs list) is
# the documented one; the older colon form admin:organization:audit-logs
# "continue[s] to work".
#
# Usage:  HTH_LOOKBACK_HOURS=24 HTH_WORKSPACE_ID=<id> ./hth-chatgpt-dots-6.02-tenant-rbac-audit.sh
#         HTH_WORKSPACE_ID narrows only the connector-role events, which carry a
#         workspace_id; tenant.* events have none and always print.
# Output: one tab-separated row per event: time, type, scope, resource_type, actor, details (JSON)
# Exit codes: 0 no events (feed verified) | 1 events to review | 2 precondition,
#   a query failed, or output could not be parsed | 3 no events, feed unverified (TRAP 4)
# =============================================================================

set -euo pipefail

command -v openai >/dev/null 2>&1 || { echo "PRECONDITION: openai CLI not found (brew install openai/tools/openai)" >&2; exit 2; }
command -v jq     >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
[ -n "${OPENAI_ADMIN_KEY:-}" ] || {
  echo "PRECONDITION: export OPENAI_ADMIN_KEY (an API Platform admin key, not a ChatGPT Admin key)" >&2; exit 2; }

# HTH Guide Excerpt: begin cli-list-dots-reach-rbac-events
# List RBAC changes that can widen what dots reach, from the API Platform audit log.
HOURS="${HTH_LOOKBACK_HOURS:-24}"
printf '%s' "$HOURS" | grep -E '^[1-9][0-9]*$' >/dev/null || {
  echo "PRECONDITION: HTH_LOOKBACK_HOURS must be a positive integer" >&2; exit 2; }
SINCE=$(( $(date +%s) - HOURS * 3600 ))

# Documented ChatGPT workspace connector-role events first, then the tenant RBAC
# events whose link to dots grants is unverified (TRAP 2), then the role.* family
# (role.updated carries the only documented permission diff).
EVENT_TYPES=(
  role.bound_to_resource role.unbound_from_resource
  tenant.custom_role.created tenant.custom_role.updated tenant.custom_role.deleted
  tenant.role_assignment.created tenant.role_assignment.deleted
  tenant.group.member.added tenant.group.member.removed
  tenant.resource_role_assignment.created tenant.resource_role_assignment.deleted
)
ROLE_TYPES=(
  role.created role.updated role.deleted role.assignment.created role.assignment.deleted
)

ERR=$(mktemp "${TMPDIR:-/tmp}/hth-dots-602.XXXXXX"); trap 'rm -f "$ERR"' EXIT
FOUND=0; FAILED=0

# list_type <event type> <scope: tenant|org> — one type per call (TRAP 3). The key
# travels in OPENAI_ADMIN_KEY, never in argv. Returns 1 if the CLI rejects the call.
list_type() {
  local type="$1" scope="$2" out rows bad
  local only=()
  [ "$scope" = "tenant" ] && only=(--tenant-only)
  if ! out=$(openai --format jsonl admin organization audit-logs list \
        ${only[@]+"${only[@]}"} --event-type "$type" --effective-at.gte "$SINCE" --limit 100 2>"$ERR"); then
    echo "  ERROR: $type (scope=$scope): $(head -c 300 "$ERR")" >&2; return 1
  fi
  # Count non-empty lines that are not a JSON object with a `type` (TRAP 5).
  bad=$(printf '%s\n' "$out" | jq -R -s -r 'split("\n") | map(select(length > 0))
    | map(select(((try fromjson catch null) as $o
                  | ($o | type) != "object" or ($o | has("type") | not))))
    | .[0:3][]')
  if [ -n "$bad" ]; then
    echo "  ERROR: $type (scope=$scope): unparseable CLI output: $(printf '%s' "$bad" | head -c 300)" >&2
    FAILED=1
  fi
  # Details live under a key named after the event type, e.g. ."role.bound_to_resource".
  rows=$(printf '%s\n' "$out" | jq -R -r --arg ws "${HTH_WORKSPACE_ID:-}" --arg scope "$scope" '
    fromjson? | select(type == "object" and has("type"))
    | (.[.type] // {}) as $d
    | select($ws == "" or (($d.workspace_id // $ws) == $ws))
    | [ (.effective_at | todate), .type, $scope,
        ($d.resource_type // $d.changes_requested.resource_type // "-"),
        (.actor.session.user.email // .actor.api_key.user.email
          // .actor.api_key.service_account.id // .actor.type // "unknown"),
        ($d | tojson) ] | @tsv')
  if [ -n "$rows" ]; then printf '%s\n' "$rows"; FOUND=1; fi
  return 0
}

printf 'effective_at\ttype\tscope\tresource_type\tactor\tdetails\n'
for TYPE in "${EVENT_TYPES[@]}"; do
  list_type "$TYPE" tenant || FAILED=1
done
# role.* may not be tenant-scoped: try --tenant-only first, then once without it.
for TYPE in "${ROLE_TYPES[@]}"; do
  list_type "$TYPE" tenant || list_type "$TYPE" org || FAILED=1
done

if [ "$FAILED" = 1 ]; then
  echo "INCOMPLETE: at least one event type could not be read or parsed; do not treat this window as clean" >&2; exit 2
fi
if [ "$FOUND" = 1 ]; then
  exit 1
fi
if [ "${HTH_TENANT_FEED_VERIFIED:-}" != "yes" ]; then
  echo "  UNVERIFIED: none in the last ${HOURS}h, and the feed has not been shown to carry a known test change (TRAP 4); set HTH_TENANT_FEED_VERIFIED=yes once it has" >&2; exit 3
fi
echo "  none in the last ${HOURS}h" >&2; exit 0
# HTH Guide Excerpt: end cli-list-dots-reach-rbac-events
