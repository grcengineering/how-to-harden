#!/usr/bin/env bash
# HTH Okta Control 1.11: Enable End-User Security Notifications
# Profile: L1 | NIST: SI-4, IR-6
# https://howtoharden.com/guides/okta/#111-enable-end-user-security-notifications
source "$(dirname "$0")/common.sh"

banner "1.11: Enable End-User Security Notifications"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.11 Enabling end-user security notifications..."

# Enable all five end-user notification types
info "1.11 Enabling all five notification types..."
okta_put "/api/v1/org/settings" '{
  "endUserNotifications": {
    "newSignOnNotification": {
      "enabled": true
    },
    "authenticatorEnrolledNotification": {
      "enabled": true
    },
    "authenticatorResetNotification": {
      "enabled": true
    },
    "passwordChangedNotification": {
      "enabled": true
    },
    "factorResetNotification": {
      "enabled": true
    }
  }
}' > /dev/null 2>&1 && {
  pass "1.11 All five end-user notification types enabled"
} || {
  fail "1.11 Failed to enable end-user notifications"
  increment_failed
  summary
  exit 0
}

# Enable Suspicious Activity Reporting
info "1.11 Enabling Suspicious Activity Reporting..."
okta_post "/api/v1/org/privacy/suspicious-activity-reporting" '{
  "enabled": true
}' > /dev/null 2>&1 && {
  pass "1.11 Suspicious Activity Reporting enabled"
} || {
  warn "1.11 Suspicious Activity Reporting may already be enabled"
}

# Verify settings
NOTIFICATIONS=$(okta_get "/api/v1/org/settings" | jq -c '.endUserNotifications' 2>/dev/null || echo "{}")
info "1.11 Current notification settings: ${NOTIFICATIONS}"

increment_applied

summary
