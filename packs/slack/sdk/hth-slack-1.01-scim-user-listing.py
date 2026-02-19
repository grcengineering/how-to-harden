# =============================================================================
# HTH Slack Control 1.1: SCIM User Provisioning Check
# Profile: L1 | NIST: IA-2, IA-8
# =============================================================================

# HTH Guide Excerpt: begin sdk-scim-user-listing
import requests

headers = {
    'Authorization': f'Bearer {SLACK_ADMIN_TOKEN}',
    'Content-Type': 'application/json'
}

# List users via SCIM
response = requests.get(
    'https://api.slack.com/scim/v1/Users',
    headers=headers
)

users = response.json()
for user in users.get('Resources', []):
    print(f"User: {user['userName']}, Active: {user['active']}")
# HTH Guide Excerpt: end sdk-scim-user-listing
