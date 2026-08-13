#!/usr/bin/env bash
# =============================================================================
# HTH Google Chat Control 3.1: Enable Google Chat Audit Logging & Content Reporting
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 8.2/8.5 | NIST 800-53 AU-2, AU-6, IR-6
# CISA SCuBA: GWS.CHAT.5.1v1, GWS.CHAT.5.2v1
# Guide: https://howtoharden.com/guides/google-chat/#31-enable-google-chat-audit-logging--content-reporting
#
# INTERFACE: `gws` — the Google Workspace CLI (github.com/googleworkspace/cli)
#
# TOOL STATUS — read this before adopting:
#   `gws` is published by Google in the googleworkspace GitHub org, but its own
#   README states verbatim: "This is not an officially supported Google product."
#   It is pre-1.0 and expects breaking changes. It is used here in preference to
#   GAM, which is community-maintained rather than vendor-published at all.
#   For a fully supported path, call the Admin SDK Reports API directly (see the
#   API pack for this control).
#
# Install:  npm install -g @googleworkspace/cli   OR   brew install googleworkspace-cli
# Auth:     gws auth login          (interactive OAuth)
#           export GOOGLE_APPLICATION_CREDENTIALS=/path/key.json   (service account)
# Syntax:   gws <service> <resource> [sub-resource] <method> [flags]
# Introspect a method before calling it:  gws schema admin-reports.activities.list
# =============================================================================
set -euo pipefail

# HTH Guide Excerpt: begin cli-gws-chat-audit-events
# All Chat activity for the customer. `--params` carries query parameters as
# JSON; `--page-all` auto-paginates and emits NDJSON.
gws admin-reports activities list \
  --params '{"userKey":"all","applicationName":"chat"}' \
  --page-all --format json

# Attachment uploads only — the Chat data-exfiltration signal.
gws admin-reports activities list \
  --params '{"userKey":"all","applicationName":"chat","eventName":"attachment_upload"}' \
  --page-all --format json

# Rogue/external space activity: creation and membership growth.
gws admin-reports activities list \
  --params '{"userKey":"all","applicationName":"chat","eventName":"room_created"}' \
  --format json

gws admin-reports activities list \
  --params '{"userKey":"all","applicationName":"chat","eventName":"add_room_member"}' \
  --format json
# HTH Guide Excerpt: end cli-gws-chat-audit-events

# HTH Guide Excerpt: begin cli-gws-chat-audit-window
# Bound the window for a scheduled review. startTime/endTime are RFC 3339.
# --dry-run validates the call locally without hitting the API.
WINDOW_START="$(date -u -v-7d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '7 days ago' '+%Y-%m-%dT%H:%M:%SZ')"

gws admin-reports activities list \
  --params "{\"userKey\":\"all\",\"applicationName\":\"chat\",\"startTime\":\"${WINDOW_START}\"}" \
  --page-all --page-limit 50 --format json \
  > "chat-audit-$(date -u '+%Y-%m-%d').ndjson"
# HTH Guide Excerpt: end cli-gws-chat-audit-window
