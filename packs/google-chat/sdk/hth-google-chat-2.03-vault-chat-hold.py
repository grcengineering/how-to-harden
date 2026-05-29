#!/usr/bin/env python3
# HTH Google Chat Control 4.5: Enforce Google Chat History & Retention
# Profile: L2 | NIST: AU-2, AU-9, SC-7(10) | SCuBA: GWS.CHAT.1.1v1, 1.2v1, 3.1v1
#
# History defaults ("History for chats" = ON, "History for spaces" = ALWAYS ON,
# and unchecking "Allow users to change their history setting") are Admin Console
# settings with no public API -- configure them via ClickOps.
#
# Long-term preservation IS automatable: the Vault API places Chat content on a
# legal hold so it cannot be purged by users or retention rules. The Chat corpus
# in the Vault API is "HANGOUTS_CHAT"; set includeRooms to also hold space messages.
# Requires: pip install google-api-python-client google-auth
#   Scope: https://www.googleapis.com/auth/ediscovery

# HTH Guide Excerpt: begin sdk-vault-chat-hold
from googleapiclient.discovery import build

vault = build('vault', 'v1', credentials=credentials)

# 1. Create a matter to own the hold (or reuse an existing matterId).
matter = vault.matters().create(body={
    'name': 'HTH Chat Retention',
    'description': 'HTH 4.5 -- preserves Google Chat content for legal/compliance hold',
}).execute()
matter_id = matter['matterId']

# 2. Place an org unit on hold for the Chat corpus, including space (room) messages.
hold = vault.matters().holds().create(matterId=matter_id, body={
    'name': 'HTH Chat Hold',
    'corpus': 'HANGOUTS_CHAT',
    'orgUnit': {'orgUnitId': 'id:03ph8a2z1example'},  # Admin SDK org unit ID
    'query': {'hangoutsChatQuery': {'includeRooms': True}},
}).execute()

print(f"Created Chat hold {hold['holdId']} on matter {matter_id}")
# HTH Guide Excerpt: end sdk-vault-chat-hold
