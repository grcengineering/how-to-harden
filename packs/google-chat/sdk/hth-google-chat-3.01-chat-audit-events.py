#!/usr/bin/env python3
# HTH Google Chat Control 5.2: Google Chat Audit Logging & Content Reporting
# Profile: L1 | NIST: AU-2, AU-3, AU-6, IR-6 | SCuBA: GWS.CHAT.5.1v1, 5.2v1
# Requires: pip install google-api-python-client google-auth
#   Scope: https://www.googleapis.com/auth/admin.reports.audit.readonly

# HTH Guide Excerpt: begin sdk-chat-audit-events
# Pull Google Chat audit events from the Admin SDK Reports API
# (applicationName='chat'). Verified event names include: message_posted,
# attachment_upload, room_created, add_room_member, remove_room_member.
from googleapiclient.discovery import build

reports = build('admin', 'reports_v1', credentials=credentials)

# All Chat attachment uploads in the last 7 days (potential data exfiltration).
resp = reports.activities().list(
    userKey='all',
    applicationName='chat',
    eventName='attachment_upload',
    startTime='2026-05-20T00:00:00Z',
).execute()

for activity in resp.get('items', []):
    actor = activity['actor'].get('email', 'unknown')
    for event in activity.get('events', []):
        print(f"{activity['id']['time']}  {actor}  {event['name']}")
# HTH Guide Excerpt: end sdk-chat-audit-events
