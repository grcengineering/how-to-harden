#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-dots-1.1
#   guide:   https://howtoharden.com/guides/chatgpt-dots/#11-keep-use-dots-beta-off-by-default-and-grant-it-only-through-a-pilot-custom-role
#   profile: L1
#   mode:    read-only
#   requires: CHATGPT_ADMIN_KEY(workspace Admin key, Custom: chatgpt.enterprise.directory read), CHATGPT_WORKSPACE_ID(UUID), HTH_DOTS_GROUP_IDS(comma-separated IDs of the groups assigned a dots-granting role), HTH_DOTS_APPROVED(file of, or comma list of, approved emails / user IDs — not needed with --inventory), curl, jq
# =============================================================================
# HTH ChatGPT Dots Control 1.1: Keep Use dots (Beta) off by default and grant it
#   only through a pilot custom role
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls v8 6.8, 4.8; NIST 800-53 AC-3, AC-6, CM-7;
#   SOC 2 CC6.1, CC6.3; no benchmark equivalent yet
# Also serves: 2.2 (the group carrying "Add dots to Slack and Microsoft Teams")
#   and 4.1 (the group carrying "Use custom rules for dots") — point
#   HTH_DOTS_GROUP_IDS at those groups instead.
#
# Sources (fetched 2026-10-08):
#   https://chatgpt.com/public/admin/api-reference   (Admin API v2.5.37:
#     GET /manage/workspaces/{workspace_id}/groups/{group_id}        Get Group
#     GET /manage/workspaces/{workspace_id}/groups/{group_id}/users  List Group Users
#     scope chatgpt.enterprise.directory read; limit 1-100, opaque cursor, has_more)
#   https://learn.chatgpt.com/docs/enterprise/dots-admin-guide
#   https://help.openai.com/en/articles/20001554-manage-dots-in-chatgpt-workspaces
#   https://learn.chatgpt.com/docs/enterprise/roles-and-workspace-permissions
#   https://learn.chatgpt.com/docs/enterprise/groups-and-provisioning
#   https://help.openai.com/en/articles/11750701-managing-feature-access-with-role-based-access-control-in-chatgpt
#   https://help.openai.com/en/articles/9083985  (group manager permissions; fetched 2026-10-09)
#
# WHAT THIS PROVES, AND WHAT IT CANNOT. Admin API v2.5.37 has no role,
# permission, direct-assignment or workspace-default route. The only part of a
# dots grant an API can read is WHO SITS IN the group a dots-granting custom
# role is assigned to. This pack diffs that roster against your approved pilot
# list. It does not, and cannot, show that the role on the group grants
# Use dots (Beta), or that nothing else grants it.
#
# TRAPS
#  1. A ROSTER IS NOT EFFECTIVE ACCESS. Grants also arrive through the workspace
#     default and through direct role assignments (member profile > Direct
#     roles), and the API exposes neither. A clean diff here plus a console
#     review of the workspace default, every custom role, and every member's
#     direct roles is the whole check; the diff alone is half of it.
#  2. TIER 1 CONFLICT ON HOW ROLES COMBINE. learn roles-and-workspace-permissions
#     ("Ordinary role permissions combine additively: another assigned role can
#     still grant access") and help 20001554 say grants are additive.
#     learn groups-and-provisioning says "an explicit Off in any role denies that
#     permission, even when another role grants it". Unresolved in a live tenant
#     as of 2026-10-08. Treat grants as additive: an Off role is not a control.
#  3. SCIM-MANAGED GROUPS. List User Groups marks them `source: "scim"`. Their
#     roster reflects the last IdP sync; the IdP group is authoritative, so diff
#     that too. Writes to a SCIM group return 409 scim_managed_resource.
#  4. PROPAGATION. RBAC changes "can take up to 5 minutes to take effect"
#     (help 11750701). A roster read seconds after a change can predate it.
#  5. PLAN. Enterprise (incl. Edu and Healthcare) only. Business Premium and Pro
#     have no Admin API, so a 403/404 there is a plan boundary, not a finding.
#  6. member_count on the group object is compared with the rows actually
#     paged; a mismatch means membership moved during the read — re-run.
#  7. DYNAMIC GROUPS. learn groups-and-provisioning documents a third group
#     type, Dynamic ("Rules evaluated against SCIM user attributes"), but the
#     spec's group `source` enum lists only manual and scim. Any other source
#     value stops the run with a precondition (exit 2) rather than guessing.
#  8. ROLE EDITORS. Workspace Admins "may be able to view or update existing
#     roles", and in Enterprise group managers can "edit permitted settings on
#     custom roles assigned to their group" when an Owner turns on Edit
#     permissions on assigned roles (help 11750701). A clean roster says nothing
#     about who can change the role later; see guide 1.1 Step 5.
#
# Usage:
#   hth-chatgpt-dots-1.01-audit-dots-group-membership.sh             # diff (default)
#   hth-chatgpt-dots-1.01-audit-dots-group-membership.sh --inventory # roster only
# Exit codes: 0 pass (or --inventory) | 1 finding | 2 precondition
# =============================================================================

set -euo pipefail
HTH_PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=common.sh
. "${HTH_PACK_DIR}/common.sh"

MODE="diff"
case "${1:-}" in
  "") ;;
  --inventory) MODE="inventory" ;;
  *) echo "usage: $(basename "$0") [--inventory]" >&2; exit 2 ;;
esac

cgpt_require
CGPT_SCOPE_HINT="chatgpt.enterprise.directory read"
[ -n "${HTH_DOTS_GROUP_IDS:-}" ] \
  || cgpt_die "set HTH_DOTS_GROUP_IDS — the group ID(s) your dots-granting custom role is assigned to"

# Approved list: a readable file (one email or user ID per line, # comments ok)
# or a comma-separated string. Emails compare case-insensitively.
APPROVED_JSON="[]"
if [ "${MODE}" = "diff" ]; then
  [ -n "${HTH_DOTS_APPROVED:-}" ] \
    || cgpt_die "set HTH_DOTS_APPROVED (file or comma list of approved emails / user IDs), or run with --inventory"
  if [ -f "${HTH_DOTS_APPROVED}" ]; then
    APPROVED_JSON="$(sed -e 's/#.*//' "${HTH_DOTS_APPROVED}" | tr ',' '\n' \
      | jq -R -s -c '[split("\n")[] | gsub("^\\s+|\\s+$"; "") | select(length > 0) | ascii_downcase] | unique')"
  else
    APPROVED_JSON="$(printf '%s' "${HTH_DOTS_APPROVED}" \
      | jq -R -s -c '[split(",")[] | gsub("^\\s+|\\s+$"; "") | select(length > 0) | ascii_downcase] | unique')"
  fi
  [ "$(jq 'length' <<<"${APPROVED_JSON}")" -gt 0 ] || cgpt_die "HTH_DOTS_APPROVED parsed to an empty list"
fi

# HTH Guide Excerpt: begin audit-dots-group-roster
FINDINGS=0
ALL_MEMBERS="${CGPT_TMPDIR}/all-members.jsonl"
: > "${ALL_MEMBERS}"

# Normalise the list first: a value made only of commas and spaces (a templated
# variable that came out empty) must stop the run, not read zero groups and PASS.
IFS=',' read -r -a RAW_GROUP_IDS <<<"${HTH_DOTS_GROUP_IDS}"
GROUP_IDS=()
for GID in "${RAW_GROUP_IDS[@]+"${RAW_GROUP_IDS[@]}"}"; do
  GID="$(printf '%s' "${GID}" | tr -d '[:space:]')"
  if [ -n "${GID}" ]; then GROUP_IDS+=("${GID}"); fi
done
[ "${#GROUP_IDS[@]}" -gt 0 ] \
  || cgpt_die "HTH_DOTS_GROUP_IDS contained no group ID after splitting on commas"
GROUPS_READ=0
for GID in "${GROUP_IDS[@]}"; do
  cgpt_safe_id "${GID}" "group ID"

  # 1. The group itself: name, member_count, and whether SCIM owns its roster.
  cgpt_get_ok "/manage/workspaces/${CHATGPT_WORKSPACE_ID}/groups/${GID}"
  jq -e '(.id | type == "string") and (.source | IN("manual", "scim"))' "${CGPT_BODY}" >/dev/null 2>&1 \
    || cgpt_die "Get Group ${GID} returned HTTP 200 without the documented id/source fields"
  G_NAME="$(jq -r '.name // "(unnamed)"' "${CGPT_BODY}")"
  G_SOURCE="$(jq -r '.source' "${CGPT_BODY}")"
  G_COUNT="$(jq -r '.member_count // "?"' "${CGPT_BODY}")"
  GROUPS_READ=$((GROUPS_READ + 1))
  echo "=== Group ${G_NAME} (${GID}) — source=${G_SOURCE}, member_count=${G_COUNT} ==="
  [ "${G_SOURCE}" = "manual" ] \
    || echo "  NOTE: SCIM-managed — the IdP group is authoritative; diff it as well (TRAP 3)"

  # 2. Every member, every page.
  ROSTER="${CGPT_TMPDIR}/roster-${GID}.jsonl"
  cgpt_paginate_cursor "/manage/workspaces/${CHATGPT_WORKSPACE_ID}/groups/${GID}/users" "${ROSTER}"
  ROWS="$(wc -l < "${ROSTER}" | tr -d ' ')"
  if [ "${G_COUNT}" != "?" ] && [ "${G_COUNT}" != "${ROWS}" ]; then
    echo "  WARN: member_count=${G_COUNT} but ${ROWS} member row(s) paged — membership moved mid-read; re-run (TRAP 6)"
  fi
  jq -r '"  \(.email // "(no email)")  id=\(.id)  status=\(.status)  role=\(.role)  scim=\(.is_scim_managed)"' "${ROSTER}"
  cat "${ROSTER}" >> "${ALL_MEMBERS}"

  [ "${MODE}" = "diff" ] || continue

  # 3. Anyone in the group who is not on the approved list holds a dots grant
  #    nobody approved. A deactivated member cannot sign in; still remove them.
  while IFS=$'\t' read -r EMAIL UID_ STATUS; do
    if [ "${STATUS}" = "active" ]; then
      echo "  FINDING: ${EMAIL} (${UID_}) is ACTIVE in ${G_NAME} but not on the approved list"
      FINDINGS=$((FINDINGS + 1))
    else
      echo "  INFO: ${EMAIL} (${UID_}) is ${STATUS} in ${G_NAME} and not approved — remove at next cleanup"
    fi
  done < <(jq -r --argjson ok "${APPROVED_JSON}" '
      ((.id | ascii_downcase) as $i | $ok | any(.[]; . == $i)) as $id_ok
      | (((.email // "") | ascii_downcase) as $e | $e != "" and ($ok | any(.[]; . == $e))) as $email_ok
      | select(($id_ok or $email_ok) | not)
      | [(.email // "(no email)"), .id, .status] | @tsv' "${ROSTER}")
done

# 4. Approved people who are in none of the groups: not a risk, but the pilot
#    list and the workspace have drifted apart.
if [ "${MODE}" = "diff" ]; then
  jq -r -s --argjson ok "${APPROVED_JSON}" '
      ([.[] | (.id | ascii_downcase), ((.email // "") | ascii_downcase)] | unique) as $have
      | $ok[] | . as $want | select(($have | any(.[]; . == $want)) | not)
      | "  INFO: approved entry \(.) is not a member of any listed group"' "${ALL_MEMBERS}"
fi

echo ""
echo "NOT COVERED BY THE API (console review required — TRAP 1):"
echo "  Workspace settings > Permissions & roles > Permissions > Workspace default > Workspace capabilities > Use dots (Beta) = Off"
echo "  Every other custom role: Use dots (Beta) not On; every member's Direct roles: no dots-granting role"
echo "  Groups > [group] > Group manager permissions: Edit permissions on assigned roles off (control 1.1 Step 5)"

[ "${GROUPS_READ}" -gt 0 ] || cgpt_die "no group was read — refusing to report a result"
if [ "${MODE}" = "inventory" ]; then
  echo "INVENTORY ONLY — no approved list was compared, so this is not a pass"
  exit 0
fi
[ "${FINDINGS}" -eq 0 ] && { echo "PASS: every active member of the listed group(s) is approved"; exit 0; }
echo "${FINDINGS} finding(s)"
exit 1
# HTH Guide Excerpt: end audit-dots-group-roster
