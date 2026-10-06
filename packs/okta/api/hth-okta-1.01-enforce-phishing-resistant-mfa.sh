#!/usr/bin/env bash
# HTH Okta Control 1.1: Enforce Phishing-Resistant MFA (FIDO2/WebAuthn)
# Profile: L1 | NIST: IA-2(1), IA-2(6) | DISA STIG: V-273190, V-273191
# https://howtoharden.com/guides/okta/#11-enforce-phishing-resistant-mfa-fido2webauthn
#
# Creates an app sign-in (ACCESS_POLICY) policy whose rule requires two factors,
# one of them a phishing-resistant possession factor. The new policy protects
# nothing until you assign apps to it (Applications and Resources > Applications
# > app > Sign On > User authentication > Edit). Optional: HTH_ADMIN_GROUP_ID
# limits the rule to one group (for example, your administrators).
# Request shapes: Okta Management API, Policy (createPolicy, createPolicyRule).
source "$(dirname "$0")/common.sh"

banner "1.1: Enforce Phishing-Resistant MFA (FIDO2/WebAuthn)"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.1 Enforcing phishing-resistant MFA (FIDO2/WebAuthn)..."

# The rule is only satisfiable if a phishing-resistant authenticator is active
WEBAUTHN_STATUS=$(okta_get "/api/v1/authenticators" \
  | jq -r '[.[] | select(.key == "webauthn")][0].status // "ABSENT"')
if [ "${WEBAUTHN_STATUS}" != "ACTIVE" ]; then
  warn "1.1 Passkey (FIDO2 WebAuthn) authenticator status: ${WEBAUTHN_STATUS} -- activate it first (Security > Authenticators)"
fi

# Check if policy already exists (idempotent)
EXISTING=$(okta_get "/api/v1/policies?type=ACCESS_POLICY" \
  | jq -r '.[] | select(.name == "Phishing-Resistant MFA Policy") | .id')

if [ -n "${EXISTING}" ]; then
  pass "1.1 Phishing-resistant MFA policy already exists (ID: ${EXISTING})"
  increment_applied
  summary
  exit 0
fi

# HTH Guide Excerpt: begin api-create-policy
# Create an app sign-in policy (ACCESS_POLICY takes no policy-level conditions)
info "1.1 Creating phishing-resistant MFA policy..."
POLICY_ID=$(okta_post "/api/v1/policies" '{
  "type": "ACCESS_POLICY",
  "name": "Phishing-Resistant MFA Policy",
  "description": "Requires a phishing-resistant possession factor",
  "status": "ACTIVE"
}' | jq -r '.id // empty')
# HTH Guide Excerpt: end api-create-policy

if [ -z "${POLICY_ID}" ]; then
  fail "1.1 Policy creation returned no ID"
  increment_failed
  summary
fi

GROUP_CONDITION='{}'
if [ -n "${HTH_ADMIN_GROUP_ID:-}" ]; then
  GROUP_CONDITION=$(jq -n --arg g "${HTH_ADMIN_GROUP_ID}" '{people: {groups: {include: [$g]}}}')
fi

# HTH Guide Excerpt: begin api-create-rule
# Rule: two factors, one of them phishing resistant, re-verified at every sign-in
info "1.1 Creating policy rule requiring a phishing-resistant factor..."
RULE_BODY=$(jq -n --argjson conditions "${GROUP_CONDITION}" '(if $conditions == {} then {} else {conditions: $conditions} end) + {
  type: "ACCESS_POLICY",
  name: "Require phishing-resistant MFA",
  priority: 1,
  actions: {
    appSignOn: {
      access: "ALLOW",
      verificationMethod: {
        type: "ASSURANCE",
        factorMode: "2FA",
        reauthenticateIn: "PT0S",
        constraints: [{possession: {phishingResistant: "REQUIRED"}}]
      }
    }
  }
}')
okta_post "/api/v1/policies/${POLICY_ID}/rules" "${RULE_BODY}" > /dev/null
# HTH Guide Excerpt: end api-create-rule

pass "1.1 Phishing-resistant MFA policy created (ID: ${POLICY_ID}) -- assign apps to it to enforce"
increment_applied

summary
