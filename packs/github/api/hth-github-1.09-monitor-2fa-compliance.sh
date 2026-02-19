#!/usr/bin/env bash
# HTH GitHub Control 1.09: Monitor 2FA Compliance
# Profile: L1 | NIST: IA-2(1), IA-2(2)
# https://howtoharden.com/guides/github/#11-enforce-multi-factor-authentication-mfa-for-all-organization-members
source "$(dirname "$0")/common.sh"

banner "1.09: Monitor 2FA Compliance"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.09 Monitoring 2FA compliance for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-monitor-2fa-compliance
# Daily check for non-compliant members
gh api /orgs/{org}/members?filter=2fa_disabled --jq 'length'
# Expected: 0
# If > 0, alert security team
# HTH Guide Excerpt: end api-monitor-2fa-compliance

increment_applied
summary
