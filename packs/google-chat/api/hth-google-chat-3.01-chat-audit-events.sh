#!/usr/bin/env bash
# =============================================================================
# HTH Google Chat Control 3.1: Enable Google Chat Audit Logging & Content Reporting
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 8.2/8.5 | NIST 800-53 AU-2, AU-3, AU-6, IR-6
# CISA SCuBA: GWS.CHAT.5.1v1, GWS.CHAT.5.2v1
# Guide: https://howtoharden.com/guides/google-chat/#31-enable-google-chat-audit-logging--content-reporting
#
# INTERFACE: Admin SDK Reports API — the FIRST-PARTY, officially supported path.
#   https://developers.google.com/workspace/admin/reports/v1/appendix/activity/chat
#
#   A CLI-driven variant of this control ships in the `cli/` pack using Google's
#   own `gws` CLI. GAM is deliberately NOT used: it is community-maintained, not
#   vendor-published (see docs/research/cli-inventory.md).
#
# Requires: Audit & Investigation admin privilege
#   Scope: https://www.googleapis.com/auth/admin.reports.audit.readonly
# =============================================================================
set -euo pipefail

BASE="https://admin.googleapis.com/admin/reports/v1/activity/users/all/applications/chat"

# HTH Guide Excerpt: begin api-chat-audit-events
# Attachment uploads — data moving INTO Chat.
curl -s -G "${BASE}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  --data-urlencode "eventName=attachment_upload" \
  --data-urlencode "startTime=$(date -u -v-7d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '7 days ago' '+%Y-%m-%dT%H:%M:%SZ')"

# Attachment downloads — data moving OUT. A compromised account harvesting an
# existing space generates downloads without ever uploading anything.
curl -s -G "${BASE}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  --data-urlencode "eventName=attachment_download"

# Space lifecycle and membership growth (rogue or external spaces).
for EV in room_created add_room_member; do
  curl -s -G "${BASE}" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    --data-urlencode "eventName=${EV}"
done
# HTH Guide Excerpt: end api-chat-audit-events

# HTH Guide Excerpt: begin api-chat-report-queue
# Content-reporting queue health. `message_reported` and `message_report_resolved`
# both carry a `report_id` parameter, so raised-versus-resolved is measurable —
# which is what proves the queue in control 3.3 has a working owner.
curl -s -G "${BASE}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  --data-urlencode "eventName=message_reported" \
  | python3 -c '
import json, sys
items = json.load(sys.stdin).get("items", [])
print(f"messages reported: {len(items)}")
for a in items:
    actor = a.get("actor", {}).get("email", "unknown")
    print(f"  {a[\"id\"][\"time\"]}  {actor}")
'

curl -s -G "${BASE}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  --data-urlencode "eventName=message_report_resolved"
# HTH Guide Excerpt: end api-chat-report-queue

# HTH Guide Excerpt: begin api-chat-evidence-tampering
# Deletion and editing of content that history was meant to preserve
# (MITRE ATT&CK T1562.001, Impair Defenses).
for EV in message_deleted message_edited room_deleted; do
  curl -s -G "${BASE}" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    --data-urlencode "eventName=${EV}"
done
# HTH Guide Excerpt: end api-chat-evidence-tampering
