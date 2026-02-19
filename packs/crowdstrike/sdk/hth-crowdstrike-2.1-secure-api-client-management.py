#!/usr/bin/env python3
# HTH CrowdStrike Control 2.1: Secure API Client Management
# Profile: L1 | NIST: IA-5, SC-8
# https://howtoharden.com/guides/crowdstrike/#21-secure-api-client-management

import os
from datetime import datetime
from falconpy import APIHarness

# HTH Guide Excerpt: begin audit-api-clients
def audit_api_clients():
    """Audit all API clients for over-privileged access"""

    falcon = APIHarness(
        client_id=os.environ['CS_CLIENT_ID'],
        client_secret=os.environ['CS_CLIENT_SECRET']
    )

    # Get API clients (requires appropriate scope)
    response = falcon.command("QueryAPIClients")

    issues = []
    for client in response['body']['resources']:
        # Check for overly broad scopes
        scopes = client.get('scopes', [])

        dangerous_scopes = ['hosts:write', 'sensor-update-policies:write',
                           'prevention-policies:write', 'user-management:write']

        for scope in dangerous_scopes:
            if scope in scopes:
                issues.append(f"Client '{client['name']}' has dangerous scope: {scope}")

        # Check creation date
        created = datetime.fromisoformat(client['created_timestamp'])
        age_days = (datetime.now() - created).days
        if age_days > 90:
            issues.append(f"Client '{client['name']}' is {age_days} days old")

    return issues
# HTH Guide Excerpt: end audit-api-clients
