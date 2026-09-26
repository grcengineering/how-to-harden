#!/usr/bin/env bash
# HTH Cloudflare Control 1.2: Configure Multi-Factor Authentication
# Profile: L1 | NIST: IA-2(1) | CIS: 6.5
# https://howtoharden.com/guides/cloudflare/#12-configure-multi-factor-authentication
#
# Read-only audit. An application is MFA-protected only when EVERY policy that
# can let a user in requires MFA:
#   - a Bypass policy skips Access login entirely, so it can never require MFA
#     and always counts as a gap;
#   - an Allow policy is covered when it has a Require rule on auth_method
#     "mfa", or when Independent MFA applies to it. Independent MFA follows the
#     documented precedence Policy > Application > Organization
#     (developers.cloudflare.com/cloudflare-one/access-controls/policies/mfa-requirements/):
#     a policy's own mfa_config wins over the application's, which wins over
#     the organization default (mfa_required_for_all_apps).
# A level's mfa_config counts as "on" only when it carries a custom setting
# (allowed_authenticators or session_duration) and is not disabled; an empty or
# bare {"mfa_disabled":false} object is treated as inheriting the next level,
# never as MFA on. Service Auth (non_identity) policies admit service tokens,
# not people, and Block policies admit no one, so neither is evaluated.
# Every page of applications and policies is read; any application whose
# policies cannot be read fails the audit.
source "$(dirname "$0")/common.sh"

banner "1.2: Configure Multi-Factor Authentication"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.2 Checking MFA enforcement in Access policies..."

APPS=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/access/apps") || {
  fail "1.2 Unable to retrieve Access applications"
  increment_failed
  summary
  exit 0
}

APP_COUNT=$(echo "${APPS}" | jq '.result | length')
info "1.2 Found ${APP_COUNT} Access application(s)"

ORG=$(cf_get "/accounts/${CF_ACCOUNT_ID}/access/organizations") || {
  fail "1.2 Unable to retrieve Access organization settings"
  increment_failed
  summary
  exit 0
}
ORG_MFA_DEFAULT=$(echo "${ORG}" | jq -r '.result.mfa_required_for_all_apps // false')

if [ "${APP_COUNT}" = "0" ]; then
  warn "1.2 No Access applications to audit -- nothing was checked"
  increment_skipped
  summary
  exit 0
fi

# HTH Guide Excerpt: begin api-verify-mfa
# Independent MFA at one level (application or policy): "on", "off" or "inherit"
MFA_LEVEL='def mfa_level:
  if .mfa_config == null then "inherit"
  elif (.mfa_config.mfa_disabled // false) then "off"
  elif ((.mfa_config.allowed_authenticators // []) | length) > 0
    or ((.mfa_config.session_duration // "") != "") then "on"
  else "inherit" end;'

# Every Allow or Bypass policy must require MFA, by rule or by Independent MFA
MFA_MISSING=0
FETCH_ERR=0
while IFS= read -r app; do
  APP_ID=$(echo "${app}" | jq -r '.id')
  APP_NAME=$(echo "${app}" | jq -r '.name')
  APP_MFA=$(echo "${app}" | jq -r "${MFA_LEVEL} mfa_level")

  APP_POLICIES=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/access/apps/${APP_ID}/policies") || {
    fail "1.2 Could not read policies for application '${APP_NAME}'"
    FETCH_ERR=1
    continue
  }
  GAPS=$(echo "${APP_POLICIES}" | jq -r --arg app "${APP_MFA}" --argjson org "${ORG_MFA_DEFAULT}" "${MFA_LEVEL}"'
    .result[]
    | (.decision // "allow") as $d
    | select($d == "allow" or $d == "bypass")
    | (.name // "unnamed policy") as $n
    | if $d == "bypass" then "\($n): Bypass skips Access login, so MFA cannot apply"
      elif any(.require[]?; .auth_method.auth_method? == "mfa") then empty
      else mfa_level as $p
        | (if $p != "inherit" then $p elif $app != "inherit" then $app
           elif $org then "on" else "off" end) as $effective
        | if $effective == "on" then empty
          elif $p == "off" then "\($n): policy disables Independent MFA and has no MFA Require rule"
          else "\($n): no MFA Require rule and Independent MFA does not apply" end
      end')

  if [ -n "${GAPS}" ]; then
    warn "1.2 Application '${APP_NAME}' admits users without MFA:"
    while IFS= read -r gap; do
      echo "    - ${gap}"
    done < <(printf '%s\n' "${GAPS}")
    MFA_MISSING=$((MFA_MISSING + 1))
  fi
done < <(echo "${APPS}" | jq -c '.result[]')
# HTH Guide Excerpt: end api-verify-mfa

if [ "${FETCH_ERR}" = "1" ]; then
  fail "1.2 Audit incomplete -- one or more applications could not be read"
  increment_failed
elif [ "${MFA_MISSING}" = "0" ]; then
  pass "1.2 All ${APP_COUNT} Access application(s) require MFA"
  increment_applied
else
  fail "1.2 ${MFA_MISSING} application(s) admit users without MFA -- require MFA in every Allow policy (Authentication method = mfa) or via Independent MFA, and remove Bypass policies"
  increment_failed
fi

summary
