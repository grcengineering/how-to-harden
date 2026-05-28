#!/usr/bin/env bash
# HTH Google Workspace Control 5.2: Google Chat Audit Logging & Content Reporting
# Profile: L1 | NIST: AU-2, AU-3, AU-6, IR-6 | SCuBA: GWS.CHAT.5.1v1, 5.2v1
#
# TOOL STATUS NOTE (2026-04):
#   GAM is a COMMUNITY-MAINTAINED CLI, NOT a first-party Google product.
#   The first-party equivalent is the Admin SDK Reports API
#   (admin.googleapis.com/admin/reports/v1/activity/users/all/applications/chat).
# Requires: GAM (https://github.com/GAM-team/GAM)

# HTH Guide Excerpt: begin cli-chat-audit
# Generate a Google Chat audit report for the last 7 days
gam report chat start -7d end today

# Filter to attachment uploads (potential data exfiltration via Chat)
gam report chat start -7d end today event attachment_upload

# Filter to space creation and external membership changes
gam report chat start -7d end today event room_created
gam report chat start -7d end today event add_room_member

# First-party alternative: Admin SDK Reports API via curl + OAuth bearer token
curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  "https://admin.googleapis.com/admin/reports/v1/activity/users/all/applications/chat?eventName=attachment_upload"
# HTH Guide Excerpt: end cli-chat-audit
