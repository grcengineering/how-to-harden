#!/usr/bin/env python3
# HTH Google Workspace Control 3.01: List OAuth Tokens
# Profile: L1 | NIST: AC-3, CM-7
# Requires: pip install google-api-python-client google-auth

# HTH Guide Excerpt: begin sdk-list-oauth-tokens
# List OAuth tokens for a user
from googleapiclient.discovery import build

service = build('admin', 'directory_v1', credentials=credentials)

tokens = service.tokens().list(userKey='user@domain.com').execute()

for token in tokens.get('items', []):
    print(f"App: {token['displayText']}")
    print(f"Client ID: {token['clientId']}")
    print(f"Scopes: {token['scopes']}")
    print("---")
# HTH Guide Excerpt: end sdk-list-oauth-tokens
