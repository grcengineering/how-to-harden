#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-bot-7.1
#   guide:   https://howtoharden.com/guides/grok-bot/#71-offboard-completely-delete-computer-data-remove-access-revoke-sessions
#   profile: L1
#   mode:    mutating
#   requires: CURSOR_ORG_API_KEY(Organization API key, admin:* only; computer operations turned on for the team), CURSOR_ADMIN_API_KEY(Team API key, admin:*; Enterprise), CURSOR_TEAM_ID(integer team id), HTH_OFFBOARD_EMAIL(the leaver's email), HTH_OFFBOARD_OPERATION_ID(optional, to resume THIS pack's own delete), curl, jq, uuidgen
# =============================================================================
# HTH Grok Bot Control 7.1: Offboard Completely: Delete Computer Data, Remove Access, Revoke Sessions
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls v8 5.3, 6.2; NIST 800-53 AC-2, PS-4, MP-6; SOC 2 CC6.2, CC6.5;
#             ISO 27001:2022 A.5.18, A.6.5, A.8.10
# Sources (transcribed from, fetched 2026-10-08):
#   https://cursor.com/docs/account/organizations/organization-admin-api#list-organization-members
#   https://cursor.com/docs/account/organizations/organization-admin-api#start-grok-bot-computer-operation
#   https://cursor.com/docs/account/organizations/organization-admin-api#get-grok-bot-computer-operation
#   https://cursor.com/docs/account/teams/admin-api#remove-team-member
#   https://cursor.com/docs/account/teams/admin-api#get-team-members
#   https://cursor.com/docs/account/teams/admin-api#get-model-access-configuration (re-checked 2026-10-09)
#   https://cursor.com/docs/enterprise/compliance-and-monitoring (remove_user, credentials_revoked, grok_bot_vm_bulk)
# Dependencies: curl, jq, uuidgen (or HTH_OFFBOARD_OPERATION_ID), ./common.sh
#
# Usage: HTH_OFFBOARD_EMAIL=leaver@example.com CURSOR_TEAM_ID=7 \
#          bash hth-grok-bot-7.01-offboard-member.sh [--apply]
#   both modes        prove the Team key belongs to CURSOR_TEAM_ID (TRAP 6), and
#                     that the leaver is an active member of that team, before
#                     anything irreversible is even planned
#   without --apply   resolve the member and print both requests; nothing changes
#   --apply           1. POST /organizations/teams/:teamId/grok-bot/operations
#                        {"action":"delete_vm_and_data","userIds":[<numeric id>],"operationId":<uuid>}
#                     2. poll the operation until it leaves `running`
#                     3. ONLY if the polled operation is this delete_vm_and_data
#                        (TRAP 7) and this member's item is `succeeded`:
#                        POST /teams/remove-member {"email": ...}
#                     4. confirm GET /teams/members no longer lists them as active
#
# ── TRAP 1: the order is the control ────────────────────────────────────────
# delete_vm_and_data needs "a current member of the team who has signed in to
# Cursor"; for anyone else "the request returns 400 and nothing starts". No
# admin path is documented to delete a removed member's durable data later (the
# fallback is a written deletion request under the DPA). So data goes FIRST and
# removal second — and on SCIM-managed teams, run this BEFORE unassigning the
# user in the IdP, because SCIM removal would otherwise win the race.
#
# ── TRAP 2: it cannot be undone ─────────────────────────────────────────────
# "delete_vm_and_data - Delete the computer and its durable data, so the member
# starts from empty. This can't be undone." Hence dry run by default.
#
# ── TRAP 3: two id formats, and the docs disagree about them ────────────────
# Computer operations take NUMERIC userIds from GET /organizations/members.
# That page says the numeric id matches "the id returned by the team GET
# /teams/members endpoint", but /teams/members documents encoded
# `user_…` string ids. This pack never maps one onto the other: it resolves the
# numeric id by email on the Organization API and removes the member by email
# on the Team API ("Provide either userId or email, but not both").
#
# ── TRAP 4: per-team enablement and key scopes ──────────────────────────────
# Computer operations are "turned on per team; contact your account team ...
# Until then, every route returns 403", and accept only an Organization key with
# admin:* (other scopes return 401). remove-member is "Enterprise only", and
# refuses to leave the team without a paid member or an admin. One operation
# runs per team at a time: a 409 names the running one (runningOperationId).
#
# ── TRAP 5: sessions may survive removal ────────────────────────────────────
# The audit pair remove_user + credentials_revoked records what happened to
# access. sessions=retained means the member still belongs to another team in
# the organization and their sessions stay valid — offboard every team, and
# revoke the user's IdP sessions too. grok_bot_vm_bulk (bulk_permanent_delete)
# reports counts only: "Its child operations emit no rows", so the per-member
# proof is this pack's operation items.
#
# ── TRAP 6: two keys, one team ──────────────────────────────────────────────
# The delete runs on CURSOR_TEAM_ID through the Organization API, but
# remove-member and GET /teams/members act on whichever team the Team key
# belongs to: "Team API keys can only act within one team", and those routes
# take no team id. A Team key for another team the leaver is also in would
# remove them THERE, confirm against that team, and leave access on
# CURSOR_TEAM_ID. The pack therefore proves the binding first
# (gb_require_team_key_matches: GET /teams/model-access/configuration's teamId,
# "Integer team ID implied by the API key", else a member-set comparison), and
# requires the leaver to be active on the Team key's team, so remove-member
# cannot fail with "User is not a member of this team" after the delete.
#
# ── TRAP 7: a reused operationId is someone else's operation ────────────────
# "Cursor returns 202 for the existing operation instead of starting a second
# one ... Cursor doesn't compare the rest of the body on a retry, so generate a
# new UUID for every new operation." A stale id (for example one exported while
# containing the same member with the 7.02 pack) would return a terminate_vm
# whose item for this member is `succeeded`, and terminate KEEPS the durable
# disk. So this pack resumes only through HTH_OFFBOARD_OPERATION_ID, checks a
# resumed id before posting, and refuses to remove the member unless the polled
# operation's operationId and action are this delete_vm_and_data.
#
# Exit codes: 0 offboarded (or dry run — this is a runbook action, see common.sh)
# | 1 delete did not succeed for the member, or removal could not be confirmed |
# 2 precondition (including a key/team mismatch or a reused operationId)
# =============================================================================

set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

for a in "$@"; do
  case "${a}" in
    --apply) GB_APPLY=1 ;;
    *) echo "PRECONDITION: unknown argument '${a}' (expected: [--apply])" >&2; exit 2 ;;
  esac
done
if [ -z "${HTH_OFFBOARD_EMAIL:-}" ]; then
  echo "PRECONDITION: set HTH_OFFBOARD_EMAIL to the leaver's Cursor email" >&2
  exit 2
fi
gb_require_team_id
gb_require_key org
gb_require_key team

# HTH Guide Excerpt: begin offboard-delete-then-remove
offboard() {
  local members uid op body status item state active
  # 0. Both keys must point at CURSOR_TEAM_ID, and the leaver must be active on
  #    the Team key's team, before anything irreversible is planned (TRAP 6).
  gb_require_team_key_matches
  gb_get team /teams/members
  gb_require "GET /teams/members" 200
  gb_shape '.teamMembers | type == "array"' "GET /teams/members"
  active=$(jq -r --arg e "${HTH_OFFBOARD_EMAIL}" '[.teamMembers[] | select((.email | ascii_downcase) == ($e | ascii_downcase) and .isRemoved == false)] | length' "${GB_BODY_FILE}")
  if [ "${active}" -ne 1 ]; then
    echo "PRECONDITION: ${HTH_OFFBOARD_EMAIL} is not exactly one active member of the Team key's team (found ${active}) — remove-member would fail after an irreversible delete (TRAP 6)" >&2
    exit 2
  fi

  # 1. Numeric id for the Organization API, resolved by email (TRAP 3).
  members="$(gb_tmp members)"
  gb_org_members "${members}"
  uid=$(jq -r --arg e "${HTH_OFFBOARD_EMAIL}" 'select((.email | ascii_downcase) == ($e | ascii_downcase)) | .id' "${members}")
  if [ -z "${uid}" ] || [ "$(wc -l <<<"${uid}" | tr -d ' ')" -ne 1 ]; then
    echo "PRECONDITION: ${HTH_OFFBOARD_EMAIL} is not exactly one member of team ${CURSOR_TEAM_ID} — data can only be deleted for a current member (TRAP 1)" >&2
    exit 2
  fi
  echo "Grok Bot 7.1 — offboarding ${HTH_OFFBOARD_EMAIL} (numeric id ${uid}) from team ${CURSOR_TEAM_ID}"

  op=$(gb_uuid HTH_OFFBOARD_OPERATION_ID)
  # A resumed id must name THIS member's delete, or be unused (TRAP 7). The
  # status route documents two 404 bodies: "Operation not found." (never
  # started, or aged out) and "This operation finished, and its status is no
  # longer available." (completion can no longer be proven).
  if [ -n "${HTH_OFFBOARD_OPERATION_ID:-}" ]; then
    gb_get org "/organizations/teams/${CURSOR_TEAM_ID}/grok-bot/operations/${op}?limit=1000"
    case "${GB_CODE}" in
      200)
        if ! jq -e --argjson u "${uid}" '.action == "delete_vm_and_data" and ((.items == null) or any(.items[]; .userId == $u))' "${GB_BODY_FILE}" >/dev/null; then
          echo "PRECONDITION: HTH_OFFBOARD_OPERATION_ID ${op} is a $(jq -r '.action // "unknown"' "${GB_BODY_FILE}") operation that does not cover ${HTH_OFFBOARD_EMAIL} — unset it to start a new delete; the member was NOT removed (TRAP 7)" >&2
          exit 2
        fi ;;
      404)
        if jq -e '(.message // .error // "") | tostring | test("no longer available")' "${GB_BODY_FILE}" >/dev/null 2>&1; then
          echo "PRECONDITION: operation ${op} finished and its status is no longer available, so the delete cannot be proven — the member was NOT removed; unset HTH_OFFBOARD_OPERATION_ID to start a new delete (TRAP 7)" >&2
          exit 2
        fi ;;
      *) gb_require "GET /organizations/teams/${CURSOR_TEAM_ID}/grok-bot/operations/${op}" 200 ;;
    esac
  fi
  body=$(jq -nc --argjson u "${uid}" --arg op "${op}" '{action: "delete_vm_and_data", userIds: [$u], operationId: $op}')
  if [ "${GB_APPLY}" -ne 1 ]; then
    gb_plan POST "/organizations/teams/${CURSOR_TEAM_ID}/grok-bot/operations" "${body}"
    gb_plan POST /teams/remove-member "$(jq -nc --arg e "${HTH_OFFBOARD_EMAIL}" '{email: $e}')"
    echo "DRY RUN: nothing was changed. Re-run with --apply. delete_vm_and_data cannot be undone (TRAP 2)."
    return 0
  fi

  # 2. Delete the computer and its durable data. A retry with the same
  #    operationId returns the existing operation instead of starting another.
  gb_post org "/organizations/teams/${CURSOR_TEAM_ID}/grok-bot/operations" "${body}"
  if [ "${GB_CODE}" = "409" ]; then
    echo "PRECONDITION: another computer operation is running for this team: $(jq -r '.runningOperationId // "unknown (use GET .../operations/latest)"' "${GB_BODY_FILE}")" >&2
    exit 2
  fi
  gb_require "POST /organizations/teams/${CURSOR_TEAM_ID}/grok-bot/operations" 202
  op=$(jq -r '.operationId // empty' "${GB_BODY_FILE}")
  if [ -z "${op}" ]; then echo "PRECONDITION: 202 without an operationId" >&2; exit 2; fi
  echo "  delete_vm_and_data queued: operationId=${op} (re-run with HTH_OFFBOARD_OPERATION_ID=${op} to resume)"

  # 3. Follow it to the end and read THIS member's result.
  status="$(gb_tmp operation)"
  gb_poll_operation "${op}" "${status}" HTH_OFFBOARD_OPERATION_ID
  # A reused operationId returns the EXISTING operation and Cursor does not
  # compare the body, so prove this is our delete before trusting its items (TRAP 7).
  if ! jq -e --arg op "${op}" '.operationId == $op and .action == "delete_vm_and_data"' "${status}" >/dev/null; then
    echo "PRECONDITION: operation ${op} is action=$(jq -r '.action // "unknown"' "${status}"), not delete_vm_and_data — HTH_OFFBOARD_OPERATION_ID names a different operation; unset it and re-run. The member was NOT removed (TRAP 7)" >&2
    exit 2
  fi
  item=$(jq -c --argjson u "${uid}" '(.items // [])[] | select(.userId == $u)' "${status}")
  if [ -z "${item}" ]; then item='{}'; fi
  state=$(jq -r '.state // "missing"' <<<"${item}")
  echo "  member result: state=${state} reason=$(jq -r '.reason // "none"' <<<"${item}")"
  if [ "${state}" != "succeeded" ]; then
    gb_fail "computer data was NOT deleted for ${HTH_OFFBOARD_EMAIL} — refusing to remove the member, because removal would end the only documented deletion path (TRAP 1)"
  fi

  # 4. Only now remove the member from the team.
  gb_post team /teams/remove-member "$(jq -nc --arg e "${HTH_OFFBOARD_EMAIL}" '{email: $e}')"
  gb_require_2xx "POST /teams/remove-member"
  if jq -e '.success == false' "${GB_BODY_FILE}" >/dev/null 2>&1; then
    gb_fail "remove-member answered success=false: $(jq -c '.' "${GB_BODY_FILE}")"
  fi

  # 5. Confirm, rather than trust the response.
  gb_get team /teams/members
  gb_require "GET /teams/members" 200
  gb_shape '.teamMembers | type == "array"' "GET /teams/members"
  if jq -e --arg e "${HTH_OFFBOARD_EMAIL}" 'any(.teamMembers[]; (.email | ascii_downcase) == ($e | ascii_downcase) and .isRemoved == false)' "${GB_BODY_FILE}" >/dev/null; then
    gb_fail "${HTH_OFFBOARD_EMAIL} is still listed as an active team member"
  fi
  echo "DONE: computer data deleted and ${HTH_OFFBOARD_EMAIL} removed from team ${CURSOR_TEAM_ID}."
  echo "  Next: confirm audit rows remove_user and credentials_revoked (sessions=revoked; 'retained' means"
  echo "  another org team still holds them — TRAP 5), offboard any other team, and revoke IdP sessions."
}
# HTH Guide Excerpt: end offboard-delete-then-remove

offboard
