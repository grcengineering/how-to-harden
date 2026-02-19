# =============================================================================
# HTH Slack Control 3.1: Audit Approved and Restricted Apps
# Profile: L1 | NIST: AC-3, CM-7
# =============================================================================

# HTH Guide Excerpt: begin api-audit-approved-apps
import requests

headers = {
    'Authorization': f'Bearer {SLACK_ADMIN_TOKEN}',
    'Content-Type': 'application/json'
}

# List approved apps
response = requests.get(
    'https://slack.com/api/admin.apps.approved.list',
    headers=headers
)

approved_apps = response.json()
for app in approved_apps.get('approved_apps', []):
    print(f"App: {app['name']}, Scopes: {app.get('scopes', [])}")

# List restricted apps
response = requests.get(
    'https://slack.com/api/admin.apps.restricted.list',
    headers=headers
)
# HTH Guide Excerpt: end api-audit-approved-apps
