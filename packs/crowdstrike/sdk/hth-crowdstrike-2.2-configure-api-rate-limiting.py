#!/usr/bin/env python3
# HTH CrowdStrike Control 2.2: Configure API Rate Limiting
# Profile: L2 | NIST: SC-5
# https://howtoharden.com/guides/crowdstrike/#22-configure-api-rate-limiting

# HTH Guide Excerpt: begin detect-api-anomalies
# Monitor for unusual API activity
def detect_api_anomalies(falcon):
    """Detect unusual API usage patterns"""

    # Check for bulk host queries
    response = falcon.command("audit_events",
                             filter="service_name:'hosts' + action:'query'")

    events = response['body']['resources']

    # Group by client
    client_counts = {}
    for event in events:
        client = event.get('audit_key_values', {}).get('client_id', 'unknown')
        client_counts[client] = client_counts.get(client, 0) + 1

    # Alert on high-volume clients
    for client, count in client_counts.items():
        if count > 1000:
            alert(f"High API volume from {client}: {count} requests")
# HTH Guide Excerpt: end detect-api-anomalies
