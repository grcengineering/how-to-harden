#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: stripe-3.3
#   guide:   https://howtoharden.com/guides/stripe/#33-configure-restricted-keys
#   profile: L1
#   mode:    read-only
#   requires: STRIPE_SECRET_KEY(the restricted key under test — run it with the integration's own key)
# =============================================================================
# HTH Stripe Control 3.3: Configure Restricted Keys
# Profile: L1 | NIST: AC-6 | CIS: 5.4
# https://howtoharden.com/guides/stripe/#33-configure-restricted-keys
#
# HOW THIS PACK DECIDES. It probes resources an integration usually should not
# read and branches on the HTTP status, never on "the call failed":
#   403 -> the key is denied that resource, as a narrowly scoped key should be (PASS)
#   200 -> the key can read it; confirm the integration really needs that (WARN)
#   anything else (401 bad key, 429, 5xx, 000 no connection) -> nothing was
#          learned about scope, so the probe FAILS.
#
# EXIT CODES. The pack passes only when every probe came back 403.
#   0 -> every probed resource was denied (403): the key is narrowly scoped
#   1 -> at least one probe could not be assessed (FAIL)
#   3 -> NEEDS REVIEW: the key can read a probed resource (200). A full-access
#        standard secret key lands here, so this is never reported as a pass.
source "$(dirname "$0")/common.sh"

banner "3.3: Configure Restricted Keys"
should_apply 1 || { increment_skipped; finish; }

# Restricted key creation is a Dashboard operation.
info "3.3 Restricted keys are created in the Dashboard (Developers > API keys)"
info "3.3 Validating current key scope by testing restricted operations..."

# HTH Guide Excerpt: begin api-validate-key-scope
# Probe resources a narrowly scoped key should be denied, and branch on the status
_readable=0
probe_denied() {
  local path="$1" label="$2" code
  code=$(stripe_status "${path}")
  case "${code}" in
    403) pass "3.3 Current key cannot ${label} (403) — properly scoped" ;;
    200) warn "3.3 Current key can ${label} (200) — confirm the integration needs it"
         _readable=$((_readable + 1)) ;;
    *)   fail "3.3 Could not assess '${label}' (HTTP ${code}) — check the key and connectivity"
         increment_failed ;;
  esac
}

probe_denied "/customers?limit=1"       "list customers"
probe_denied "/payment_intents?limit=1" "list payment intents"

# Webhook endpoint read access is informational (many integrations need it)
code=$(stripe_status "/webhook_endpoints?limit=1")
case "${code}" in
  200) info "3.3 Current key has webhook endpoint read access" ;;
  403) info "3.3 Current key cannot list webhook endpoints" ;;
  *)   fail "3.3 Could not assess webhook endpoint access (HTTP ${code})"; increment_failed ;;
esac

# Pass only when every probe was denied: a key that can read a probed resource
# (a full-access secret key always can) needs review, never a PASS line
if [ "${_failed}" -gt 0 ]; then
  fail "3.3 Key scope not assessed — see the FAIL lines above"
elif [ "${_readable}" -gt 0 ]; then
  warn "3.3 NEEDS REVIEW — the key can read ${_readable} probed resource(s) a narrowly scoped key should be denied"
else
  pass "3.3 Key scope validation complete — every probed resource was denied (403)"
  increment_applied
fi
# HTH Guide Excerpt: end api-validate-key-scope

# Exit 1 on any failure (finish), 3 when the key needs review, 0 only when every probe was denied
if [ "${_failed}" -eq 0 ] && [ "${_readable}" -gt 0 ]; then
  summary
  exit 3
fi
finish
