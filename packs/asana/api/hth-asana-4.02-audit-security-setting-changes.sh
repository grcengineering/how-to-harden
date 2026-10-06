#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: asana-4.2
#   guide:   https://howtoharden.com/guides/asana/#42-monitor-security-compliance
#   profile: L1
#   mode:    read-only
#   requires: ASANA_SERVICE_ACCOUNT_PAT(service account with Scoped permissions > Audit logs; Enterprise+ or Legacy Enterprise), ASANA_WORKSPACE_GID, ASANA_LOOKBACK_DAYS(optional, default 7, max 90), ASANA_LOGIN_FAILURE_THRESHOLD(optional)
# =============================================================================
# HTH Asana Control 4.2: Monitor Security Compliance
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 8.11 | NIST 800-53 CA-7
# Source: https://howtoharden.com/guides/asana/#42-monitor-security-compliance
# Dependencies: bash, curl (7.55+ for -H @file), jq, date
# API (verified against Asana's OpenAPI spec asana_oas.yaml and the supported
#      event list at https://developers.asana.com/docs/audit-log-events, 2026-09-24):
#   GET /workspaces/{workspace_gid}/audit_log_events?event_type=...&start_at=...
#
# The weekly posture review as a command. Most of this guide's settings (SAML,
# 2FA, session length, IP allowlist, app approval, mobile data controls,
# read-only links) have NO read endpoint: their current value cannot be
# fetched. What Asana does record is every change to them, as an Admin settings
# audit event. This pack pulls the documented event types for the review window
# and sorts them into two lists.
#
# ── TRAP 1: a change is not a state ─────────────────────────────────────────
# An empty window proves nothing was CHANGED in the window, not that the
# settings are correct. The console walk in each control is still what
# establishes the baseline; this pack catches drift away from it.
#
# ── TRAP 2: the stream never ends on its own ────────────────────────────────
# next_page keeps coming for a filter with matches; an empty data page is the
# end of the current events.
#
# ── TRAP 3: one vendor doc typo, used as documented ─────────────────────────
# Asana's table describes workspace_mobile_app_attachments_sharing_disabled as
# "...was enabled." The event NAME is the contract; this pack keys on names.
#
# ── TRAP 4: a silent feed is not a quiet week ───────────────────────────────
# Zero setting-change events means something only if the feed was delivering
# events at all. Before the 32 filtered queries, the pack reads one unfiltered
# page. If the whole window holds no event of any type, it exits 2 instead of
# reporting "no weakening change".
#
# Exit codes: 0 no weakening change | 1 weakening change (or login-failure threshold) found | 2 precondition (including an empty feed)
# =============================================================================

set -eEuo pipefail
trap 'echo "PRECONDITION: unexpected failure at line ${LINENO}" >&2; exit 2' ERR

# A missing input is a precondition (exit 2), never a finding (exit 1).
need() { if [ -z "${!1:-}" ]; then echo "PRECONDITION: set $1 — $2" >&2; exit 2; fi; }
need ASANA_SERVICE_ACCOUNT_PAT "service account token scoped to Audit logs"
need ASANA_WORKSPACE_GID "the workspace gid of the organization"
ASANA_API_BASE="${ASANA_API_BASE:-https://app.asana.com/api/1.0}"
LOOKBACK_DAYS="${ASANA_LOOKBACK_DAYS:-7}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
case "${LOOKBACK_DAYS}" in ''|*[!0-9]*) echo "PRECONDITION: ASANA_LOOKBACK_DAYS must be a whole number" >&2; exit 2 ;; esac
if [ "${LOOKBACK_DAYS}" -lt 1 ] || [ "${LOOKBACK_DAYS}" -gt 90 ]; then
  echo "PRECONDITION: ASANA_LOOKBACK_DAYS must be 1-90; audit events are deleted after 90 days" >&2; exit 2
fi
case "${ASANA_LOGIN_FAILURE_THRESHOLD:-0}" in *[!0-9]*) echo "PRECONDITION: ASANA_LOGIN_FAILURE_THRESHOLD must be a whole number" >&2; exit 2 ;; esac
START_AT=$(date -u -v-"${LOOKBACK_DAYS}"d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "${LOOKBACK_DAYS} days ago" +%Y-%m-%dT%H:%M:%SZ)

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-asana-402.XXXXXX")"
ITEMS_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-asana-402i.XXXXXX")"
trap 'rm -f "${BODY_FILE}" "${ITEMS_FILE}"' EXIT
FINDINGS=0; REVIEW=0

# One GET. Fails closed: anything but HTTP 200 with a data array exits 2.
# The token reaches curl through a process-substitution header file, never argv.
asana_get() {
  local code rc=0
  code=$(curl -sS --max-time 120 -o "${BODY_FILE}" -w '%{http_code}' \
    -H @<(printf 'Authorization: Bearer %s\n' "${ASANA_SERVICE_ACCOUNT_PAT}") \
    -H 'Accept: application/json' "${ASANA_API_BASE}$1" 2>/dev/null) || rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: GET ${1%%\?*} got no HTTP response (curl exit ${rc})" >&2; exit 2
  fi
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: GET ${1%%\?*} returned HTTP ${code}: $(jq -r '[.errors[]?.message] | join("; ")' "${BODY_FILE}" 2>/dev/null || true)" >&2
    echo "  The Audit Log API needs a service account token with the Audit logs scope (Enterprise+ or Legacy Enterprise)." >&2
    exit 2
  fi
  if ! jq -e 'type == "object" and (.data | type == "array")' "${BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: GET ${1%%\?*} returned no data array" >&2; exit 2
  fi
}

# All events of one type in the window, into ITEMS_FILE (TRAP 2).
events_of() {  # events_of <event_type>
  local query="event_type=$1&start_at=${START_AT}&limit=100" offset="" pages=0
  : > "${ITEMS_FILE}"
  while :; do
    if [ -n "${offset}" ]; then
      asana_get "/workspaces/${ASANA_WORKSPACE_GID}/audit_log_events?${query}&offset=${offset}"
    else
      asana_get "/workspaces/${ASANA_WORKSPACE_GID}/audit_log_events?${query}"
    fi
    pages=$((pages + 1))
    [ "$(jq '.data | length' "${BODY_FILE}")" -gt 0 ] || break
    jq -c '.data[]' "${BODY_FILE}" >> "${ITEMS_FILE}"
    offset=$(jq -r '.next_page.offset // "" | @uri' "${BODY_FILE}")
    [ -n "${offset}" ] || break
    if [ "${pages}" -ge 1000 ]; then echo "PRECONDITION: audit log paging exceeded 1000 pages" >&2; exit 2; fi
  done
}

show() {  # show <label>
  jq -r --arg l "$1" '"  \($l): \(.event_type) at \(.created_at) by \(.actor.name // .actor.actor_type // "unknown")"
                     + (if .details.new_value then " (\(.details.old_value // "unset") -> \(.details.new_value))" else "" end)' "${ITEMS_FILE}"
}

# HTH Guide Excerpt: begin security-setting-drift
# A change that turns a control in this guide OFF or open. Any one is a finding.
WEAKENING="workspace_require_two_factor_auth_disabled
workspace_ip_allowlist_disabled
workspace_ip_allowlist_api_traffic_disabled
workspace_view_links_enabled
workspace_logged_out_view_authentication_required_disabled
workspace_form_link_authentication_required_disabled
workspace_personal_access_token_enabled
workspace_mobile_app_biometric_authentication_required_disabled
workspace_mobile_app_screen_capture_enabled
workspace_mobile_app_copy_paste_enabled
workspace_mobile_app_attachments_sharing_enabled"
# A change to a control whose direction the event does not state. Each one is
# listed for the weekly review against the recorded baseline.
CHANGED="workspace_saml_settings_changed
workspace_saml_url_changed
workspace_required_sso_provider_settings_changed
workspace_password_requirements_changed
workspace_default_session_duration_changed
workspace_idle_session_duration_changed
workspace_allowed_ip_range_added
workspace_allowed_ip_range_changed
workspace_ip_allowlist_member_type_changed
workspace_require_app_approvals_of_type_changed
workspace_app_admin_approval_setting_changed
workspace_guest_invite_permissions_changed
workspace_trusted_domains_setting_changed
workspace_file_attachment_options_changed
workspace_machine_learning_product_feature_changed
workspace_personal_access_token_expiry_changed
workspace_service_account_token_expiry_changed
user_workspace_admin_role_changed
custom_role_created
role_permission_changed"

echo "Asana 4.2 — security setting changes, ${LOOKBACK_DAYS} days from ${START_AT} (changes, not state: TRAP 1)"
# TRAP 4. The feed must hold at least one event of any type in the window.
asana_get "/workspaces/${ASANA_WORKSPACE_GID}/audit_log_events?start_at=${START_AT}&limit=1"
if [ "$(jq '.data | length' "${BODY_FILE}")" -eq 0 ]; then
  echo "PRECONDITION: the audit feed returned 0 events of any type for the window; an absence of setting changes is not evidence (TRAP 4)." >&2
  echo "  Widen ASANA_LOOKBACK_DAYS, or check that the token belongs to this organization." >&2
  exit 2
fi
echo "  audit feed live: at least one event in the window"
queried=0
for t in ${WEAKENING}; do
  events_of "${t}"; queried=$((queried + 1))
  n=$(jq -s 'length' "${ITEMS_FILE}")
  if [ "${n}" -gt 0 ]; then show "FINDING"; FINDINGS=$((FINDINGS + n)); fi
done
for t in ${CHANGED}; do
  events_of "${t}"; queried=$((queried + 1))
  n=$(jq -s 'length' "${ITEMS_FILE}")
  if [ "${n}" -gt 0 ]; then show "REVIEW"; REVIEW=$((REVIEW + n)); fi
done
events_of "user_login_failed"; queried=$((queried + 1))
failures=$(jq -s 'length' "${ITEMS_FILE}")
echo "  user_login_failed in window: ${failures}"
if [ -n "${ASANA_LOGIN_FAILURE_THRESHOLD:-}" ] && [ "${failures}" -gt "${ASANA_LOGIN_FAILURE_THRESHOLD}" ]; then
  echo "FINDING: ${failures} failed logins exceeds ASANA_LOGIN_FAILURE_THRESHOLD=${ASANA_LOGIN_FAILURE_THRESHOLD}"
  FINDINGS=$((FINDINGS + 1))
fi
echo "  event types queried: ${queried} (HTTP 200 on every page); weakening: ${FINDINGS}; for review: ${REVIEW}"
# HTH Guide Excerpt: end security-setting-drift

if [ "${FINDINGS}" -gt 0 ]; then
  exit 1
fi
echo "NO WEAKENING CHANGE in the window. ${REVIEW} change(s) listed for review against the baseline."
exit 0
