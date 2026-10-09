#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-dots-7.1
#   guide:   https://howtoharden.com/guides/chatgpt-dots/#71-rehearse-the-dots-kill-sequence-stop-the-dots-work-and-revoke-every-grant
#   profile: L1
#   mode:    mutating
#   requires: CHATGPT_ADMIN_KEY(workspace Admin key, Custom: chatgpt.enterprise.directory read + write), CHATGPT_WORKSPACE_ID(UUID), HTH_DOTS_GROUP_IDS(comma-separated IDs of the groups assigned a dots-granting role), curl, jq
# =============================================================================
# HTH ChatGPT Dots Control 7.1: Rehearse the dots kill sequence: stop the dot's
#   work and revoke every grant
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls v8 17.4, 6.2; NIST 800-53 IR-4, AC-2, CM-3;
#   SOC 2 CC7.4; no benchmark equivalent yet
#
# Sources (fetched 2026-10-08):
#   https://chatgpt.com/public/admin/api-reference   (Admin API v2.5.37:
#     GET    /manage/workspaces/{workspace_id}/groups/{group_id}                    Get Group
#     GET    /manage/workspaces/{workspace_id}/groups/{group_id}/users              List Group Users
#     DELETE /manage/workspaces/{workspace_id}/groups/{group_id}/users/{user_id}    Remove Group User
#            200 {object: directory.workspace.group_user.deleted, deleted: true, ...};
#            409 "such as a SCIM-managed group" (code scim_managed_resource)
#     GET    /manage/workspaces/{workspace_id}/users/{user_id}/groups               List User Groups)
#   https://learn.chatgpt.com/docs/enterprise/dots-admin-guide
#   https://help.openai.com/en/articles/20001554-manage-dots-in-chatgpt-workspaces
#   https://learn.chatgpt.com/docs/dots/controls
#   https://help.openai.com/en/articles/20001530-getting-started-with-your-dot
#   https://learn.chatgpt.com/docs/enterprise/cloud-local-access
#
# THE ADMIN HALF OF THE KILL SWITCH IS PARTIAL BY DESIGN. No admin pause, reset
# or delete of a member's dot exists; the admin FAQ answer is "Revoke dots
# access through workspace permissions". The one part an API can do is take the
# member out of the manually managed group that carries the dots role. This pack
# does that (dry-run by default), proves the group no longer lists them, and
# prints the console and owner-side steps that finish the sequence.
#
# TRAPS
#  1. A GROUP IS ONE GRANT OF SEVERAL. Help 20001554: review "Use dots (Beta) in
#     the workspace default and all roles assigned directly to the member or
#     through groups, then remove every applicable grant". The API sees none of
#     the workspace default, role permissions or direct assignments.
#  2. TIER 1 CONFLICT ON HOW ROLES COMBINE: additive (learn
#     roles-and-workspace-permissions, help 20001554, the ROLE_CREATE schema)
#     vs "an explicit Off in any role denies that permission" (learn
#     groups-and-provisioning). Removing every grant is correct under both.
#  3. SCIM GROUPS. Remove Group User returns 409 scim_managed_resource. Remove
#     the member in the IdP; a later sync can restore a workspace-side change.
#     This pack refuses to call DELETE on a group whose source is "scim".
#  4. REVOCATION IS NOT DISCONNECTION. "removing dots access does not replace
#     disconnecting an app or signing out of a website"; "an already authorized
#     local task may still be finishing" (learn cloud-local-access); "Stopping
#     work doesn't undo completed actions."
#  5. SCHEDULES AND IN-FLIGHT CLOUD TASKS. Whether revocation stops them is
#     undocumented. Pause scope conflicts: learn dots/controls says Pause "doesn't
#     stop every delegated task or cancel future scheduled runs"; help 20001530
#     says it stops the dot until resumed. Take the conservative reading. The
#     Admin API's Delete User Automation exists, but no doc says dot schedules
#     are Compliance API automations, so this pack does not call it.
#  6. THE REVOCATION KEY IS A GRANT KEY. chatgpt.enterprise.directory write also
#     authorizes Add Group User, Bulk Add, Create/Update/Delete Group. Hold it as
#     a break-glass credential with a short expiration.
#  7. PROPAGATION AND EVIDENCE. RBAC changes "can take up to 5 minutes to take
#     effect". This pack's DELETE is an Admin API request made with an API key,
#     so it is logged as AUDIT_LOG DELETE_WORKSPACE_DIRECTORY_GROUP_USER
#     (workspace_id, group_id, user_id; actor.type API_KEY), not GROUP_REMOVE_USER.
#     GROUP_REMOVE_USER (group_id, group_name, removed_user_id) is the "Admin
#     actions" event for removals made outside the Admin API. p99 under 30
#     minutes. Pull it with 6.01 (HTH_CLP_EVENT_TYPES=AUDIT_LOG) and filter on
#     .action; 6.02's governance filter deliberately leaves removals out.
#     tenant.group.member.removed (6.02 --feed tenant) is a possible cross-check
#     only: no doc maps a workspace group removal to it. The spec does not say
#     whether an API removal ALSO emits GROUP_REMOVE_USER.
#  8. PLAN. Enterprise (incl. Edu and Healthcare) only.
#  9. ORDER. With a cooperative owner on an uncompromised account (guide 7.1
#     Path A), the owner-side steps belong BEFORE this pack runs: no doc says a
#     member whose grant is revoked can still open the dot profile, Activity or
#     Scheduled. On Path B (owner unreachable or compromised) run this first and
#     treat the owner-side steps as unverified.
# 10. PARTIAL RUNS. A DELETE answered 429 is retried after Retry-After (a 429 is
#     a rejected request, so retrying cannot double-apply). A 401, 403, 429 after
#     retries, or no response before anything was removed exits 2 (nothing
#     evaluated). Once any removal has landed, failures are counted, writes stop
#     on 401/403/000, the verify block still runs, and the pack exits 1.
#
# Usage: hth-chatgpt-dots-7.01-revoke-dots-group-membership.sh [--apply] TARGET...
#   TARGET = a member's user ID (user-…) or email address
# Exit codes: 0 every matched membership removed (or planned, in dry-run) and
#   verified | 1 a removal failed, did not verify, or needs IdP action (SCIM)
#   | 2 precondition
# =============================================================================

set -euo pipefail
HTH_PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=common.sh
. "${HTH_PACK_DIR}/common.sh"

APPLY=0; TARGETS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    -h|--help) sed -n '/^# Usage:/,/^# Exit codes/p' "$0" >&2; exit 2 ;;
    -*) cgpt_die "unknown option $1" ;;
    *) TARGETS+=("$1") ;;
  esac
  shift
done

cgpt_require
CGPT_SCOPE_HINT="chatgpt.enterprise.directory read + write"
[ -n "${HTH_DOTS_GROUP_IDS:-}" ] || cgpt_die "set HTH_DOTS_GROUP_IDS — the group(s) your dots-granting role is assigned to"
[ "${#TARGETS[@]}" -gt 0 ] || cgpt_die "name at least one TARGET (user ID or email)"
TARGETS_JSON="$(printf '%s\n' "${TARGETS[@]}" | jq -R -s -c '[split("\n")[] | select(length > 0) | ascii_downcase]')"

# HTH Guide Excerpt: begin revoke-resolve-targets
# Read-only: find each target in each dots group, and refuse SCIM-owned groups.
PLAN="${CGPT_TMPDIR}/plan.tsv"
: > "${PLAN}"
FAILED=0
IFS=',' read -r -a RAW_GROUP_IDS <<<"${HTH_DOTS_GROUP_IDS}"
GROUP_IDS=()
for GID in "${RAW_GROUP_IDS[@]+"${RAW_GROUP_IDS[@]}"}"; do
  GID="$(printf '%s' "${GID}" | tr -d '[:space:]')"
  if [ -n "${GID}" ]; then GROUP_IDS+=("${GID}"); fi
done
[ "${#GROUP_IDS[@]}" -gt 0 ] \
  || cgpt_die "HTH_DOTS_GROUP_IDS contained no group ID after splitting on commas"
for GID in "${GROUP_IDS[@]}"; do
  cgpt_safe_id "${GID}" "group ID"
  cgpt_get_ok "/manage/workspaces/${CHATGPT_WORKSPACE_ID}/groups/${GID}"
  jq -e '.source | IN("manual", "scim")' "${CGPT_BODY}" >/dev/null 2>&1 \
    || cgpt_die "Get Group ${GID} returned HTTP 200 without the documented source field"
  G_NAME="$(jq -r '.name // "(unnamed)"' "${CGPT_BODY}")"
  G_SOURCE="$(jq -r '.source' "${CGPT_BODY}")"
  ROSTER="${CGPT_TMPDIR}/roster-${GID}.jsonl"
  cgpt_paginate_cursor "/manage/workspaces/${CHATGPT_WORKSPACE_ID}/groups/${GID}/users" "${ROSTER}"
  MATCHES="$(jq -r --argjson t "${TARGETS_JSON}" --arg gid "${GID}" --arg gname "${G_NAME}" '
      select(((.id | ascii_downcase) as $i | $t | any(.[]; . == $i))
             or (((.email // "") | ascii_downcase) as $e | $e != "" and ($t | any(.[]; . == $e))))
      | [$gid, $gname, .id, (.email // "(no email)")] | @tsv' "${ROSTER}")"
  [ -n "${MATCHES}" ] || continue
  if [ "${G_SOURCE}" = "scim" ]; then
    while IFS=$'\t' read -r _ _ UID_ EMAIL; do
      echo "IdP ACTION REQUIRED: ${EMAIL} (${UID_}) is in SCIM-managed group ${G_NAME} — remove them in the IdP (TRAP 3)"
      FAILED=$((FAILED + 1))
    done <<<"${MATCHES}"
    continue
  fi
  printf '%s\n' "${MATCHES}" >> "${PLAN}"
done
jq -r -R -s --argjson t "${TARGETS_JSON}" '
    [split("\n")[] | select(length > 0) | split("\t") | (.[2] | ascii_downcase), (.[3] | ascii_downcase)] as $hit
    | $t[] | . as $want | select(($hit | any(.[]; . == $want)) | not)
    | "NOT IN ANY LISTED MANUAL GROUP: \(.) — already removed, SCIM-managed, or granted another way (TRAP 1)"' "${PLAN}"
# HTH Guide Excerpt: end revoke-resolve-targets

# HTH Guide Excerpt: begin revoke-remove-group-membership
# The write: one literal DELETE per (group, member). Dry-run unless --apply.
# A 429 is retried after Retry-After (TRAP 10); -D captures THIS response's headers.
CGPT_DELETE_RETRIES=5
delete_group_user() { # <path>
  local attempt=0 rc
  CGPT_RETRIES=0
  while :; do
    set +e
    CGPT_CODE="$(_cgpt_auth | curl -sS --path-as-is -K - -X DELETE -D "${CGPT_HDRS}" -o "${CGPT_BODY}" \
      -w '%{http_code}' "${CHATGPT_ADMIN_BASE}$1" 2>/dev/null)"
    rc=$?
    set -e
    [ "${rc}" -eq 0 ] || CGPT_CODE="000"
    if [ "${CGPT_CODE}" = "429" ] && [ "${attempt}" -lt "${CGPT_DELETE_RETRIES}" ]; then
      sleep "$(_cgpt_retry_after)"; attempt=$((attempt + 1)); CGPT_RETRIES="${attempt}"; continue
    fi
    return 0
  done
}

WRITES_DONE=0
while IFS=$'\t' read -r GID G_NAME UID_ EMAIL; do
  [ -n "${GID}" ] || continue
  cgpt_safe_id "${UID_}" "user ID"
  P="/manage/workspaces/${CHATGPT_WORKSPACE_ID}/groups/${GID}/users/${UID_}"
  if [ "${APPLY}" -eq 0 ]; then
    echo "DRY-RUN: would DELETE ${P}   (${EMAIL} from ${G_NAME})"
    continue
  fi
  delete_group_user "${P}"
  case "${CGPT_CODE}" in
    # The spec requires only workspace_id, group_id and user_id on a 200 body, so
    # a 200 echoing the IDs counts; the List User Groups verify below is the real check.
    200) if jq -e --arg u "${UID_}" --arg g "${GID}" \
             '.deleted == true or (.user_id == $u and .group_id == $g)' "${CGPT_BODY}" >/dev/null 2>&1; then
           echo "REMOVED: ${EMAIL} (${UID_}) from ${G_NAME}"; WRITES_DONE=$((WRITES_DONE + 1))
         else
           echo "FAIL: ${EMAIL} — HTTP 200 without deleted: true or the documented IDs"; FAILED=$((FAILED + 1))
         fi ;;
    409) echo "FAIL: ${EMAIL} — 409 conflict with directory state (SCIM-managed?): $(head -c 300 "${CGPT_BODY}")"
         FAILED=$((FAILED + 1)) ;;
    404) echo "FAIL: ${EMAIL} — not found (the workspace, user or group; possibly already removed — see verify)"
         FAILED=$((FAILED + 1)) ;;
    400) echo "FAIL: ${EMAIL} — HTTP 400 invalid request input: $(head -c 300 "${CGPT_BODY}")"; FAILED=$((FAILED + 1)) ;;
    401|403|429|000)
         if [ "${WRITES_DONE}" -eq 0 ] && [ "${CGPT_CODE}" != "000" ]; then
           cgpt_fail_http DELETE "${P}"            # nothing removed yet: a true precondition
         fi
         echo "FAIL: ${EMAIL} — HTTP ${CGPT_CODE} after ${CGPT_RETRIES} retr(y/ies)$([ "${CGPT_CODE}" = "000" ] && echo ' (no response; state unknown — see verify)')"
         FAILED=$((FAILED + 1))
         if [ "${CGPT_CODE}" != "429" ]; then
           echo "  stopping writes (TRAP 10); ${WRITES_DONE} removal(s) already landed above"
           break
         fi ;;
    *)   echo "FAIL: ${EMAIL} — HTTP ${CGPT_CODE}: $(head -c 300 "${CGPT_BODY}" 2>/dev/null | tr '\n' ' ')"
         FAILED=$((FAILED + 1)) ;;
  esac
done < "${PLAN}"
# HTH Guide Excerpt: end revoke-remove-group-membership

# HTH Guide Excerpt: begin revoke-verify-and-finish
# Read-only proof: every group each member is still in. After --apply, the
# group just removed must be gone; any other group listed may still grant dots.
while IFS= read -r UID_; do
  [ -n "${UID_}" ] || continue
  cgpt_safe_id "${UID_}" "user ID"
  UG="${CGPT_TMPDIR}/user-groups-${UID_}.jsonl"
  cgpt_paginate_cursor "/manage/workspaces/${CHATGPT_WORKSPACE_ID}/users/${UID_}/groups" "${UG}"
  echo "=== ${UID_} is still in $(wc -l < "${UG}" | tr -d ' ') group(s) ==="
  jq -r '"  \(.name // "(unnamed)") (\(.id))  source=\(.source)"' "${UG}"
  [ "${APPLY}" -eq 1 ] || continue
  while IFS= read -r GID; do
    if jq -e --arg g "${GID}" 'select(.id == $g)' "${UG}" >/dev/null 2>&1; then
      echo "  FAIL: still listed in ${GID} after removal"; FAILED=$((FAILED + 1))
    fi
  done < <(awk -F'\t' -v u="${UID_}" '$3 == u {print $1}' "${PLAN}")
done < <(cut -f3 "${PLAN}" | sort -u)

echo ""
echo "FINISH THE SEQUENCE (no API exists for these — TRAPS 1, 4, 5, 9):"
echo "  Workspace owner: Workspace settings > Permissions & roles — Use dots (Beta) granted by no other"
echo "    custom role, direct role, or the Workspace default. Allow up to 5 minutes to propagate."
echo "  Dot owner, dot profile: ••• > Pause; stop delegated tasks in Activity; disable or delete"
echo "    Scheduled entries; Computers > Your computer > Revoke access. On Path A these steps belong"
echo "    BEFORE this pack runs; on Path B record whether they were still reachable (TRAP 9)."
echo "  Disconnect apps at the source systems, sign out of websites, then Reset (delete) the dot (control 7.2)."
echo "  Evidence: AUDIT_LOG DELETE_WORKSPACE_DIRECTORY_GROUP_USER for this pack's removals (GROUP_REMOVE_USER for"
echo "    console removals), via pack 6.01 HTH_CLP_EVENT_TYPES=AUDIT_LOG (p99 under 30 minutes) — TRAP 7."
[ "${APPLY}" -eq 1 ] || echo "DRY-RUN complete — nothing written. Re-run with --apply to execute."
[ "${FAILED}" -eq 0 ] || exit 1
exit 0
# HTH Guide Excerpt: end revoke-verify-and-finish
