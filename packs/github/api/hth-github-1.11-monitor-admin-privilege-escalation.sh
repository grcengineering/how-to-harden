#!/usr/bin/env bash
# HTH GitHub Control 1.11: Monitor Admin Privilege Escalation
# Profile: L1 | NIST: AC-6(1)
# https://howtoharden.com/guides/github/#14-configure-admin-access-controls
source "$(dirname "$0")/common.sh"

banner "1.11: Monitor Admin Privilege Escalation"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.11 Monitoring admin privilege escalation for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-monitor-privilege-escalation
# Monitor for privilege escalation
gh api /orgs/{org}/audit-log?phrase=action:org.update_member_role \
  --jq '.[] | select(.role == "admin") | {actor: .actor, user: .user, created_at: .created_at}'
# HTH Guide Excerpt: end api-monitor-privilege-escalation

increment_applied
summary
