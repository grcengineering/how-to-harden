#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-bot-7.2
#   guide:   https://howtoharden.com/guides/grok-bot/#72-prepare-a-grok-bot-containment-runbook
#   profile: L2
#   mode:    mutating
#   requires: CURSOR_ADMIN_API_KEY(Team API key; admin:* for disable, Enterprise), CURSOR_ORG_API_KEY(Organization API key, admin:* only, for terminate), CURSOR_TEAM_ID(integer team id, for terminate), HTH_CONTAIN_EMAILS(comma-separated) or HTH_CONTAIN_ALL(1 = every team member), HTH_CONTAIN_OPERATION_ID(optional, to resume THIS pack's own terminate), curl, jq, uuidgen
# =============================================================================
# HTH Grok Bot Control 7.2: Prepare a Grok Bot Containment Runbook
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls v8 17.4; NIST 800-53 IR-4, IR-8; SOC 2 CC7.4;
#             ISO 27001:2022 A.5.24, A.5.26
# Sources (transcribed from, fetched 2026-10-08):
#   https://cursor.com/docs/account/teams/admin-api#disable-grok-bot
#   https://cursor.com/docs/account/teams/admin-api#get-grok-bot-capabilities
#   https://cursor.com/docs/account/teams/admin-api#get-grok-bot-access
#   https://cursor.com/docs/account/organizations/organization-admin-api#start-grok-bot-computer-operation
#   https://cursor.com/docs/account/organizations/organization-admin-api#get-grok-bot-computer-operation
#   https://cursor.com/docs/account/organizations/organization-admin-api#get-latest-grok-bot-computer-operation
#   https://cursor.com/docs/account/organizations/organization-admin-api#list-organization-members
#   https://cursor.com/docs/grok-bot/computers ("Running work stops"; re-checked 2026-10-09)
#   https://cursor.com/docs/enterprise/compliance-and-monitoring (sand_onboarding, grok_bot_vm_bulk, grok_bot_routine)
# Dependencies: curl, jq, uuidgen (or HTH_CONTAIN_OPERATION_ID), ./common.sh
#
# Usage: bash hth-grok-bot-7.02-contain.sh [status] [disable] [terminate] [--apply]
#   status      (default) enabled flag, access mode, latest computer operation
#   disable     POST /grok-bot/disable — the WHOLE TEAM loses Grok Bot access
#   terminate   POST /organizations/teams/:teamId/grok-bot/operations
#               {"action":"terminate_vm", "userIds":[…], "operationId":<uuid>}
#               for HTH_CONTAIN_EMAILS, or every member when HTH_CONTAIN_ALL=1
#   --apply     send the writes; without it every write is printed, not sent
#   disable and terminate can be combined; disable runs first, after the pack
#   proves the Team key and CURSOR_TEAM_ID name the same team (common.sh
#   gb_require_team_key_matches), so both actions hit one team.
#
# ── TRAP 1: disable is team-wide, and is not documented to stop running work ─
# "Disable Grok Bot for the team. Members lose access; their computers are not
# deleted. Returns 403 on Teams plans." No doc says whether a Bot already
# working stops; Terminate is the documented stop ("Running work stops",
# cursor.com/docs/grok-bot/computers), so in an incident run
# `disable terminate --apply` together. Disable has no per-member form;
# per-member access is by billing group (PUT /grok-bot/access, see the 1.1 pack)
# or by removing the member (7.1). Rehearse on a dedicated pilot team — a
# tabletop on a production team takes Grok Bot away from everyone on it.
#
# ── TRAP 2: terminate keeps the durable disk ────────────────────────────────
# "terminate_vm - Delete the member's current computer and keep the durable
# disk. The member's next message starts a fresh computer." It stops what is
# running now; it is not data deletion (that is delete_vm_and_data, 7.1) and it
# does not stop the member starting again unless access is also removed.
#
# ── TRAP 3: Organization API prerequisites ──────────────────────────────────
# Computer operations take an Organization key with admin:* only ("Keys with any
# other scope return 401"), are "turned on per team" by the account team (403
# "Bot fleet admin API access is not enabled for this team" until then), take
# NUMERIC userIds from GET /organizations/members, up to 25,000 per operation,
# and run one at a time per team (409 with runningOperationId). Every id "must
# belong to a current member of the team who has signed in to Cursor; if one
# doesn't, the request returns 400 and nothing starts", and the error table
# also gives 400 for "a userId that isn't a current member of the team, or too
# many members". With HTH_CONTAIN_ALL=1 one unqualified member stops the whole
# terminate, and List Organization Members exposes no signed-in field to
# pre-filter on; on a 400 the pack names the remedies. Per-member results exist
# only for operations of 1,000 members or fewer. Confirm the enablement BEFORE
# an incident: `status` reads the latest operation, which returns 404 until one
# has run — and 404 is also the answer for a team not linked to the
# organization, so `status` checks GET /organizations/members?teamId= as well
# (an unlinked team returns an empty page) and reports "turned on" only when
# that page lists members.
#
# ── TRAP 4: what this cannot contain ────────────────────────────────────────
# Routines and their Slack/webhook triggers have no admin API or disable switch.
# Only the person who set up a routine can pause or delete it ("only they can
# see or change it", docs.x.ai/grok-bot/team-bots). The one admin route is
# deleting a Team Bot from Manage Team Bots, which removes every routine on it.
# Confirm the cleanup with grok_bot_routine disable/delete audit rows. The 401
# on disable can also mean "Grok Bot Admin API not enabled for the team"
# (common.sh TRAP C).
#
# ── TRAP 5: a reused operationId is someone else's operation ────────────────
# "Cursor doesn't compare the rest of the body on a retry, so generate a new
# UUID for every new operation." A stale id would return an older operation,
# for another action or other members, and its result would read as this
# terminate. The pack resumes only through HTH_CONTAIN_OPERATION_ID, checks the
# operation's action before following it, and checks that it covers exactly the
# requested members before reporting "terminated".
#
# Exit codes: 0 done (or dry run / status — this is a runbook action, see
# common.sh) | 1 an operation finished with failed members, or Grok Bot still
# reads enabled after disable | 2 precondition (including a reused operationId,
# a key/team mismatch, or a 400 on terminate)
# =============================================================================

set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

DO_STATUS=0; DO_DISABLE=0; DO_TERMINATE=0
for a in "$@"; do
  case "${a}" in
    status)    DO_STATUS=1 ;;
    disable)   DO_DISABLE=1 ;;
    terminate) DO_TERMINATE=1 ;;
    --apply)   GB_APPLY=1 ;;
    *) echo "PRECONDITION: unknown argument '${a}' (expected: status | disable | terminate, plus --apply)" >&2; exit 2 ;;
  esac
done
if [ $((DO_DISABLE + DO_TERMINATE)) -eq 0 ]; then DO_STATUS=1; fi

status() {
  echo "Grok Bot 7.2 — containment status"
  gb_get team /grok-bot/capabilities
  if [ "${GB_CODE}" = "200" ]; then
    # `enabled` is a documented boolean; jq's // would turn false into "?".
    echo "  enabled: $(jq -r 'if (.enabled | type) == "boolean" then (.enabled | tostring) else "? (no boolean enabled field)" end' "${GB_BODY_FILE}")"
  else
    echo "  enabled: not readable (HTTP ${GB_CODE})"
  fi
  gb_get team /grok-bot/access
  gb_require "GET /grok-bot/access" 200
  echo "  access: mode=$(jq -r '.mode // "?"' "${GB_BODY_FILE}") groups=$(jq -c '[.groups[]?.name]' "${GB_BODY_FILE}")"
  if [ -n "${CURSOR_ORG_API_KEY:-}" ] && [ -n "${CURSOR_TEAM_ID:-}" ]; then
    gb_require_team_id
    gb_get org "/organizations/teams/${CURSOR_TEAM_ID}/grok-bot/operations/latest"
    case "${GB_CODE}" in
      200) echo "  latest computer operation: $(jq -c '{operationId, action, state, counts}' "${GB_BODY_FILE}")" ;;
      404)
        # 404 means "none yet" OR "team not linked" (TRAP 3): cross-check linkage.
        gb_get org "/organizations/members?teamId=${CURSOR_TEAM_ID}&pageSize=1"
        if [ "${GB_CODE}" = "200" ] && [ "$(jq '(.members // []) | length' "${GB_BODY_FILE}")" -gt 0 ]; then
          echo "  latest computer operation: none yet (404 until one has run); team ${CURSOR_TEAM_ID} is linked to this organization and did not answer 403, so computer operations are turned on"
        else
          echo "PRECONDITION: latest computer operation NOT CONFIRMED — this route also returns 404 for a team not linked to the organization, and GET /organizations/members?teamId=${CURSOR_TEAM_ID} returned HTTP ${GB_CODE} with no members (unlinked team, wrong id, or a team with no members)" >&2
          exit 2
        fi ;;
      *)   gb_require "GET /organizations/teams/${CURSOR_TEAM_ID}/grok-bot/operations/latest" 200 ;;
    esac
  else
    echo "  computer operations: not checked (set CURSOR_ORG_API_KEY and CURSOR_TEAM_ID)"
  fi
}

# HTH Guide Excerpt: begin contain-disable-grok-bot
disable_team() {
  if [ "${GB_APPLY}" -ne 1 ]; then
    gb_plan POST /grok-bot/disable
    echo "  (team-wide: every member loses Grok Bot access — TRAP 1)"
    return 0
  fi
  gb_post team /grok-bot/disable
  gb_require "POST /grok-bot/disable" 204
  echo "  POST /grok-bot/disable -> 204"
  gb_get team /grok-bot/capabilities
  gb_require "GET /grok-bot/capabilities" 200
  if [ "$(jq -r '.enabled' "${GB_BODY_FILE}")" != "false" ]; then
    gb_fail "Grok Bot still reads enabled=$(jq -r '.enabled' "${GB_BODY_FILE}") after disable"
  fi
  echo "  confirmed: enabled=false (audit: sand_onboarding with new_completed=false)"
}
# HTH Guide Excerpt: end contain-disable-grok-bot

# HTH Guide Excerpt: begin contain-terminate-computers
terminate_computers() {
  local members ids n op body opfile failed got
  gb_require_key org
  members="$(gb_tmp members)"
  gb_org_members "${members}"
  if [ "${HTH_CONTAIN_ALL:-0}" = "1" ]; then
    ids=$(jq -s -c 'map(.id) | unique' "${members}")
  elif [ -n "${HTH_CONTAIN_EMAILS:-}" ]; then
    ids=$(jq -s -c --arg e "${HTH_CONTAIN_EMAILS}" '
      ($e | ascii_downcase | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))) as $want
      | [.[] | select((.email | ascii_downcase) as $m | $want | index($m))] | map(.id) | unique' "${members}")
    if [ "$(jq 'length' <<<"${ids}")" -ne "$(jq -n --arg e "${HTH_CONTAIN_EMAILS}" '$e | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0)) | unique | length')" ]; then
      echo "PRECONDITION: not every address in HTH_CONTAIN_EMAILS is a member of team ${CURSOR_TEAM_ID}" >&2
      exit 2
    fi
  else
    echo "PRECONDITION: terminate needs HTH_CONTAIN_EMAILS or HTH_CONTAIN_ALL=1" >&2
    exit 2
  fi
  n=$(jq 'length' <<<"${ids}")
  if [ "${n}" -lt 1 ] || [ "${n}" -gt 25000 ]; then
    echo "PRECONDITION: terminate_vm takes 1-25,000 members (got ${n})" >&2
    exit 2
  fi

  op=$(gb_uuid HTH_CONTAIN_OPERATION_ID)
  body=$(jq -nc --argjson u "${ids}" --arg op "${op}" '{action: "terminate_vm", userIds: $u, operationId: $op}')
  if [ "${GB_APPLY}" -ne 1 ]; then
    gb_plan POST "/organizations/teams/${CURSOR_TEAM_ID}/grok-bot/operations" "${body}"
    return 0
  fi
  gb_post org "/organizations/teams/${CURSOR_TEAM_ID}/grok-bot/operations" "${body}"
  if [ "${GB_CODE}" = "409" ]; then
    echo "PRECONDITION: another computer operation is running for this team: $(jq -r '.runningOperationId // "unknown (run: status)"' "${GB_BODY_FILE}")" >&2
    exit 2
  fi
  if [ "${GB_CODE}" = "400" ]; then
    echo "PRECONDITION: POST .../grok-bot/operations returned 400 ($(jq -r '(.message // .error // "no message") | tostring' "${GB_BODY_FILE}" | head -c 300)) — NOTHING STARTED, no computer was terminated." >&2
    echo "  Documented causes: a listed member is no longer a current member of the team (for example removed by SCIM or the dashboard after the list was read) or never signed in to Cursor, or the body is malformed or too large (TRAP 3)." >&2
    echo "  Remedies: re-run (the member list is re-read every run); narrow with HTH_CONTAIN_EMAILS; or use Grok Bot Computers > Manage > select members > Terminate VMs in the dashboard." >&2
    if [ "${DO_DISABLE}" -eq 1 ]; then
      echo "  The disable already landed, but running computers have NOT been stopped (TRAP 1)." >&2
    fi
    exit 2
  fi
  gb_require "POST /organizations/teams/${CURSOR_TEAM_ID}/grok-bot/operations" 202
  op=$(jq -r '.operationId // empty' "${GB_BODY_FILE}")
  if [ -z "${op}" ]; then echo "PRECONDITION: 202 without an operationId" >&2; exit 2; fi

  # TRAP 5: a reused operationId returns whatever operation already holds it.
  # Check the action before following it, so a responder never waits on the wrong one.
  gb_get org "/organizations/teams/${CURSOR_TEAM_ID}/grok-bot/operations/${op}?limit=1"
  gb_require "GET /organizations/teams/${CURSOR_TEAM_ID}/grok-bot/operations/${op}" 200
  if [ "$(jq -r '.action // ""' "${GB_BODY_FILE}")" != "terminate_vm" ]; then
    echo "PRECONDITION: operationId ${op} is an existing $(jq -r '.action // "unknown"' "${GB_BODY_FILE}") operation, not this terminate (Cursor returns 202 for an existing operationId without comparing the body) — unset HTH_CONTAIN_OPERATION_ID and re-run" >&2
    exit 2
  fi
  echo "  terminate_vm queued for ${n} member(s): operationId=${op} (re-run with HTH_CONTAIN_OPERATION_ID=${op} to resume)"

  opfile="$(gb_tmp operation)"
  gb_poll_operation "${op}" "${opfile}" HTH_CONTAIN_OPERATION_ID
  # The operation must cover exactly the members requested (TRAP 5).
  if jq -e '.items != null' "${opfile}" >/dev/null; then
    got=$(jq -c '[.items[].userId] | unique' "${opfile}")
    if [ "${got}" != "$(jq -c 'sort' <<<"${ids}")" ]; then
      echo "PRECONDITION: operation ${op} covers userIds ${got}, not the requested ${ids}" >&2
      exit 2
    fi
  elif [ "$(jq -r '.counts.total // -1' "${opfile}")" != "${n}" ]; then
    echo "PRECONDITION: operation ${op} has counts.total=$(jq -r '.counts.total // "?"' "${opfile}") but ${n} members were requested" >&2
    exit 2
  fi
  jq -r '(.items // [])[] | select(.state != "succeeded") | "    userId=\(.userId) \(.state) \(.reason // "")"' "${opfile}"
  failed=$(jq -r '.counts.failed // 0' "${opfile}")
  if [ "${failed}" -gt 0 ]; then
    gb_fail "${failed} member computer(s) were not terminated — start a new operation for them"
  fi
  echo "  terminated: state=$(jq -r '.state' "${opfile}") counts=$(jq -c '.counts' "${opfile}") (audit: grok_bot_vm_bulk bulk_kill)"
}
# HTH Guide Excerpt: end contain-terminate-computers

if [ "${DO_STATUS}" -eq 1 ]; then status; fi
if [ "${DO_DISABLE}" -eq 1 ] || [ "${DO_TERMINATE}" -eq 1 ]; then
  if [ "${GB_APPLY}" -ne 1 ]; then echo "DRY RUN — nothing below is sent without --apply."; fi
fi
if [ "${DO_TERMINATE}" -eq 1 ]; then gb_require_team_id; fi
# Disable acts on the Team key's team, terminate on CURSOR_TEAM_ID: prove they
# are the same team before either write (common.sh TRAP B).
if [ "${DO_DISABLE}" -eq 1 ] && [ "${DO_TERMINATE}" -eq 1 ]; then
  gb_require_key org
  gb_require_team_key_matches
fi
if [ "${DO_DISABLE}" -eq 1 ]; then disable_team; fi
if [ "${DO_TERMINATE}" -eq 1 ]; then terminate_computers; fi
echo "Next: have each affected routine's creator pause or delete it, then confirm via grok_bot_routine disable/delete audit rows (no admin API — TRAP 4)."
exit 0
