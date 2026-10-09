#!/usr/bin/env bash
# HTH ChatGPT Dots — shared READ helpers for the ChatGPT Admin API
# Sourced by every packs/chatgpt-dots/api/hth-chatgpt-dots-*.sh pack.
#
# This is a structural file, not a pack. It deliberately holds NO write helper:
# every POST/DELETE is spelled out with a literal `-X` verb inside the pack that
# performs it, so that pack's own `mode:` line and scripts/validate-packs.sh
# check 14 both see the write, and a read-only pack can never reach one.
#
# Transcribed from (fetched 2026-10-08):
#   https://chatgpt.com/public/admin/api-reference
#     OpenAPI "OpenAI Programmatic Admin Platform" v2.5.37, base https://api.chatgpt.com/v1.
#     The live host answers fetchers with a 403 challenge; the spec was read in a
#     real browser this session (sha256 4fecb1a1…4647c12 of openapi.json).
#   https://developers.openai.com/downloads/compliance-api/download_compliance_files.sh
#     OpenAI's own List Files / Download File client (pagination on last_end_time).
#
# Authentication, verbatim from the spec's Introduction: "Workspace owners and
# workspace admins can create workspace-scoped Admin keys in the OpenAI Admin
# Console under Credentials > Admin keys. ... use Custom permissions whenever
# possible ... send requests with Authorization: Bearer <admin_api_key>. Use
# https://api.chatgpt.com/v1/ as the base URL for all endpoints."
#
# Plan boundary: the Introduction scopes the API to "ChatGPT Enterprise
# administrators", and learn.chatgpt.com/docs/pricing lists "Compliance API and
# audit logs" as unavailable on Business. Business Premium and Pro dots have no
# Admin API at all, so a 403/404 on those plans is a plan fact, not a finding.
#
# Environment:
#   CHATGPT_ADMIN_KEY     workspace-scoped Admin key (required)
#   CHATGPT_WORKSPACE_ID  ChatGPT workspace ID, a UUID (required)
#   CHATGPT_ADMIN_BASE    override of https://api.chatgpt.com/v1 (optional)
#
# Exit-code contract every pack in this directory follows:
#   0 ran / pass | 1 finding | 2 precondition (env, auth, scope, plan, transport,
#   or a 200 whose body lacks the documented shape — nothing was evaluated)

set -euo pipefail

CHATGPT_ADMIN_BASE="${CHATGPT_ADMIN_BASE:-https://api.chatgpt.com/v1}"

# Files written here (and the caller's own outputs) can hold conversation content
# and member emails, so nothing this process creates is group/world readable.
umask 077

CGPT_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/hth-chatgpt-dots.XXXXXX")"
trap 'rm -rf "${CGPT_TMPDIR}"' EXIT
CGPT_BODY="${CGPT_TMPDIR}/body"
CGPT_HDRS="${CGPT_TMPDIR}/headers"
CGPT_CODE=""
CGPT_SCOPE_HINT="${CGPT_SCOPE_HINT:-}"

cgpt_die()  { echo "PRECONDITION: $*" >&2; exit 2; }
cgpt_info() { echo "[INFO]  $*" >&2; }
cgpt_warn() { echo "[WARN]  $*" >&2; }

cgpt_require_tools() {
  command -v curl >/dev/null 2>&1 || cgpt_die "curl not found"
  command -v jq   >/dev/null 2>&1 || cgpt_die "jq not found"
}

cgpt_require() {
  cgpt_require_tools
  [ -n "${CHATGPT_ADMIN_KEY:-}" ] \
    || cgpt_die "set CHATGPT_ADMIN_KEY — a workspace-scoped Admin key (OpenAI Admin Console > Credentials > Admin keys)"
  [ -n "${CHATGPT_WORKSPACE_ID:-}" ] || cgpt_die "set CHATGPT_WORKSPACE_ID — the ChatGPT workspace ID"
  # The spec types workspace_id as `format: uuid` on every route used here.
  [[ "${CHATGPT_WORKSPACE_ID}" =~ ^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$ ]] \
    || cgpt_die "CHATGPT_WORKSPACE_ID must be a UUID (the spec types workspace_id as format: uuid)"
}

# Any ID spliced into a URL path must be a single path segment. A '/', '?', '#',
# '%' or space in an operator-supplied value could otherwise point a request —
# a DELETE included — at a different route than the one named. So could a value
# made only of dots: curl removes "." and ".." path segments, so ".." would turn
# .../users/../memory/delete_and_disable into the WORKSPACE-wide route. Every
# request in these packs also passes --path-as-is as a second layer.
cgpt_safe_id() {
  [[ "$1" =~ ^[A-Za-z0-9._:-]+$ ]] && [[ ! "$1" =~ ^\.+$ ]] \
    || cgpt_die "refusing unsafe ${2:-ID} '$1' (allowed: letters, digits, . _ : -; not '.' or '..')"
}

# The key reaches curl as a config line on stdin (`-K -`), never as an argv
# value, so it never appears in the process list. printf is a shell builtin.
_cgpt_auth() { printf 'header = "Authorization: Bearer %s"\n' "${CHATGPT_ADMIN_KEY}"; }

# Seconds from a Retry-After header ("Follow Retry-After when provided" — every
# 429 in the spec). Non-numeric (HTTP-date) or absent → 10; capped at 120.
_cgpt_retry_after() {
  local s
  s="$(awk 'tolower($1)=="retry-after:" {gsub("\r",""); v=$2} END {print v}' "${CGPT_HDRS}" 2>/dev/null || true)"
  [[ "${s}" =~ ^[0-9]+$ ]] || s=10
  [ "${s}" -le 120 ] || s=120
  echo "${s}"
}

# Retries taken by the most recent request helper (cgpt_get, clp_download, or a
# pack's own write helper), so a 429 message reports the real count.
CGPT_RETRIES=0
CGPT_GET_RETRIES=5

# cgpt_get <path> [curl -G data args...]
# One GET against the Admin API, retrying a 429 up to CGPT_GET_RETRIES times after
# Retry-After. Sets CGPT_CODE (000 = no HTTP response); the body is in "${CGPT_BODY}".
cgpt_get() {
  local path="$1" attempt=0 rc wait
  shift
  CGPT_RETRIES=0
  while :; do
    set +e
    CGPT_CODE="$(_cgpt_auth | curl -sS -g -G --path-as-is -K - -D "${CGPT_HDRS}" -o "${CGPT_BODY}" \
      -w '%{http_code}' "${CHATGPT_ADMIN_BASE}${path}" "$@" 2>/dev/null)"
    rc=$?
    set -e
    [ "${rc}" -eq 0 ] || CGPT_CODE="000"
    if [ "${CGPT_CODE}" = "429" ] && [ "${attempt}" -lt "${CGPT_GET_RETRIES}" ]; then
      wait="$(_cgpt_retry_after)"
      cgpt_warn "GET ${path}: HTTP 429, retrying in ${wait}s (Retry-After)"
      sleep "${wait}"
      attempt=$((attempt + 1))
      CGPT_RETRIES="${attempt}"
      continue
    fi
    return 0
  done
}

# Names the cause of a non-2xx for <verb> <path>, then exits 2. Response texts
# are the spec's own 401/403/404/429 descriptions.
cgpt_fail_http() {
  local verb="$1" path="$2" snippet
  snippet="$(head -c 400 "${CGPT_BODY}" 2>/dev/null | tr '\n' ' ' || true)"
  case "${CGPT_CODE}" in
    000) cgpt_die "${verb} ${path} — no HTTP response (network, DNS, or TLS failure)" ;;
    401) cgpt_die "${verb} ${path} returned HTTP 401 — missing or invalid admin API key" ;;
    403) cgpt_die "${verb} ${path} returned HTTP 403 — the Admin key lacks the required scope${CGPT_SCOPE_HINT:+ (${CGPT_SCOPE_HINT})} or is not authorized for this workspace" ;;
    404) cgpt_die "${verb} ${path} returned HTTP 404 — workspace/resource not found, or the workspace is not on a plan with the Admin API (Enterprise/Edu only). Body: ${snippet}" ;;
    429) cgpt_die "${verb} ${path} returned HTTP 429 after ${CGPT_RETRIES:-0} retr(y/ies) — rate limited (the spec allows 100 requests per minute per workspace per method and route by default; follow Retry-After)" ;;
    *)   cgpt_die "${verb} ${path} returned HTTP ${CGPT_CODE}. Body: ${snippet}" ;;
  esac
}

# cgpt_get_ok <path> [curl -G data args...] — a GET that must return 200.
cgpt_get_ok() {
  local path="$1"
  shift
  cgpt_get "${path}" "$@"
  [ "${CGPT_CODE}" = "200" ] || cgpt_fail_http GET "${path}"
}

# cgpt_paginate_cursor <path> <outfile>
# For the cursor-paginated lists used here — List Group Users, List User Groups
# (`limit` 1-100, opaque `cursor`, `has_more`) and List Workspace Plugins (same
# names, limit max 100). Writes each `.data[]` item as one JSON line. A 200 that
# is not a list, or `has_more: true` with no cursor, stops the run: a partial
# roster reported as complete is the one failure an audit cannot afford.
cgpt_paginate_cursor() {
  local path="$1" out="$2" cursor="" pages=0 more
  : > "${out}"
  while :; do
    if [ -n "${cursor}" ]; then
      cgpt_get_ok "${path}" --data-urlencode "limit=100" --data-urlencode "cursor=${cursor}"
    else
      cgpt_get_ok "${path}" --data-urlencode "limit=100"
    fi
    jq -e '.data | type == "array"' "${CGPT_BODY}" >/dev/null 2>&1 \
      || cgpt_die "GET ${path} returned HTTP 200 without the documented data[] list — nothing was read"
    jq -c '.data[]' "${CGPT_BODY}" >> "${out}"
    pages=$((pages + 1))
    more="$(jq -r 'if (.has_more | type) == "boolean" then (.has_more | tostring) else "absent" end' "${CGPT_BODY}")"
    if [ "${more}" = "absent" ]; then
      cgpt_warn "GET ${path}: response has no has_more flag — treating page ${pages} as the last; completeness unverified"
      break
    fi
    [ "${more}" = "true" ] || break
    cursor="$(jq -r '.cursor // ""' "${CGPT_BODY}")"
    [ -n "${cursor}" ] || cgpt_die "GET ${path}: has_more is true but no cursor was returned — refusing to report a partial list as complete"
    [ "${pages}" -lt 1000 ] || cgpt_die "GET ${path}: more than 1000 pages — runaway guard"
  done
}

# ── Time helpers (jq only: GNU and BSD date disagree on parsing and arithmetic) ──
hth_now_epoch()     { jq -nr 'now | floor'; }
hth_iso_hours_ago() { jq -nr --argjson h "$1" '(now - ($h * 3600)) | floor | todate'; }
# ISO 8601 → epoch seconds. Accepts Z or +00:00 and fractional seconds; any other
# offset is refused rather than silently misread.
hth_iso_to_epoch() {
  jq -nr --arg t "$1" '$t | sub("\\.[0-9]+"; "") | sub("(\\+00:00|\\+0000)$"; "Z") | fromdateiso8601' 2>/dev/null \
    || cgpt_die "cannot parse timestamp '$1' — use UTC ISO 8601, e.g. 2026-10-08T00:00:00Z"
}

hth_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  else shasum -a 256 "$1" | awk '{print $1}'; fi
}

# ── Compliance Logs Platform (List Files / Download File / Get Freshness) ─────
# List Files: `event_type` (required, repeatable) and `after` (required, "Return
# log files whose end_time is strictly later than this ISO 8601 timestamp");
# optional `before`, `limit` 1-100. "Results are ordered by end_time ascending.
# Use the last_end_time value from the previous response as the after parameter
# to paginate." Response: {data[{id, event_type, end_time, file_name, file_size,
# file_sha256}], has_more, last_end_time}.

# clp_list_files <EVENT_TYPE> <after_iso> <before_iso|""> <outfile>
# Appends one file-metadata object per line to <outfile>. Sets CLP_LAST_END_TIME
# to the final last_end_time (the next run's `after`), or "" when nothing matched.
CLP_LAST_END_TIME=""
clp_list_files() {
  local et="$1" after="$2" before="$3" out="$4" pages=0 more path
  path="/compliance/workspaces/${CHATGPT_WORKSPACE_ID}/logs"
  CLP_LAST_END_TIME=""
  while :; do
    if [ -n "${before}" ]; then
      cgpt_get_ok "${path}" --data-urlencode "event_type=${et}" --data-urlencode "after=${after}" \
        --data-urlencode "before=${before}" --data-urlencode "limit=100"
    else
      cgpt_get_ok "${path}" --data-urlencode "event_type=${et}" --data-urlencode "after=${after}" \
        --data-urlencode "limit=100"
    fi
    jq -e '(.data | type == "array") and (.has_more | type == "boolean")' "${CGPT_BODY}" >/dev/null 2>&1 \
      || cgpt_die "GET ${path}?event_type=${et} returned HTTP 200 without the documented {data[], has_more} shape"
    jq -c '.data[]' "${CGPT_BODY}" >> "${out}"
    CLP_LAST_END_TIME="$(jq -r '.last_end_time // ""' "${CGPT_BODY}")"
    pages=$((pages + 1))
    more="$(jq -r '.has_more' "${CGPT_BODY}")"
    [ "${more}" = "true" ] || break
    [ -n "${CLP_LAST_END_TIME}" ] \
      || cgpt_die "List Files (${et}): has_more is true but last_end_time is null — cannot page safely"
    after="${CLP_LAST_END_TIME}"
    [ "${pages}" -lt 2000 ] || cgpt_die "List Files (${et}): more than 2000 pages — runaway guard"
  done
}

# clp_download <log_file_id> <expected_sha256> <dest>
# Download File "responds with a 307 Temporary Redirect that points to a
# short-lived signed URL ... clients should immediately follow the redirect".
# Rather than `curl -L` with the bearer header attached (OpenAI's sample script
# does that, relying on curl to drop the header across hosts), this takes the
# Location from the 307 and fetches it with NO Authorization header. The signed
# URL goes to curl on stdin too, so it is never an argv value. The payload is
# then checked against file_sha256 ("use to verify integrity").
# Download File documents 429 ("Follow Retry-After when provided"), and a 24h,
# four-type pull makes hundreds of calls to that one route, so the first request
# is retried like cgpt_get. Each successful 307 issues a fresh signed URL, which
# is followed immediately; the signed-URL GET itself is not retried (the spec
# documents no 429 for the storage host).
clp_download() {
  local id="$1" want="$2" dest="$3" path out code loc rc got attempt=0 wait
  path="/compliance/workspaces/${CHATGPT_WORKSPACE_ID}/logs/${id}"
  CGPT_RETRIES=0
  while :; do
    set +e
    out="$(_cgpt_auth | curl -sS --path-as-is -K - -D "${CGPT_HDRS}" -o "${CGPT_BODY}" \
      -w '%{http_code} %{redirect_url}' "${CHATGPT_ADMIN_BASE}${path}" 2>/dev/null)"
    rc=$?
    set -e
    [ "${rc}" -eq 0 ] || { CGPT_CODE="000"; cgpt_fail_http GET "${path}"; }
    code="${out%% *}"
    loc="${out#* }"
    if [ "${code}" = "429" ] && [ "${attempt}" -lt "${CGPT_GET_RETRIES}" ]; then
      wait="$(_cgpt_retry_after)"
      cgpt_warn "GET ${path}: HTTP 429, retrying in ${wait}s (Retry-After)"
      sleep "${wait}"
      attempt=$((attempt + 1))
      CGPT_RETRIES="${attempt}"
      continue
    fi
    break
  done
  if [ "${code}" != "307" ] || [ -z "${loc}" ] || [ "${loc}" = "${code}" ]; then
    CGPT_CODE="${code}"
    cgpt_fail_http GET "${path} (expected 307 to a signed URL)"
  fi
  set +e
  code="$(printf 'url = "%s"\n' "${loc}" | curl -sS -K - -o "${dest}" -w '%{http_code}' 2>/dev/null)"
  rc=$?
  set -e
  [ "${rc}" -eq 0 ] && [ "${code}" = "200" ] \
    || cgpt_die "download of log file ${id} from its signed URL failed (HTTP ${code}, curl exit ${rc}) — the URL expires shortly after issue; re-run"
  got="$(hth_sha256 "${dest}")"
  [ "${got}" = "${want}" ] \
    || cgpt_die "log file ${id} failed its integrity check (file_sha256 ${want}, got ${got}) — not emitted"
}

# clp_freshness <EVENT_TYPE>... — sets CLP_FRESHNESS to the max_event_time
# object ({"<EVENT_TYPE>": "<ISO 8601>" | null, ...}).
# "This timestamp does not guarantee that all earlier events have arrived."
CLP_FRESHNESS="{}"
clp_freshness() {
  local args=() et
  for et in "$@"; do args+=(--data-urlencode "event_type=${et}"); done
  [ "${#args[@]}" -gt 0 ] || cgpt_die "clp_freshness needs at least one event type"
  cgpt_get_ok "/compliance/workspaces/${CHATGPT_WORKSPACE_ID}/max_event_time" "${args[@]}"
  jq -e '.max_event_time | type == "object"' "${CGPT_BODY}" >/dev/null 2>&1 \
    || cgpt_die "Get Freshness returned HTTP 200 without the documented max_event_time object"
  CLP_FRESHNESS="$(jq -c '.max_event_time' "${CGPT_BODY}")"
}

# clp_pull <EVENT_TYPE> <after_iso> <before_iso|""> <raw_out>
# Lists every file for one event type in the window, downloads and verifies
# each, appends its JSONL to <raw_out>. Sets CLP_FILES (files fetched) and
# CLP_LAST_END_TIME (checkpoint: pass it as the next run's `after`).
CLP_FILES=0
clp_pull() {
  local et="$1" after="$2" before="$3" raw="$4" meta id sha
  meta="${CGPT_TMPDIR}/meta-${et}"
  : > "${meta}"
  CLP_FILES=0
  clp_list_files "${et}" "${after}" "${before}" "${meta}"
  while IFS=$'\t' read -r id sha; do
    [ -n "${id}" ] || continue
    clp_download "${id}" "${sha}" "${CGPT_TMPDIR}/file.jsonl"
    cat "${CGPT_TMPDIR}/file.jsonl" >> "${raw}"
    # A JSONL file may lack a trailing newline; keep record boundaries intact.
    [ -z "$(tail -c 1 "${CGPT_TMPDIR}/file.jsonl")" ] || echo >> "${raw}"
    CLP_FILES=$((CLP_FILES + 1))
  done < <(jq -r '[.id, .file_sha256] | @tsv' "${meta}")
}

# clp_dedupe <raw_jsonl> <out_ndjson>
# "Events are handled with an at least once contract ... Always de-duplicate
# using the stable event_id." Keeps the first occurrence; a record with no
# event_id is kept and counted, never silently dropped.
clp_dedupe() {
  local raw="$1" out="$2" missing
  jq -cr 'if (.event_id | type) == "string" then "\(.event_id)\t\(tojson)" else "\t\(tojson)" end' "${raw}" \
    | awk -F'\t' '$1 == "" { print $2; next } !seen[$1]++ { print $2 }' > "${out}"
  missing="$(jq -r 'select((.event_id | type) != "string") | 1' "${out}" | wc -l | tr -d ' ')"
  [ "${missing}" -eq 0 ] || cgpt_warn "${missing} record(s) carried no event_id and could not be de-duplicated"
}
