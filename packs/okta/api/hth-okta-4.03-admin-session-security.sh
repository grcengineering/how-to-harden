#!/usr/bin/env bash
# HTH Okta Control 4.3: Configure Admin Session Security
# Profile: L1 | NIST: SC-23, AC-12
# https://howtoharden.com/guides/okta/#43-configure-admin-session-security
#
# Read-only audit of the Okta Admin Console app sign-in policy (Step 4): every
# ALLOW rule should demand a phishing-resistant factor and re-authentication at
# each sign-in. IP binding for the admin console and Protected Actions have no
# public API (the Okta Management API documents neither), so this pack does not
# touch them -- configure those in the console.
source "$(dirname "$0")/common.sh"

banner "4.3: Configure Admin Session Security"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.3 Auditing the Okta Admin Console sign-in policy..."

# HTH Guide Excerpt: begin api-check-admin-console-policy
# The Okta Admin Console is the app named "saasure"; its app sign-in policy is
# linked from the app object (a failed read stops the pack)
ADMIN_APP=$(okta_get "/api/v1/apps?filter=name%20eq%20%22saasure%22" | jq -c '.[0] // empty')
if [ -z "${ADMIN_APP}" ]; then
  fail "4.3 Okta Admin Console app (saasure) not returned -- cannot audit its policy"
  increment_failed
  summary
fi
POLICY_ID=$(printf '%s' "${ADMIN_APP}" | jq -r '._links.accessPolicy.href | split("/") | last')
RULES=$(okta_get "/api/v1/policies/${POLICY_ID}/rules")

# ALLOW rules that do not require a phishing-resistant factor, or that let an
# earlier sign-in satisfy the Admin Console (reauthenticateIn other than PT0S)
WEAK_RULES=$(printf '%s' "${RULES}" | jq -r '
  .[] | select(.status == "ACTIVE" and .actions.appSignOn.access == "ALLOW")
  | select(
      ([.actions.appSignOn.verificationMethod.constraints[]?.possession.phishingResistant] | index("REQUIRED") | not)
      or (.actions.appSignOn.verificationMethod.reauthenticateIn // "" ) != "PT0S")
  | "  - \(.name): phishing-resistant=\([.actions.appSignOn.verificationMethod.constraints[]?.possession.phishingResistant] | join(",")), reauthenticateIn=\(.actions.appSignOn.verificationMethod.reauthenticateIn // "unset")"')
# HTH Guide Excerpt: end api-check-admin-console-policy

if [ -n "${WEAK_RULES}" ]; then
  warn "4.3 Admin Console rules that allow access without a phishing-resistant factor at every sign-in:"
  echo "${WEAK_RULES}"
else
  pass "4.3 Every active ALLOW rule on the Admin Console requires a phishing-resistant factor at every sign-in"
fi

info "4.3 IP binding for admin console and Protected Actions: verify in the console (no public API)"
increment_applied

summary
