#!/usr/bin/env bash
# HTH Okta Code Pack -- Validation Script (Read-Only Audit)
# Checks all controls without making changes (GET requests only)
# Usage: HTH_PROFILE_LEVEL=2 ./validate.sh
# https://howtoharden.com/guides/okta/
source "$(dirname "$0")/common.sh"

banner "Validation Audit (Read-Only)"

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
TOTAL_COUNT=0

check_pass() { PASS_COUNT=$((PASS_COUNT + 1)); TOTAL_COUNT=$((TOTAL_COUNT + 1)); pass "$1"; }
check_fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); TOTAL_COUNT=$((TOTAL_COUNT + 1)); fail "$1"; }
check_skip() { SKIP_COUNT=$((SKIP_COUNT + 1)); TOTAL_COUNT=$((TOTAL_COUNT + 1)); warn "[SKIP] $1"; }

# ---------------------------------------------------------------------------
# Generic jq-assertion check helper (GET only)
# Usage: check "1.1" "Description" "/api/v1/endpoint" '.jq_expression'
# ---------------------------------------------------------------------------
check() {
  local control_id="$1"
  local description="$2"
  local endpoint="$3"
  local jq_expr="$4"

  local result
  result=$(okta_get "${endpoint}" 2>/dev/null | jq -r "${jq_expr}" 2>/dev/null || echo "ERROR")

  if [ "${result}" = "true" ]; then
    check_pass "${control_id} ${description}"
  elif [ "${result}" = "ERROR" ]; then
    check_fail "${control_id} ${description} (API call or jq expression failed)"
  else
    check_fail "${control_id} ${description}"
  fi
}

# ---------------------------------------------------------------------------
# Check with profile level gate
# Usage: check_level 2 "2.3" "Description" "/api/v1/endpoint" '.jq_expression'
# ---------------------------------------------------------------------------
check_level() {
  local level="$1"
  shift
  if [ "${HTH_PROFILE_LEVEL}" -lt "${level}" ]; then
    check_skip "$1 $2 (requires L${level})"
    return 0
  fi
  check "$@"
}

# ===========================================================================
# Section 1: Authentication & Access Controls
# ===========================================================================
info "--- Section 1: Authentication & Access Controls ---"

# 1.1 Phishing-Resistant MFA (FIDO2/WebAuthn active)
check "1.1" "FIDO2/WebAuthn authenticator is active" \
  "/api/v1/authenticators" \
  '[.[] | select(.key == "webauthn" and .status == "ACTIVE")] | length > 0'

# 1.2 Admin Role Separation (custom roles exist)
check "1.2" "Custom admin roles exist (role separation)" \
  "/api/v1/iam/roles" \
  '.roles | length > 0'

# 1.4 Password Policy -- minimum length
if [ "${HTH_PROFILE_LEVEL}" -ge 2 ]; then
  check "1.4" "Password policy min length >= 15 (L2+)" \
    "/api/v1/policies?type=PASSWORD" \
    '.[0].settings.password.complexity.minLength >= 15'
else
  check "1.4" "Password policy min length >= 12 (L1)" \
    "/api/v1/policies?type=PASSWORD" \
    '.[0].settings.password.complexity.minLength >= 12'
fi

# 1.4 Password complexity
check "1.4" "Password policy requires uppercase" \
  "/api/v1/policies?type=PASSWORD" \
  '.[0].settings.password.complexity.minUpperCase >= 1'

check "1.4" "Password policy requires lowercase" \
  "/api/v1/policies?type=PASSWORD" \
  '.[0].settings.password.complexity.minLowerCase >= 1'

check "1.4" "Password policy requires number" \
  "/api/v1/policies?type=PASSWORD" \
  '.[0].settings.password.complexity.minNumber >= 1'

check "1.4" "Password policy requires symbol" \
  "/api/v1/policies?type=PASSWORD" \
  '.[0].settings.password.complexity.minSymbol >= 1'

# 1.4 Password history
if [ "${HTH_PROFILE_LEVEL}" -ge 2 ]; then
  check "1.4" "Password history count >= 5 (L2+)" \
    "/api/v1/policies?type=PASSWORD" \
    '.[0].settings.password.age.historyCount >= 5'
else
  check "1.4" "Password history count >= 4 (L1)" \
    "/api/v1/policies?type=PASSWORD" \
    '.[0].settings.password.age.historyCount >= 4'
fi

# 1.5 Account Lockout
if [ "${HTH_PROFILE_LEVEL}" -ge 2 ]; then
  check "1.5" "Account lockout threshold <= 3 (L2+)" \
    "/api/v1/policies?type=PASSWORD" \
    '.[0].settings.password.lockout.maxAttempts <= 3 and .[0].settings.password.lockout.maxAttempts > 0'
else
  check "1.5" "Account lockout threshold <= 5 (L1)" \
    "/api/v1/policies?type=PASSWORD" \
    '.[0].settings.password.lockout.maxAttempts <= 5 and .[0].settings.password.lockout.maxAttempts > 0'
fi

# 1.9 Default Authentication Policy -- zero apps assigned
info "  Checking Default Authentication Policy app assignments..."
DEFAULT_POLICY_ID=$(okta_get "/api/v1/policies?type=ACCESS_POLICY" 2>/dev/null \
  | jq -r '.[] | select(.system == true and .name == "Default Policy") | .id' 2>/dev/null || echo "")

if [ -n "${DEFAULT_POLICY_ID}" ] && [ "${DEFAULT_POLICY_ID}" != "null" ]; then
  check "1.9" "Default Policy has zero apps assigned" \
    "/api/v1/policies/${DEFAULT_POLICY_ID}/app" \
    'length == 0'
else
  check_fail "1.9 Could not find Default Authentication Policy"
fi

# 1.10 Self-service recovery -- weak methods inactive
check "1.10" "SMS recovery is inactive" \
  "/api/v1/policies?type=PASSWORD" \
  '.[0].settings.recovery.factors.okta_sms.status == "INACTIVE"'

check "1.10" "Voice call recovery is inactive" \
  "/api/v1/policies?type=PASSWORD" \
  '.[0].settings.recovery.factors.okta_call.status == "INACTIVE"'

check "1.10" "Security question recovery is inactive" \
  "/api/v1/policies?type=PASSWORD" \
  '.[0].settings.recovery.factors.recovery_question.status == "INACTIVE"'

check "1.10" "Security Question authenticator is inactive" \
  "/api/v1/authenticators" \
  '[.[] | select(.key == "security_question" and .status == "ACTIVE")] | length == 0'

# 1.11 End-user notifications -- all five enabled
check "1.11" "New sign-on notification enabled" \
  "/api/v1/org/settings" \
  '.endUserNotifications.newSignOnNotification.enabled == true'

check "1.11" "Authenticator enrolled notification enabled" \
  "/api/v1/org/settings" \
  '.endUserNotifications.authenticatorEnrolledNotification.enabled == true'

check "1.11" "Authenticator reset notification enabled" \
  "/api/v1/org/settings" \
  '.endUserNotifications.authenticatorResetNotification.enabled == true'

check "1.11" "Password changed notification enabled" \
  "/api/v1/org/settings" \
  '.endUserNotifications.passwordChangedNotification.enabled == true'

check "1.11" "Factor reset notification enabled" \
  "/api/v1/org/settings" \
  '.endUserNotifications.factorResetNotification.enabled == true'

# 1.11 Suspicious Activity Reporting
check "1.11" "Suspicious Activity Reporting enabled" \
  "/api/v1/org/privacy/suspicious-activity-reporting" \
  '.enabled == true'

# ===========================================================================
# Section 2: Network Access Controls
# ===========================================================================
info ""
info "--- Section 2: Network Access Controls ---"

# 2.1 Network zones exist
check "2.1" "At least one IP network zone is configured" \
  "/api/v1/zones" \
  '[.[] | select(.type == "IP")] | length > 0'

# 2.3 Enhanced Dynamic Zone active (L2)
check_level 2 "2.3" "Enhanced Dynamic Zone is active" \
  "/api/v1/zones" \
  '[.[] | select(.name == "DefaultEnhancedDynamicZone" and .status == "ACTIVE")] | length > 0'

# 2.3 Blocklist zone exists (L2)
check_level 2 "2.3" "A blocklist zone exists and is active" \
  "/api/v1/zones" \
  '[.[] | select(.usage == "BLOCKLIST" and .status == "ACTIVE")] | length > 0'

# ===========================================================================
# Section 3: OAuth & Integration Security
# ===========================================================================
info ""
info "--- Section 3: OAuth & Integration Security ---"

# 3.1 OAuth applications auditable
check "3.1" "OAuth applications are accessible for audit" \
  "/api/v1/apps?filter=status%20eq%20%22ACTIVE%22&limit=1" \
  'type == "array"'

# 3.4 API tokens auditable
check "3.4" "API tokens are accessible for audit" \
  "/api/v1/api-tokens" \
  'type == "array"'

# ===========================================================================
# Section 4: Session Management
# ===========================================================================
info ""
info "--- Section 4: Session Management ---"

# 4.1 Global session policies exist
check "4.1" "Global session policies are configured" \
  "/api/v1/policies?type=OKTA_SIGN_ON" \
  'length > 0'

# 4.3 Admin session ASN binding enabled
check "4.3" "Admin session ASN binding is enabled" \
  "/api/v1/org/settings" \
  '.adminSessionASNBinding == "ENABLED"'

# 4.3 Admin session IP binding enabled (L2+)
check_level 2 "4.3" "Admin session IP binding is enabled (L2+)" \
  "/api/v1/org/settings" \
  '.adminSessionIPBinding == "ENABLED"'

# ===========================================================================
# Section 5: Monitoring & Detection
# ===========================================================================
info ""
info "--- Section 5: Monitoring & Detection ---"

# 5.1 System Log API accessible
check "5.1" "System Log API is accessible" \
  "/api/v1/logs?limit=1" \
  'type == "array"'

# 5.1 Log streaming configured
check "5.1" "Log streaming is configured (DISA STIG V-273202 HIGH)" \
  "/api/v1/logStreams" \
  'length > 0'

# 5.4 Behavior detection rules active (L2)
check_level 2 "5.4" "Behavior detection rules are active" \
  "/api/v1/behaviors" \
  '[.[] | select(.status == "ACTIVE")] | length > 0'

# 5.5 Identity providers auditable
check "5.5" "Identity providers are accessible for audit" \
  "/api/v1/idps" \
  'type == "array"'

# ===========================================================================
# Section 7: Operational Security
# ===========================================================================
info ""
info "--- Section 7: Operational Security ---"

# 7.3 Super Admin count < 5
info "  Checking Super Admin count..."
SUPER_ADMIN_COUNT=$(okta_get "/api/v1/iam/assignees/users?roleType=SUPER_ADMIN" 2>/dev/null \
  | jq 'length' 2>/dev/null || echo "unknown")

if [ "${SUPER_ADMIN_COUNT}" != "unknown" ] && [ "${SUPER_ADMIN_COUNT}" -ge 0 ] 2>/dev/null; then
  if [ "${SUPER_ADMIN_COUNT}" -lt 5 ]; then
    check_pass "7.3 Super Admin count (${SUPER_ADMIN_COUNT}) is < 5"
  else
    check_fail "7.3 Super Admin count (${SUPER_ADMIN_COUNT}) is >= 5 -- reduce to < 5"
  fi
else
  check_skip "7.3 Could not determine Super Admin count"
fi

# 7.3 Stale accounts check
info "  Checking for stale accounts (90+ days inactive)..."
STALE_COUNT=$(okta_get "/api/v1/users?filter=status+eq+%22ACTIVE%22&limit=200" 2>/dev/null \
  | jq '[.[] | select(.lastLogin != null) | select((.lastLogin | fromdateiso8601) < (now - 7776000))] | length' \
  2>/dev/null || echo "unknown")

if [ "${STALE_COUNT}" != "unknown" ] && [ "${STALE_COUNT}" -ge 0 ] 2>/dev/null; then
  if [ "${STALE_COUNT}" -eq 0 ]; then
    check_pass "7.3 No stale accounts found (90+ days inactive)"
  else
    check_fail "7.3 Found ${STALE_COUNT} stale account(s) (90+ days inactive) -- review and suspend"
  fi
else
  check_skip "7.3 Could not check for stale accounts"
fi

# ===========================================================================
# Final Summary
# ===========================================================================
CHECKED=$((PASS_COUNT + FAIL_COUNT))
echo ""
echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}  Okta Hardening Validation Results${NC}"
echo -e "${BLUE}  Profile Level: L${HTH_PROFILE_LEVEL}${NC}"
echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}  PASS:  ${PASS_COUNT}${NC}"
echo -e "${RED}  FAIL:  ${FAIL_COUNT}${NC}"
echo -e "${YELLOW}  SKIP:  ${SKIP_COUNT}${NC}"
echo -e "${BLUE}  -------${NC}"
echo -e "${BLUE}  TOTAL: ${TOTAL_COUNT}${NC}"
echo ""
echo -e "${BLUE}  ${PASS_COUNT}/${CHECKED} controls passing at L${HTH_PROFILE_LEVEL}${NC}"
echo -e "${BLUE}================================================================${NC}"

# Exit with non-zero if any checks failed
if [ "${FAIL_COUNT}" -gt 0 ]; then
  exit 1
fi
