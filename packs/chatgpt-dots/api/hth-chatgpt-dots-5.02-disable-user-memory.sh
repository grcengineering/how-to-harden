#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-dots-5.2
#   guide:   https://howtoharden.com/guides/chatgpt-dots/#52-limit-what-flows-into-a-dots-persistent-memory
#   profile: L2
#   mode:    mutating
#   requires: CHATGPT_ADMIN_KEY(workspace Admin key: chatgpt.enterprise.compliance_export delete to write, + read for the dry-run memory counts, + chatgpt.enterprise.directory read for --from-group), CHATGPT_WORKSPACE_ID(UUID), HTH_CONFIRM_WORKSPACE(must equal CHATGPT_WORKSPACE_ID for --workspace --apply), curl, jq
# =============================================================================
# HTH ChatGPT Dots Control 5.2: Limit what flows into a dot's persistent memory
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls v8 3.1, 3.4; NIST 800-53 SI-12, PT-2, AC-4;
#   SOC 2 C1.1, P4.1; no benchmark equivalent yet
#
# Sources (fetched 2026-10-08):
#   https://chatgpt.com/public/admin/api-reference   (Admin API v2.5.37:
#     POST /compliance/workspaces/{workspace_id}/users/{user_id}/memory/delete_and_disable
#          200 {id, object, status: "completed"}; 404, 429, 500
#     POST /compliance/workspaces/{workspace_id}/memory/delete_and_disable
#          202 {id, object, status: "accepted"}; 404, 429, 500, 503
#     GET  /compliance/workspaces/{workspace_id}/users/{user_id}/memories   List User Memories
#     GET  /manage/workspaces/{workspace_id}/groups/{group_id}/users        List Group Users
#     no request body on either POST; security chatgpt.enterprise.compliance_export delete)
#   https://help.openai.com/en/articles/20001529-dots-privacy-security-and-safety-faqs
#   https://learn.chatgpt.com/docs/dots/tasks-and-memory
#   https://help.openai.com/en/articles/8590148-memory-in-chatgpt
#   https://help.openai.com/en/articles/9295112-memory-faq-business-version
#
# DRY-RUN BY DEFAULT. Without --apply nothing is written: the pack prints each
# planned POST and, where the key can read them, how many ChatGPT saved-memory
# entries each member has (entries this call will NOT delete — TRAP 2).
#
# TRAPS
#  1. ONE-WAY AND UNVERIFIABLE BY API. No re-enable route and no read-state
#     route is documented. After --apply, confirm in the member's Settings >
#     Personalization > Memory that Memory shows off. Each POST is logged as an
#     AUDIT_LOG event (TRAP 6); keep this script's output alongside that event as
#     evidence.
#  2. THE API SAYS IT DOES NOT DELETE SAVED MEMORIES. Verbatim, both routes: "This
#     operation does not delete saved memories, conversation history, or
#     archives." The user route "deletes their About You summary cache and
#     configured M3M dream data"; individual entries need DELETE
#     .../memory_contexts/{id}/memories/{id}, which this pack does not call.
#     CONFLICTING SOURCE: help 9295112 (Memory FAQ, Business version) says "If a
#     workspace owner turns off Memory for the workspace, existing saved memories
#     for members in that workspace are deleted." That page covers the Business
#     owner toggle. No fetched doc says whether this API's "Disables Memory for the
#     workspace" is the same setting, or whether turning off workspace Memory on
#     Enterprise deletes saved memories. Treat saved-memory loss as possible and
#     irreversible until a non-production workspace test shows otherwise.
#  3. "M3M" IS UNDEFINED in every fetched doc. The user route "Disables M3M
#     Memory for a workspace user"; the workspace route "Disables Memory for the
#     workspace". Whether those are the same switch is not stated.
#  4. DOTS EFFECT IS UNDOCUMENTED. Help 20001529: "Turning off Memory in ChatGPT
#     stops that sharing. It does not delete information that your dot has
#     already received." Whether THIS endpoint stops dot <-> ChatGPT memory
#     sharing the way the member toggle does, and whether it touches the dot's
#     own notes, is not documented. Dot notes cannot be viewed or deleted
#     individually; only resetting the dot (control 7.2) removes its context.
#     Validate on one test member before relying on it.
#  5. THE DELETE SCOPE IS BROAD. chatgpt.enterprise.compliance_export delete
#     authorizes 33 operations in v2.5.37, among them Delete User Conversation
#     and Delete GPT. Use a Custom key with a short expiration, held as a
#     break-glass credential.
#  6. AUDIT EVENT. "Compliance API Requests are now all logged as AUDIT_LOG
#     events" (Admin API v2.5.37, Version History 2.2.0; actor.type API_KEY).
#     The Memory Controls tag names the actions DELETE_AND_DISABLE_USER_MEMORY
#     (action_data user_id) and DELETE_AND_DISABLE_WORKSPACE_MEMORY (action_data
#     workspace_id); the Audit tag's own action catalog does not list them, so
#     confirm in a live tenant which name arrives. Check action_result (SUCCESS /
#     BLOCKED / ERROR) in the Compliance Logs Platform Audit feed. DELETE_MEMORY
#     records single-entry deletions only. A member's own Memory toggle has no
#     documented named action.
#  7. List User Memories documents has_more and last_id but no paging
#     parameter, so the dry-run count is a lower bound when has_more is true.
#  8. --workspace is asynchronous (202) and "queues deletion of each member's
#     About You summary cache" for EVERY member, not only dot users; a 503 means
#     "Workspace Memory was disabled, but the deletion request could not be
#     queued". It therefore also requires HTH_CONFIRM_WORKSPACE. Read the
#     saved-memory conflict in TRAP 2 first: validate on a non-production
#     workspace, and capture GET .../users/{user_id}/memories for affected
#     members before --apply.
#  9. PLAN. Enterprise only. Business owners use the workspace-wide Memory
#     toggle (no console path documented), which "deletes members' existing
#     saved memories" (help 9295112); Pro members use their own Memory setting
#     and Settings > Data controls > Improve the model for everyone.
# 10. PARTIAL RUNS. A 401, 403, unanswered (000) or still-rate-limited (429)
#     POST before anything was written exits 2 (nothing evaluated). Once any
#     member has been disabled, failures are counted, the run stops issuing
#     writes on 401/403/000/429, prints the members NOT ATTEMPTED, still prints
#     the VERIFY reminder, and exits 1. A 000 after a write means the state of
#     that member is unknown: check their Memory setting.
#
# Usage:
#   hth-chatgpt-dots-5.02-disable-user-memory.sh [--apply] USER_ID...
#   hth-chatgpt-dots-5.02-disable-user-memory.sh [--apply] --from-group GROUP_ID
#   hth-chatgpt-dots-5.02-disable-user-memory.sh [--apply] --workspace
# Exit codes: 0 dry-run or every write accepted | 1 a write failed or was
#   partial | 2 precondition
# =============================================================================

set -euo pipefail
HTH_PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=common.sh
. "${HTH_PACK_DIR}/common.sh"

APPLY=0; SCOPE="users"; FROM_GROUP=""; USERS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --apply)      APPLY=1 ;;
    --workspace)  SCOPE="workspace" ;;
    --from-group) shift; FROM_GROUP="${1:-}"; [ -n "${FROM_GROUP}" ] || cgpt_die "--from-group needs a group ID" ;;
    -h|--help)    sed -n '/^# Usage:/,/^# Exit codes/p' "$0" >&2; exit 2 ;;
    -*)           cgpt_die "unknown option $1" ;;
    *)            USERS+=("$1") ;;
  esac
  shift
done

cgpt_require
CGPT_SCOPE_HINT="chatgpt.enterprise.compliance_export delete (write) / read (memory counts)"

# HTH Guide Excerpt: begin preflight-memory-targets
# Resolve targets and show, per member, the saved-memory entries that remain
# after the call (TRAP 2). Read-only.
if [ "${SCOPE}" = "users" ]; then
  if [ -n "${FROM_GROUP}" ]; then
    cgpt_safe_id "${FROM_GROUP}" "group ID"
    ROSTER="${CGPT_TMPDIR}/roster.jsonl"
    cgpt_paginate_cursor "/manage/workspaces/${CHATGPT_WORKSPACE_ID}/groups/${FROM_GROUP}/users" "${ROSTER}"
    while IFS= read -r U; do USERS+=("${U}"); done < <(jq -r 'select(.status == "active") | .id' "${ROSTER}")
  fi
  [ "${#USERS[@]}" -gt 0 ] || cgpt_die "no target users — pass USER_ID arguments or --from-group GROUP_ID"
  echo "=== ${#USERS[@]} target member(s) ==="
  for U in "${USERS[@]}"; do
    cgpt_safe_id "${U}" "user ID"
    cgpt_get "/compliance/workspaces/${CHATGPT_WORKSPACE_ID}/users/${U}/memories"
    case "${CGPT_CODE}" in
      200) jq -r --arg u "${U}" '"  \($u): \([(.data // [])[] | (.memory_contexts // [])[] | (.memory_entries // [])[]] | length)"
             + " saved-memory entries in \([(.data // [])[] | (.memory_contexts // [])[]] | length) context(s)"
             + (if .has_more == true then " (lower bound — has_more, TRAP 7)" else "" end)
             + " — NOT deleted by delete_and_disable"' "${CGPT_BODY}" ;;
      403) echo "  ${U}: memory count skipped (key lacks chatgpt.enterprise.compliance_export read)" ;;
      *)   cgpt_fail_http GET "/compliance/workspaces/${CHATGPT_WORKSPACE_ID}/users/${U}/memories" ;;
    esac
  done
fi
# HTH Guide Excerpt: end preflight-memory-targets

# HTH Guide Excerpt: begin apply-memory-delete-and-disable
# The write. Literal POST, no request body (the spec defines none), retried only
# on 429 — a 429 is a rejected request, so retrying cannot double-apply.
CGPT_POST_RETRIES=3
post_delete_and_disable() { # <path>
  local attempt=0 rc
  CGPT_RETRIES=0
  while :; do
    set +e
    CGPT_CODE="$(_cgpt_auth | curl -sS --path-as-is -K - -X POST -H "Content-Length: 0" -D "${CGPT_HDRS}" \
      -o "${CGPT_BODY}" -w '%{http_code}' "${CHATGPT_ADMIN_BASE}$1" 2>/dev/null)"
    rc=$?
    set -e
    [ "${rc}" -eq 0 ] || CGPT_CODE="000"
    if [ "${CGPT_CODE}" = "429" ] && [ "${attempt}" -lt "${CGPT_POST_RETRIES}" ]; then
      sleep "$(_cgpt_retry_after)"; attempt=$((attempt + 1)); CGPT_RETRIES="${attempt}"; continue
    fi
    return 0
  done
}

FAILED=0
if [ "${SCOPE}" = "workspace" ]; then
  P="/compliance/workspaces/${CHATGPT_WORKSPACE_ID}/memory/delete_and_disable"
  if [ "${APPLY}" -eq 0 ]; then
    echo "DRY-RUN: would POST ${P} — disables Memory for the WHOLE workspace and queues"
    echo "  deletion of every member's About You summary cache (TRAP 8). The Admin API says saved"
    echo "  memories are kept; help 9295112 says a workspace owner's Memory-off deletes them (TRAP 2)."
    echo "  Validate on a non-production workspace first, and capture GET .../users/{user_id}/memories"
    echo "  for affected members before --apply. Re-run with --apply and"
    echo "  HTH_CONFIRM_WORKSPACE=${CHATGPT_WORKSPACE_ID} to execute."
    exit 0
  fi
  [ "${HTH_CONFIRM_WORKSPACE:-}" = "${CHATGPT_WORKSPACE_ID}" ] \
    || cgpt_die "--workspace --apply needs HTH_CONFIRM_WORKSPACE=${CHATGPT_WORKSPACE_ID} (TRAP 8)"
  post_delete_and_disable "${P}"
  case "${CGPT_CODE}" in
    202) if jq -e '.status == "accepted"' "${CGPT_BODY}" >/dev/null 2>&1; then
           echo "ACCEPTED: workspace Memory disabled; deletion request $(jq -r '.id' "${CGPT_BODY}") queued (asynchronous)"
         else
           echo "FAIL: HTTP 202 without status \"accepted\""; FAILED=1
         fi ;;
    503) echo "PARTIAL: Workspace Memory was disabled, but the deletion request could not be queued — re-run --apply"; FAILED=1 ;;
    500) echo "FAIL: the workspace setting or deletion request could not be persisted"; FAILED=1 ;;
    *)   cgpt_fail_http POST "${P}" ;;
  esac
else
  DONE=0; i=0
  for U in "${USERS[@]}"; do
    i=$((i + 1))
    P="/compliance/workspaces/${CHATGPT_WORKSPACE_ID}/users/${U}/memory/delete_and_disable"
    if [ "${APPLY}" -eq 0 ]; then
      echo "DRY-RUN: would POST ${P}"
      continue
    fi
    post_delete_and_disable "${P}"
    case "${CGPT_CODE}" in
      200) if jq -e '.status == "completed"' "${CGPT_BODY}" >/dev/null 2>&1; then
             echo "DISABLED: ${U} — Memory off, About You summary cache and M3M dream data deleted (saved memories kept per the API, TRAP 2)"
             DONE=$((DONE + 1))
           else
             echo "FAIL: ${U} — HTTP 200 without status \"completed\""; FAILED=$((FAILED + 1))
           fi ;;
      404) echo "FAIL: ${U} — the user or workspace was not found"; FAILED=$((FAILED + 1)) ;;
      500) echo "FAIL: ${U} — the setting update, cache invalidation, or a scoped deletion failed; state unknown, check the member's Memory setting"
           FAILED=$((FAILED + 1)) ;;
      401|403|429|000)
           # Key-level or quota-level: every later POST would fail the same way.
           if [ $((DONE + FAILED)) -eq 0 ] && [ "${CGPT_CODE}" != "000" ]; then
             cgpt_fail_http POST "${P}"            # nothing written yet: a true precondition
           fi
           if [ "${CGPT_CODE}" = "000" ]; then
             echo "FAIL: ${U} — no HTTP response; state unknown, check the member's Memory setting (TRAP 10)"
           else
             echo "FAIL: ${U} — HTTP ${CGPT_CODE} after ${CGPT_RETRIES} retr(y/ies); stopping (TRAP 10)"
           fi
           FAILED=$((FAILED + 1))
           echo "  ${DONE} member(s) already disabled above"
           [ "${i}" -ge "${#USERS[@]}" ] || echo "NOT ATTEMPTED (re-run with these IDs): ${USERS[*]:i}"
           break ;;
      *)   echo "FAIL: ${U} — HTTP ${CGPT_CODE}. Body: $(head -c 300 "${CGPT_BODY}" 2>/dev/null | tr '\n' ' ')"
           FAILED=$((FAILED + 1)) ;;
    esac
  done
  [ "${APPLY}" -eq 1 ] || echo "DRY-RUN complete — nothing written. Re-run with --apply to execute."
fi

[ "${APPLY}" -eq 0 ] || echo "VERIFY: the API cannot read Memory state (TRAP 1) — confirm Settings > Personalization > Memory is off for each member."
[ "${FAILED}" -eq 0 ] || exit 1
exit 0
# HTH Guide Excerpt: end apply-memory-delete-and-disable
