#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-dots-7.2
#   guide:   https://howtoharden.com/guides/chatgpt-dots/#72-reset-delete-the-dot-at-offboarding-or-after-sensitive-exposure
#   profile: L2
#   mode:    read-only
#   requires: CHATGPT_ADMIN_KEY(workspace Admin key, Custom: chatgpt.enterprise.compliance_export read), CHATGPT_WORKSPACE_ID(UUID), USER_ID argument (the departing member's user ID), curl, jq
# =============================================================================
# HTH ChatGPT Dots Control 7.2: Reset (delete) the dot at offboarding or after
#   sensitive exposure
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls v8 3.5, 6.2; NIST 800-53 PS-4, MP-6, SI-12;
#   SOC 2 CC6.2, CC6.5; no benchmark equivalent yet
#
# Sources (fetched 2026-10-09):
#   https://chatgpt.com/public/admin/api-reference   (Admin API v2.5.37:
#     GET /compliance/workspaces/{workspace_id}/users/{user_id}/memories       List User Memories
#         {data[{id, memory_contexts[{id, memory_entries[{id, content, updated_at}]}]}],
#          has_more, last_id} — no paging parameter
#     GET /compliance/workspaces/{workspace_id}/users/{user_id}/library_files  List User Library Files
#         cursor, limit ("The default is 200"); data[{id, name, mime_type, state,
#         created_at, trashed_at, is_project}], has_more, cursor
#     GET /compliance/workspaces/{workspace_id}/codex_tasks                    List Codex Tasks
#         cursor, limit ("default and max = 30"); data[{id, title, created_by_id,
#         created_at, updated_at}], has_more, cursor
#     security chatgpt.enterprise.compliance_export read on all three)
#   https://help.openai.com/en/articles/20001530-getting-started-with-your-dot
#   https://help.openai.com/en/articles/20001529-dots-privacy-security-and-safety-faqs
#   https://learn.chatgpt.com/docs/enterprise/dots-admin-guide
#
# WHAT THIS PACK IS FOR. Resetting the dot itself is owner-only ClickOps: the
# Admin API has no dot endpoint. What an admin CAN do at offboarding is list the
# artifacts that outlive the dot — "Files, Codex threads, and ChatGPT
# conversations your dot created are stored separately. Deleting your dot does
# not delete them" (help 20001529) — and the ChatGPT memories a dot may have
# fed. This pack lists them for one member so the review in 7.2 Step 3 has a
# machine record. It writes nothing.
#
# TRAPS
#  1. NO DOT ATTRIBUTION. No returned field marks an item as dot-created:
#     memory entries carry only id, content and updated_at; Library files carry no
#     origin field; Codex tasks carry created_by_id (the member), not the agent.
#     Decide what is dot-derived by reviewing content. This pack never claims it.
#  2. CONVERSATIONS ARE NOT LISTED. The Conversations tag has delete routes only
#     ("Endpoints for deleting ChatGPT Enterprise workspace conversations"); there
#     is no list route. Review conversation records as CONVERSATION_MESSAGE files
#     from the Compliance Logs Platform (pack 6.01).
#  3. CODEX TASKS ARE WORKSPACE-WIDE. List Codex Tasks takes no user parameter, so
#     every page is read and filtered here on created_by_id. A large workspace
#     means many pages; the runaway guard stops at 2000 pages.
#  4. MEMORIES HAVE NO PAGING PARAMETER. has_more and last_id are documented, but
#     no request parameter consumes them, so a has_more=true count is a lower bound.
#  5. CONTENT IS SENSITIVE. Memory content is printed only with --show-content.
#     Treat any saved output like the member's own data.
#  6. DELETION IS NOT HERE. The matching deletes (Delete Memory Entry, Delete
#     Library File, Delete Codex Task, Delete User Conversation) need
#     compliance_export delete and are deliberately not called; delete only named
#     items after review, under your retention policy.
#  7. PLAN. Enterprise (incl. Edu and Healthcare) only.
#
# Usage: hth-chatgpt-dots-7.02-offboarding-artifact-inventory.sh [--show-content] USER_ID
# Exit codes: 0 inventory printed | 2 precondition
# =============================================================================

set -euo pipefail
HTH_PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=common.sh
. "${HTH_PACK_DIR}/common.sh"

SHOW=0; TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --show-content) SHOW=1 ;;
    -h|--help) sed -n '/^# Usage:/,/^# Exit codes/p' "$0" >&2; exit 2 ;;
    -*) cgpt_die "unknown option $1" ;;
    *) [ -z "${TARGET}" ] || cgpt_die "pass exactly one USER_ID"; TARGET="$1" ;;
  esac
  shift
done

cgpt_require
CGPT_SCOPE_HINT="chatgpt.enterprise.compliance_export read"
[ -n "${TARGET}" ] || cgpt_die "pass the departing member's USER_ID"
cgpt_safe_id "${TARGET}" "user ID"

# HTH Guide Excerpt: begin offboarding-artifact-inventory
# 1. ChatGPT memory entries (TRAPS 1, 4, 5). Read-only.
cgpt_get_ok "/compliance/workspaces/${CHATGPT_WORKSPACE_ID}/users/${TARGET}/memories"
jq -e '.data | type == "array"' "${CGPT_BODY}" >/dev/null 2>&1 \
  || cgpt_die "List User Memories returned HTTP 200 without the documented data[] list"
echo "=== ChatGPT memory entries for ${TARGET} ==="
jq -r --argjson show "${SHOW}" '
  [ .data[] | (.memory_contexts // [])[] as $c | ($c.memory_entries // [])[]
    | "  context=\($c.id)  entry=\(.id)  updated_at=\(.updated_at // "?")"
      + (if $show == 1 then "  content=\(.content // "" | tostring | .[0:200])" else "" end) ]
  | if length == 0 then "  (none)" else .[] end' "${CGPT_BODY}"
jq -r 'if .has_more == true then "  NOTE: has_more is true — the count above is a lower bound (TRAP 4)" else empty end' "${CGPT_BODY}"

# 2. Library files the member owns (TRAP 1). Read-only.
LIB="${CGPT_TMPDIR}/library.jsonl"
cgpt_paginate_cursor "/compliance/workspaces/${CHATGPT_WORKSPACE_ID}/users/${TARGET}/library_files" "${LIB}"
echo "=== Library files owned by ${TARGET}: $(wc -l < "${LIB}" | tr -d ' ') ==="
jq -r '"  \(.id)  \(.name // "(unnamed)")  mime=\(.mime_type // "?")  state=\(.state // "?")"
       + "  created_at=\(.created_at // "?")  trashed_at=\(.trashed_at // "-")  is_project=\(.is_project // "-")"' "${LIB}"

# 3. Codex tasks the member created (TRAP 3). The route is workspace-wide and
#    takes limit <= 30, so it is paged here and filtered on created_by_id.
TASKS="${CGPT_TMPDIR}/codex-tasks.jsonl"
: > "${TASKS}"
CURSOR=""; PAGES=0
while :; do
  if [ -n "${CURSOR}" ]; then
    cgpt_get_ok "/compliance/workspaces/${CHATGPT_WORKSPACE_ID}/codex_tasks" \
      --data-urlencode "limit=30" --data-urlencode "cursor=${CURSOR}"
  else
    cgpt_get_ok "/compliance/workspaces/${CHATGPT_WORKSPACE_ID}/codex_tasks" --data-urlencode "limit=30"
  fi
  jq -e '(.data | type == "array") and (.has_more | type == "boolean")' "${CGPT_BODY}" >/dev/null 2>&1 \
    || cgpt_die "List Codex Tasks returned HTTP 200 without the documented {data[], has_more} shape"
  jq -c --arg u "${TARGET}" '.data[] | select(.created_by_id == $u)' "${CGPT_BODY}" >> "${TASKS}"
  PAGES=$((PAGES + 1))
  [ "$(jq -r '.has_more' "${CGPT_BODY}")" = "true" ] || break
  CURSOR="$(jq -r '.cursor // ""' "${CGPT_BODY}")"
  [ -n "${CURSOR}" ] || cgpt_die "List Codex Tasks: has_more is true but no cursor was returned — refusing to report a partial list"
  [ "${PAGES}" -lt 2000 ] || cgpt_die "List Codex Tasks: more than 2000 pages — runaway guard"
done
echo "=== Codex tasks created by ${TARGET}: $(wc -l < "${TASKS}" | tr -d ' ') (from ${PAGES} workspace page(s)) ==="
jq -r '"  \(.id)  \(.title // "(untitled)")  created_at=\(.created_at // "?")  updated_at=\(.updated_at // "?")"' "${TASKS}"

echo ""
echo "NOT LISTED (TRAP 2): conversations — review CONVERSATION_MESSAGE records from pack 6.01."
echo "Nothing above is marked dot-created (TRAP 1): decide what is dot-derived by reviewing content,"
echo "then retain or delete named items under your retention policy (TRAP 6)."
exit 0
# HTH Guide Excerpt: end offboarding-artifact-inventory
