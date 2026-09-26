#!/usr/bin/env bash
# HTH Cloudflare Control 4.3: Configure Split Tunnel Settings
# Profile: L2 | NIST: SC-7 | CIS: 13.5
# https://howtoharden.com/guides/cloudflare/#43-configure-split-tunnel-settings
#
# Read-only audit of the default device profile and every custom device
# profile. A profile in Include mode sends only the listed destinations to
# Gateway -- all other traffic bypasses DNS, HTTP and network filtering -- so
# Include mode is reported as a finding. In Exclude mode, excessive or
# undocumented exclusions are reported.
source "$(dirname "$0")/common.sh"

banner "4.3: Configure Split Tunnel Settings"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "4.3 Auditing split tunnel configuration..."

FINDINGS=0

# jq: the response's .result list; an error when .result is present but is not
# a list, so a malformed response is never read as an empty (compliant) list
RESULT_LIST='(.result // []) | if type == "array" then . else error("result is not a list") end'

# audit_profile <label> <include-path> <exclude-path>
# It is called as `audit_profile ... || FETCH_ERR=1`, and that `||` switches
# off set -e inside the function -- so every jq call carries its own
# `|| return 1`, or a parse failure would fall through to a pass.
audit_profile() {
  local label=$1 inc_path=$2 exc_path=$3 inc exc inc_count exc_count undocumented
  inc=$(cf_get "${inc_path}") || { fail "4.3 ${label}: unable to read the include list"; return 1; }
  exc=$(cf_get "${exc_path}") || { fail "4.3 ${label}: unable to read the exclude list"; return 1; }
  inc_count=$(echo "${inc}" | jq "${RESULT_LIST} | length") \
    || { fail "4.3 ${label}: the include list could not be parsed"; return 1; }
  exc_count=$(echo "${exc}" | jq "${RESULT_LIST} | length") \
    || { fail "4.3 ${label}: the exclude list could not be parsed"; return 1; }
  if [ "${inc_count}" -gt 0 ]; then
    warn "4.3 ${label}: Include mode (${inc_count} route(s)) -- all other traffic bypasses Gateway"
    FINDINGS=$((FINDINGS + 1))
    return 0
  fi
  undocumented=$(echo "${exc}" | jq "[${RESULT_LIST} | .[] | select((.description // \"\") == \"\")] | length") \
    || { fail "4.3 ${label}: the exclude list could not be parsed"; return 1; }
  info "4.3 ${label}: Exclude mode, ${exc_count} exclusion(s)"
  if [ "${exc_count}" -gt 20 ]; then
    warn "4.3 ${label}: ${exc_count} exclusions is excessive -- review and minimize exceptions"
    FINDINGS=$((FINDINGS + 1))
  fi
  if [ "${undocumented}" -gt 0 ]; then
    warn "4.3 ${label}: ${undocumented} exclusion(s) have no description (business justification)"
    FINDINGS=$((FINDINGS + 1))
  fi
  return 0
}

# HTH Guide Excerpt: begin api-audit-split-tunnel
# Audit split tunnel mode and exclusions for the default and custom profiles
FETCH_ERR=0
audit_profile "default profile" \
  "/accounts/${CF_ACCOUNT_ID}/devices/policy/include" \
  "/accounts/${CF_ACCOUNT_ID}/devices/policy/exclude" || FETCH_ERR=1

# Parse the profile list before looping: a jq failure inside `done < <(jq ...)`
# is silent and would leave the loop empty, so custom profiles would go unaudited
PROFILE_LINES=""
if PROFILES=$(cf_get "/accounts/${CF_ACCOUNT_ID}/devices/policies"); then
  PROFILE_LINES=$(echo "${PROFILES}" | jq -c "${RESULT_LIST} | .[]
    | select(.default != true and .policy_id != null)") || {
    fail "4.3 Unable to parse the custom device profile list"
    FETCH_ERR=1
    PROFILE_LINES=""
  }
else
  fail "4.3 Unable to list custom device profiles"
  FETCH_ERR=1
fi
while IFS= read -r profile; do
  [ -z "${profile}" ] && continue
  PID=$(echo "${profile}" | jq -r '.policy_id')
  PNAME=$(echo "${profile}" | jq -r '.name // .policy_id')
  audit_profile "profile '${PNAME}'" \
    "/accounts/${CF_ACCOUNT_ID}/devices/policy/${PID}/include" \
    "/accounts/${CF_ACCOUNT_ID}/devices/policy/${PID}/exclude" || FETCH_ERR=1
done < <(printf '%s\n' "${PROFILE_LINES}")
# HTH Guide Excerpt: end api-audit-split-tunnel

info "4.3 Keep Exclude mode; Include mode sends only listed routes through Gateway and leaves all other traffic unfiltered"
if [ "${FETCH_ERR}" = "1" ]; then
  fail "4.3 Audit incomplete -- one or more split tunnel lists could not be read"
  increment_failed
elif [ "${FINDINGS}" = "0" ]; then
  pass "4.3 Split tunnel configuration is in Exclude mode with documented, minimal exclusions"
  increment_applied
else
  fail "4.3 ${FINDINGS} split tunnel finding(s)"
  increment_failed
fi

summary
