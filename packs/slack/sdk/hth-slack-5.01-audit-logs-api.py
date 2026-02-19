# =============================================================================
# HTH Slack Control 5.1: Audit Logs API Integration
# Profile: L1 | NIST: AU-2, AU-3, AU-6
# =============================================================================

# HTH Guide Excerpt: begin sdk-audit-logs-api
import requests

headers = {
    'Authorization': f'Bearer {SLACK_AUDIT_TOKEN}',
    'Content-Type': 'application/json'
}

params = {
    'limit': 100,
    'action': 'user_login',
    'oldest': 1704067200
}

response = requests.get(
    'https://api.slack.com/audit/v1/logs',
    headers=headers,
    params=params
)

logs = response.json()
for entry in logs.get('entries', []):
    print(f"Action: {entry['action']}, User: {entry.get('actor', {}).get('user', {}).get('email')}")
# HTH Guide Excerpt: end sdk-audit-logs-api
