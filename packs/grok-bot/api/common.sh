#!/usr/bin/env bash
# HTH Grok Bot Packs — shared helpers for packs/grok-bot/api/hth-grok-bot-*.sh
# Structural file (not a pack). Every pack in this directory sources it; it does
# nothing when run on its own.
#
# Grok Bot is a SpaceXAI product that runs in Cursor's cloud on Cursor accounts,
# so every admin handle these packs use is on CURSOR's API, not xAI's. Sources
# (fetched 2026-10-08, re-checked 2026-10-09):
#   https://cursor.com/docs/api                                   (auth, key types, rate limits)
#   https://cursor.com/docs/account/teams/admin-api#grok-bot      (17 Grok Bot routes, error table)
#   https://cursor.com/docs/account/teams/admin-api#get-audit-logs
#   https://cursor.com/docs/account/teams/admin-api#get-model-access-configuration
#   https://cursor.com/docs/account/organizations/organization-admin-api#list-organization-members
#   https://cursor.com/docs/account/organizations/organization-admin-api#get-audit-logs
#   https://cursor.com/docs/account/organizations/organization-admin-api#grok-bot-computers
#   https://cursor.com/docs/enterprise/compliance-and-monitoring  (audit event types and fields)
#
# TRAPS SHARED BY EVERY PACK (each pack adds its own)
#
# ── TRAP A: the Admin API is Basic auth, not Bearer ──────────────────────────
# Verbatim from the API overview: "The Admin, Analytics, AI Code Tracking, and
# Bugbot APIs accept Basic Authentication. The Cloud Agents API accepts Basic or
# Bearer authentication." The key is the username and the password is empty.
# Bearer is documented for the Cloud Agents API only, so it is not used here.
# The key reaches curl as a config line on stdin (`-K -`): it is never a command
# line argument, never part of a URL, and never echoed.
#
# ── TRAP B: two key types, never interchangeable ─────────────────────────────
# "Organization endpoints require Organization API keys. Team endpoints require
# Team API keys." CURSOR_ADMIN_API_KEY is the Team API key (/teams/*, /grok-bot/*).
# CURSOR_ORG_API_KEY is the Organization API key (/organizations/*). Grok Bot
# computer operations "accept only admin:*" on the Organization key. Team routes
# take no team id: a Team key acts on the one team it belongs to, so a pack that
# also names CURSOR_TEAM_ID for the Organization API proves the two agree first
# (gb_require_team_key_matches).
#
# ── TRAP C: 401 and 403 mean "not available to this team/plan" ──────────────
# The Grok Bot error table: 401 = "Bad key, missing read:* / admin:*, or Grok Bot
# Admin API not enabled for the team"; 403 = "The write is not available to the
# team or its plan". A write with a read:* key also returns 401. A refused READ
# is not evidence about the control, so it exits 2 (precondition). A refused
# request during `enforce`, after verify has already recorded a finding, exits
# 1 instead: the finding stands, and only the remedy was refused (gb_require
# reads GB_PHASE). After a write (the re-verify phase) a refusal is exit 2 again,
# because nothing has been judged yet.
#
# ── TRAP D: Teams-plan reach is contradictory in Cursor's own docs ───────────
# cursor.com/docs/api lists the Admin API's availability as "Enterprise teams".
# The Grok Bot section says GET /grok-bot/access, /network and /auto-review
# "return the effective policy on every plan", and documents "Returns 403 on
# Teams plans" for disable and the network PUT. Nothing documents
# /grok-bot/capabilities on Teams. The packs behave identically on both plans and
# let TRAP C's classification report what the tenant actually allows.
#
# ── TRAP E: scope wording differs between two pages ──────────────────────────
# The API overview says the Admin API key's "Required scope: admin:*". The Grok
# Bot section says "Reads require read:* or admin:*. Writes require admin:*." The
# packs follow the Grok Bot section for /grok-bot/* routes: a read:* key is
# enough to verify those. Other team routes (/teams/audit-logs, /teams/groups,
# /teams/members) fall under the overview's admin:*.
#
# ── TRAP F: rate limits ──────────────────────────────────────────────────────
# Grok Bot routes: "20 requests per minute per team per endpoint", 429 with
# "Retry-After: 60". Organization API routes are limited per ORGANIZATION: the
# audit feed and starting a computer operation allow 20 per minute, and "Each
# status route allows 120 requests per minute per organization". On a 429 these
# helpers wait the documented 60 seconds once, then stop.
#
# ── TRAP G: a 200 is not proof of data ───────────────────────────────────────
# A proxy, captive portal or API change can answer 200 with another body. Every
# pack checks the documented response shape before judging anything (gb_shape),
# and every cursor-paged loop stops on a page cap or a repeated cursor.
#
# ── TRAP H: most write routes document a body but no status code ────────────
# Status codes are stated for enable/disable (204), team-rule create (201),
# deletes (204) and computer-operation start (202). The PATCH/PUT routes show a
# response body only. Those writes accept any 2xx (gb_require_2xx), and every
# enforce run re-reads state with a fresh GET before it reports success.
#
# ── TRAP I: exit 0 is "no finding the API can see", not always "compliant" ───
# Several controls are partly invisible to every API (group Grok Bot tabs, Team
# Secrets, the OpenTelemetry destination, anything changed before an audit
# window). A pack that cannot see part of its control sets GB_UNPROVEN, and
# gb_exit then prints "RESULT: no finding in what the API can read; NOT proven:
# …" instead of "RESULT: compliant". The exit code stays 0, because such a pack
# could otherwise never pass, but the result line never overclaims.
#
# Exit codes for the verify/enforce packs (everything that runs gb_main):
#   0 no finding in what the API can read ("compliant" only when GB_UNPROVEN is
#     empty) | 1 finding, failed action, a dry run that would change something,
#     or a request refused during enforce after a finding (TRAP C) |
#   2 precondition (nothing was judged)
# The 7.01 and 7.02 packs are runbook ACTIONS, not checks: their dry runs exit 0,
# and their own headers give their codes.

set -euo pipefail

CURSOR_API_BASE="${CURSOR_API_BASE:-https://api.cursor.com}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

GB_TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/hth-grok-bot.XXXXXX")"
trap 'rm -rf "${GB_TMP_DIR}"' EXIT
GB_BODY_FILE="${GB_TMP_DIR}/body.json"
GB_CODE=""
GB_KIND=""
GB_MODE="verify"
GB_APPLY=0
GB_FINDINGS=0
GB_PHASE="verify"   # verify | enforce | reverify — decides how a refused request exits (TRAP C)
GB_UNPROVEN=""      # what the API cannot see for this control (TRAP I); set by a pack

gb_tmp() { mktemp "${GB_TMP_DIR}/$1.XXXXXX"; }

# ── Keys ─────────────────────────────────────────────────────────────────────
gb_require_key() { # gb_require_key team|org
  case "$1" in
    team)
      if [ -z "${CURSOR_ADMIN_API_KEY:-}" ]; then
        echo "PRECONDITION: set CURSOR_ADMIN_API_KEY — a Cursor Team API key (cursor.com/dashboard > API Keys); read:* verifies /grok-bot/* routes, admin:* is needed to enforce and for /teams/* routes (TRAP E)" >&2
        exit 2
      fi ;;
    org)
      if [ -z "${CURSOR_ORG_API_KEY:-}" ]; then
        echo "PRECONDITION: set CURSOR_ORG_API_KEY — a Cursor Organization API key (admin:* for Grok Bot computer operations; auditlogs:read or admin:* for the organization audit feed; members:read or admin:* to list members)" >&2
        exit 2
      fi ;;
    *) echo "PRECONDITION: unknown key kind '$1'" >&2; exit 2 ;;
  esac
}

gb_require_team_id() {
  case "${CURSOR_TEAM_ID:-}" in
    ''|*[!0-9]*)
      echo "PRECONDITION: set CURSOR_TEAM_ID to the team's integer id (GET /organizations/members lists it as teams[].teamId)" >&2
      exit 2 ;;
  esac
}

# ── HTTP ─────────────────────────────────────────────────────────────────────
# _gb_send <team|org> <path> [curl args...]
# Sets GB_CODE (000 when no HTTP response arrived) and leaves the body in
# GB_BODY_FILE. The key is piped to curl as a config line (TRAP A).
_gb_send() {
  local kind="$1" path="$2" key rc attempt=0
  shift 2
  gb_require_key "${kind}"
  GB_KIND="${kind}"
  if [ "${kind}" = "team" ]; then key="${CURSOR_ADMIN_API_KEY}"; else key="${CURSOR_ORG_API_KEY}"; fi
  while :; do
    : > "${GB_BODY_FILE}"
    set +e
    GB_CODE=$(printf 'user = "%s:"\n' "${key}" \
      | curl -sS -K - -o "${GB_BODY_FILE}" -w '%{http_code}' "$@" "${CURSOR_API_BASE}${path}" 2>/dev/null)
    rc=$?
    set -e
    if [ "${rc}" -ne 0 ]; then GB_CODE="000"; fi
    if [ "${GB_CODE}" = "429" ] && [ "${attempt}" -lt 1 ]; then
      attempt=$((attempt + 1))
      echo "  (HTTP 429 on ${path}: waiting the documented Retry-After of 60 s, once)" >&2
      sleep 60
      continue
    fi
    break
  done
}

# Reads.
gb_get() { _gb_send "$1" "$2"; }

# Writes. Each helper spells its HTTP verb literally, so scripts/validate-packs.sh
# check 14 sees that any pack calling one of them mutates.
gb_put()    { _gb_send "$1" "$2" -X PUT   -H "Content-Type: application/json" --data-binary "$3"; }
gb_patch()  { _gb_send "$1" "$2" -X PATCH -H "Content-Type: application/json" --data-binary "$3"; }
gb_delete() { _gb_send "$1" "$2" -X DELETE; }
gb_post() {
  if [ -n "${3:-}" ]; then
    _gb_send "$1" "$2" -X POST -H "Content-Type: application/json" --data-binary "$3"
  else
    _gb_send "$1" "$2" -X POST
  fi
}

# gb_require "<METHOD path>" <acceptable HTTP codes...>
# Returns when GB_CODE is acceptable. Otherwise explains the status for the
# route that was called (TRAP C, E, F) and exits: 2 (precondition) normally, 1
# when this is the enforce phase and verify already found something.
gb_require() {
  local label="$1" c msg path hint="" tag="PRECONDITION"
  shift
  for c in "$@"; do
    if [ "${GB_CODE}" = "${c}" ]; then return 0; fi
  done
  msg=$(jq -r '(.message // .error // empty) | tostring' "${GB_BODY_FILE}" 2>/dev/null | head -c 300 || true)
  path="${label#* }"   # "<METHOD> <path>" -> "<path>"; labels without a method keep their text
  if [ "${GB_PHASE}" = "enforce" ] && [ "${GB_FINDINGS}" -gt 0 ]; then tag="FAILED"; fi
  case "${GB_KIND}:${GB_CODE}" in
    *:000)
      hint="no HTTP response (network, DNS or TLS failure)" ;;
    team:401)
      case "${path}" in
        /grok-bot/*) hint="bad key, a key without read:* (reads) or admin:* (writes), or the Grok Bot Admin API is not enabled for this team. Not available to this team/plan." ;;
        *)           hint="bad key or the wrong scope: the API overview gives the Admin API's required scope as admin:*, and read:* is documented only for /grok-bot/* reads." ;;
      esac ;;
    team:403)
      case "${path}" in
        /grok-bot/*) hint="not available to this team or its plan (several Grok Bot writes are Enterprise only)." ;;
        *)           hint="not available to this team or its plan (audit logs and remove-member are Enterprise only)." ;;
      esac ;;
    org:401)
      case "${path}" in
        */grok-bot/*)                hint="invalid Organization key, or the wrong scope: computer operations accept only admin:*." ;;
        /organizations/audit-logs*)  hint="invalid Organization key, or the wrong scope: the audit feed needs auditlogs:read or admin:*." ;;
        /organizations/members*)     hint="invalid Organization key, or the wrong scope: listing members needs members:read, members:* or admin:*." ;;
        *)                           hint="invalid Organization key, or the wrong scope." ;;
      esac ;;
    org:403)
      case "${path}" in
        */grok-bot/*)                hint="Grok Bot computer operations are not turned on for this team (the account team enables them per team)." ;;
        /organizations/audit-logs*)  hint="the teamId is not linked to this organization, or the key's scope does not cover the audit feed." ;;
        *)                           hint="the key's scope does not cover this route." ;;
      esac ;;
    org:404)
      case "${path}" in
        */grok-bot/*) hint="the team is not linked to this organization, or the operation does not exist or is no longer available." ;;
      esac ;;
    *:409)
      hint="the resource changed during the request, or another operation is running. Re-run." ;;
    *:429)
      case "${GB_KIND}:${path}" in
        org:*/grok-bot/operations/*) hint="rate limited after one 60 s wait (each status route allows 120 requests/minute per organization)." ;;
        org:*)                       hint="rate limited after one 60 s wait (Organization API limits are per organization, for example 20 requests/minute)." ;;
        *)                           hint="rate limited after one 60 s wait (20 requests/minute per team per endpoint)." ;;
      esac ;;
    *:503)
      hint="temporarily unavailable; retry the same request." ;;
  esac
  echo "${tag}: ${label} returned HTTP ${GB_CODE}${msg:+ (${msg})}${hint:+ — ${hint}}" >&2
  if [ "${tag}" = "FAILED" ]; then
    echo "FAILED: enforcement did not complete — verify found ${GB_FINDINGS} finding(s) before this request; re-run verify to read the current state" >&2
    exit 1
  fi
  exit 2
}

# gb_require_2xx "<METHOD path>" — for writes whose success status the docs do
# not state (TRAP H). Any 2xx passes; everything else is classified as above.
gb_require_2xx() {
  case "${GB_CODE}" in
    2??) return 0 ;;
  esac
  gb_require "$1"
}

# gb_shape '<jq boolean over the body>' '<label>' — TRAP G.
gb_shape() {
  if ! jq -e "$1" "${GB_BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: $2 returned HTTP ${GB_CODE} without the documented response shape — nothing was judged" >&2
    exit 2
  fi
}

# ── Results and modes ────────────────────────────────────────────────────────
gb_finding() { echo "FINDING: $*"; GB_FINDINGS=$((GB_FINDINGS + 1)); }
gb_fail()    { echo "FAILED: $*"; exit 1; }

gb_plan() { # gb_plan <METHOD> <path> [json-body] — what --apply would send
  echo "  DRY RUN — would send: $1 ${CURSOR_API_BASE}$2"
  if [ -n "${3:-}" ]; then
    printf '%s\n' "$3" | jq . | sed 's/^/    /'
  fi
}

gb_parse_mode() { # accepts: [verify | enforce [--apply]]
  local a
  for a in "$@"; do
    case "${a}" in
      verify|enforce) GB_MODE="${a}" ;;
      --apply) GB_APPLY=1 ;;
      *) echo "PRECONDITION: unknown argument '${a}' (expected: verify | enforce [--apply])" >&2; exit 2 ;;
    esac
  done
  if [ "${GB_APPLY}" -eq 1 ] && [ "${GB_MODE}" != "enforce" ]; then
    echo "PRECONDITION: --apply is only meaningful with 'enforce'" >&2
    exit 2
  fi
}

gb_parse_readonly() { # read-only packs accept only [verify]
  local a
  for a in "$@"; do
    case "${a}" in
      verify) ;;
      *) echo "PRECONDITION: this pack is read-only; unknown argument '${a}'" >&2; exit 2 ;;
    esac
  done
}

gb_exit() {
  if [ "${GB_FINDINGS}" -gt 0 ]; then
    echo "RESULT: ${GB_FINDINGS} finding(s)"
    exit 1
  fi
  if [ -n "${GB_UNPROVEN}" ]; then
    echo "RESULT: no finding in what the API can read; NOT proven: ${GB_UNPROVEN}"
    exit 0
  fi
  echo "RESULT: compliant"
  exit 0
}

# gb_main <verify-fn> [enforce-fn]
# verify always runs first and is the only judge. enforce runs only when verify
# found something, writes only with --apply, and is followed by a fresh verify,
# so a write is never reported as success on the strength of its own response.
gb_main() {
  local verify_fn="$1" enforce_fn="${2:-}"
  GB_FINDINGS=0
  GB_PHASE="verify"
  "${verify_fn}"
  if [ "${GB_MODE}" = "verify" ] || [ -z "${enforce_fn}" ]; then gb_exit; fi
  if [ "${GB_FINDINGS}" -eq 0 ]; then
    if [ -n "${GB_UNPROVEN}" ]; then
      echo "ENFORCE: no API-visible finding — nothing to change. NOT proven: ${GB_UNPROVEN}"
    else
      echo "ENFORCE: already compliant — nothing to change."
    fi
    exit 0
  fi
  GB_PHASE="enforce"
  if [ "${GB_APPLY}" -ne 1 ]; then
    echo "ENFORCE (dry run): nothing below is sent without --apply."
    "${enforce_fn}"
    echo "RESULT: still non-compliant (dry run)"
    exit 1
  fi
  echo "ENFORCE (--apply):"
  "${enforce_fn}"
  echo "RE-VERIFY after apply:"
  GB_PHASE="reverify"
  GB_FINDINGS=0
  "${verify_fn}"
  gb_exit
}

# ── Shared reads ─────────────────────────────────────────────────────────────
# GET /grok-bot/capabilities into GB_TMP_DIR/capabilities.json. Only the object
# type is checked here; each pack checks the one field it judges, because the
# doc marks some fields (localEgressAllowed) Enterprise only.
gb_read_capabilities() {
  gb_get team /grok-bot/capabilities
  gb_require "GET /grok-bot/capabilities" 200
  gb_shape 'type == "object"' "GET /grok-bot/capabilities"
  cp "${GB_BODY_FILE}" "${GB_TMP_DIR}/capabilities.json"
}

# gb_lookback_days <default> — validated HTH_LOOKBACK_DAYS. Read as base 10, so
# "08" is 8 days and "00" is refused rather than silently judging zero days.
gb_lookback_days() {
  local d="${HTH_LOOKBACK_DAYS:-$1}"
  case "${d}" in
    ''|*[!0-9]*) echo "PRECONDITION: HTH_LOOKBACK_DAYS must be a whole number of days >= 1" >&2; exit 2 ;;
  esac
  d=$((10#${d}))
  if [ "${d}" -lt 1 ]; then
    echo "PRECONDITION: HTH_LOOKBACK_DAYS must be a whole number of days >= 1" >&2
    exit 2
  fi
  printf '%s' "${d}"
}

# gb_audit_pull <comma-separated event_types> <days back> <out.jsonl>
# Audit logs are an Enterprise feature. A request may span at most 30 days and
# returns at most 500 events per page, oldest first; "Page through longer
# periods with consecutive windows." This walks 30-day windows back from now
# (Unix-second startTime/endTime, a documented format), follows
# pagination.hasNextPage, and writes one event per line, de-duplicated on
# event_id because consecutive windows share a boundary second.
# HTH_AUDIT_SCOPE=team (default): Team key, GET /teams/audit-logs.
# HTH_AUDIT_SCOPE=org: Organization key, GET /organizations/audit-logs, narrowed
# to CURSOR_TEAM_ID (validated as an integer) when that is set.
gb_audit_pull() {
  local types="$1" days="$2" out="$3" kind path now floor end start page q raw
  case "${HTH_AUDIT_SCOPE:-team}" in
    team) kind="team"; path="/teams/audit-logs" ;;
    org)  kind="org";  path="/organizations/audit-logs" ;;
    *) echo "PRECONDITION: HTH_AUDIT_SCOPE must be team or org" >&2; exit 2 ;;
  esac
  if [ "${kind}" = "org" ] && [ -n "${CURSOR_TEAM_ID:-}" ]; then gb_require_team_id; fi
  raw="$(gb_tmp audit-raw)"
  now=$(date -u +%s)
  floor=$((now - days * 86400))
  end="${now}"
  while [ "${end}" -gt "${floor}" ]; do
    start=$((end - 30 * 86400))
    if [ "${start}" -lt "${floor}" ]; then start="${floor}"; fi
    page=1
    while :; do
      q="startTime=${start}&endTime=${end}&eventTypes=${types}&pageSize=500&page=${page}"
      if [ "${kind}" = "org" ] && [ -n "${CURSOR_TEAM_ID:-}" ]; then q="${q}&teamId=${CURSOR_TEAM_ID}"; fi
      gb_get "${kind}" "${path}?${q}"
      gb_require "GET ${path}" 200
      gb_shape '(.events | type == "array") and (.pagination.hasNextPage | type == "boolean")' "GET ${path} (page ${page})"
      jq -c '.events[]' "${GB_BODY_FILE}" >> "${raw}"
      if [ "$(jq -r '.pagination.hasNextPage' "${GB_BODY_FILE}")" != "true" ]; then break; fi
      page=$((page + 1))
      if [ "${page}" -gt 200 ]; then
        echo "PRECONDITION: more than 200 pages in one 30-day window — narrow the event types or the lookback" >&2
        exit 2
      fi
    done
    end="${start}"
  done
  jq -s -c 'unique_by(.event_id) | sort_by(.timestamp) | .[]' "${raw}" > "${out}"
}

# gb_org_members <out.jsonl> — every member of CURSOR_TEAM_ID as {id, email}.
# GET /organizations/members?teamId= returns NUMERIC ids, the only ids the
# computer-operation routes accept (pageSize is capped at 200). A team that is
# not linked to the organization returns an empty page.
gb_org_members() {
  local out="$1" page=1
  gb_require_team_id
  : > "${out}"
  while :; do
    gb_get org "/organizations/members?teamId=${CURSOR_TEAM_ID}&page=${page}&pageSize=200"
    gb_require "GET /organizations/members" 200
    gb_shape '(.members | type == "array")
              and all(.members[]; (.id | type == "number") and (.email | type == "string"))
              and (.pagination.hasNextPage | type == "boolean")' "GET /organizations/members (page ${page})"
    jq -c '.members[] | {id, email}' "${GB_BODY_FILE}" >> "${out}"
    if [ "$(jq -r '.pagination.hasNextPage' "${GB_BODY_FILE}")" != "true" ]; then break; fi
    page=$((page + 1))
    if [ "${page}" -gt 500 ]; then
      echo "PRECONDITION: more than 500 pages of organization members" >&2
      exit 2
    fi
  done
}

# gb_require_team_key_matches — prove CURSOR_ADMIN_API_KEY (a Team key) belongs
# to CURSOR_TEAM_ID before a pack acts on "one" team through both APIs (TRAP B).
# First choice: GET /teams/model-access/configuration returns `teamId`, the
# "Integer team ID implied by the API key" (models:read or admin:*; the route is
# documented for "Teams with model access control enabled"). Where it is not
# readable, the Team key's active members must equal the Organization API's
# members of CURSOR_TEAM_ID. Anything else stops with exit 2.
gb_require_team_key_matches() {
  local key_team cfg_code members team_emails org_emails
  gb_require_team_id
  gb_get team /teams/model-access/configuration
  cfg_code="${GB_CODE}"
  if [ "${cfg_code}" = "200" ] && jq -e '.teamId | type == "number"' "${GB_BODY_FILE}" >/dev/null 2>&1; then
    key_team=$(jq -r '.teamId' "${GB_BODY_FILE}")
    if [ "${key_team}" != "${CURSOR_TEAM_ID}" ]; then
      echo "PRECONDITION: CURSOR_ADMIN_API_KEY belongs to team ${key_team}, not CURSOR_TEAM_ID ${CURSOR_TEAM_ID} — its team routes would act on the wrong team" >&2
      exit 2
    fi
    echo "  Team key belongs to team ${key_team} (GET /teams/model-access/configuration)"
    return 0
  fi
  gb_get team /teams/members
  gb_require "GET /teams/members" 200
  gb_shape '(.teamMembers | type == "array")
            and all(.teamMembers[]; (.email | type == "string") and (.isRemoved | type == "boolean"))' "GET /teams/members"
  team_emails=$(jq -c '[.teamMembers[] | select(.isRemoved == false) | .email | ascii_downcase] | unique' "${GB_BODY_FILE}")
  members="$(gb_tmp keycheck)"
  gb_org_members "${members}"
  org_emails=$(jq -s -c '[.[].email | ascii_downcase] | unique' "${members}")
  if [ "${team_emails}" = "[]" ] || [ "${team_emails}" != "${org_emails}" ]; then
    echo "PRECONDITION: cannot prove CURSOR_ADMIN_API_KEY belongs to team ${CURSOR_TEAM_ID}: GET /teams/model-access/configuration returned HTTP ${cfg_code} without a teamId, and the Team key's active members differ from the Organization API's members of team ${CURSOR_TEAM_ID}" >&2
    exit 2
  fi
  echo "  Team key's active members match team ${CURSOR_TEAM_ID} (model-access configuration not readable: HTTP ${cfg_code})"
}

# gb_uuid <resume-variable-name> — operationId for a computer operation. The API
# wants a caller UUID and returns it lowercase. The named variable
# (HTH_OFFBOARD_OPERATION_ID or HTH_CONTAIN_OPERATION_ID) re-sends a known id to
# resume THAT pack's own operation. Cursor "doesn't compare the rest of the body
# on a retry", so each pack has its own variable and checks the action it gets
# back (see gb_poll_operation's callers).
gb_uuid() {
  local var="$1" given u=""
  given="${!var:-}"
  if [ -n "${given}" ]; then
    u="${given}"
  elif command -v uuidgen >/dev/null 2>&1; then
    u="$(uuidgen)"
  elif [ -r /proc/sys/kernel/random/uuid ]; then
    u="$(cat /proc/sys/kernel/random/uuid)"
  fi
  u="$(printf '%s' "${u}" | tr '[:upper:]' '[:lower:]')"
  if ! printf '%s' "${u}" | grep -Eq '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'; then
    if [ -n "${given}" ]; then
      echo "PRECONDITION: ${var} is not a UUID" >&2
    else
      echo "PRECONDITION: could not generate a UUID operationId (no uuidgen) — set ${var}" >&2
    fi
    exit 2
  fi
  printf '%s' "${u}"
}

# gb_poll_operation <operationId> <out.json> <resume-variable-name>
# GET /organizations/teams/:teamId/grok-bot/operations/:operationId until state
# is no longer `running` (status routes allow 120 requests/minute). Writes the
# final status with every page of per-member items merged into .items.
# items is null for operations of more than 1,000 members (counts only). The
# caller checks .action and the member set: a reused operationId returns
# whatever operation already holds it.
gb_poll_operation() {
  local op="$1" out="$2" resume="${3:-the resume variable}" waited=0 interval="${HTH_POLL_SECONDS:-10}" limit="${HTH_POLL_TIMEOUT:-1800}" state cursor next items pages=0
  case "${interval}${limit}" in *[!0-9]*) echo "PRECONDITION: HTH_POLL_SECONDS and HTH_POLL_TIMEOUT must be whole numbers" >&2; exit 2 ;; esac
  # The id goes into a URL path: accept only the UUID shape the API documents.
  if ! printf '%s' "${op}" | grep -Eq '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'; then
    echo "PRECONDITION: operationId '${op}' is not a lowercase UUID" >&2
    exit 2
  fi
  while :; do
    gb_get org "/organizations/teams/${CURSOR_TEAM_ID}/grok-bot/operations/${op}?limit=1000"
    gb_require "GET /organizations/teams/${CURSOR_TEAM_ID}/grok-bot/operations/${op}" 200
    gb_shape '(.state | IN("running","succeeded","partially_succeeded","failed")) and (.counts | type == "object")' "GET operation ${op}"
    state=$(jq -r '.state' "${GB_BODY_FILE}")
    echo "  operation ${op}: action=$(jq -r '.action // "?"' "${GB_BODY_FILE}") state=${state} counts=$(jq -c '.counts' "${GB_BODY_FILE}")"
    if [ "${state}" != "running" ]; then break; fi
    if [ "${waited}" -ge "${limit}" ]; then
      echo "PRECONDITION: operation ${op} still running after ${limit}s — re-run with ${resume}=${op} to keep following it" >&2
      exit 2
    fi
    sleep "${interval}"
    waited=$((waited + interval))
  done
  cp "${GB_BODY_FILE}" "${out}"
  items="$(gb_tmp items)"
  jq -c '.items // [] | .[]' "${out}" > "${items}"
  cursor=$(jq -r '.nextCursor // ""' "${out}")
  while [ -n "${cursor}" ]; do
    pages=$((pages + 1))
    if [ "${pages}" -gt 100 ]; then
      echo "PRECONDITION: more than 100 item pages for operation ${op}" >&2
      exit 2
    fi
    gb_get org "/organizations/teams/${CURSOR_TEAM_ID}/grok-bot/operations/${op}?limit=1000&cursor=$(jq -rn --arg c "${cursor}" '$c|@uri')"
    gb_require "GET operation ${op} (items page)" 200
    gb_shape '(.items | type == "array")' "GET operation ${op} (items page ${pages})"
    jq -c '.items[]' "${GB_BODY_FILE}" >> "${items}"
    next=$(jq -r '.nextCursor // ""' "${GB_BODY_FILE}")
    if [ -n "${next}" ] && [ "${next}" = "${cursor}" ]; then
      echo "PRECONDITION: operation ${op}: the API returned the same nextCursor twice" >&2
      exit 2
    fi
    cursor="${next}"
  done
  jq --slurpfile it "${items}" 'if .items == null then . else .items = $it end' "${out}" > "${out}.merged"
  mv "${out}.merged" "${out}"
}
