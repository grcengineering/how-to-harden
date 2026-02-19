#!/usr/bin/env python3
# HTH BeyondTrust Control 2.01: API Key Management and Rotation
# Profile: L1 | NIST: IA-5, SC-12
# https://howtoharden.com/guides/beyondtrust/#21-api-key-management-and-rotation
# Requires: pip install requests

# HTH Guide Excerpt: begin sdk-api-key-rotation
import requests
import json
from datetime import datetime, timedelta

BEYONDTRUST_HOST = "https://beyondtrust.company.com"

def rotate_api_key(admin_token, key_id, key_name, allowed_ips):
    """Rotate an API key and return new credentials"""

    # Create new key
    response = requests.post(
        f"{BEYONDTRUST_HOST}/api/config/api-keys",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "name": f"{key_name}-{datetime.now().strftime('%Y%m%d')}",
            "allowedIps": allowed_ips,
            "expiresAt": (datetime.now() + timedelta(days=90)).isoformat()
        }
    )
    new_key = response.json()

    # Store new key securely (e.g., Vault)
    store_in_vault(key_name, new_key['apiKey'])

    # Revoke old key
    requests.delete(
        f"{BEYONDTRUST_HOST}/api/config/api-keys/{key_id}",
        headers={"Authorization": f"Bearer {admin_token}"}
    )

    return new_key

def audit_api_keys(admin_token):
    """Audit all API keys for compliance"""
    response = requests.get(
        f"{BEYONDTRUST_HOST}/api/config/api-keys",
        headers={"Authorization": f"Bearer {admin_token}"}
    )

    keys = response.json()
    issues = []

    for key in keys:
        # Check age
        created = datetime.fromisoformat(key['createdAt'])
        age_days = (datetime.now() - created).days
        if age_days > 90:
            issues.append(f"Key '{key['name']}' is {age_days} days old (max 90)")

        # Check IP restrictions
        if not key.get('allowedIps'):
            issues.append(f"Key '{key['name']}' has no IP restrictions")

        # Check last usage
        if not key.get('lastUsed'):
            issues.append(f"Key '{key['name']}' has never been used - consider removal")

    return issues
# HTH Guide Excerpt: end sdk-api-key-rotation
