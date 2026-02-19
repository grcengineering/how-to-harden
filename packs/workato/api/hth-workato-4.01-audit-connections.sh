#!/usr/bin/env bash
# HTH Workato Control 4.01: Secure Connection Credentials
# Profile: L1 | NIST: SC-12, IA-5
# https://howtoharden.com/guides/workato/#41-secure-connection-credentials

# HTH Guide Excerpt: begin api-list-connections
# List all connections with their status
curl -s "https://www.workato.com/api/connections" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, name, provider, connected: .authorized}'
# HTH Guide Excerpt: end api-list-connections

# HTH Guide Excerpt: begin api-list-folder-connections
# List connections in a specific folder/project
curl -s "https://www.workato.com/api/connections?folder_id=FOLDER_ID" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, name, provider}'
# HTH Guide Excerpt: end api-list-folder-connections
