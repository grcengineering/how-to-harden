#!/usr/bin/env python3
# HTH CrowdStrike Control 4.1: Implement Staged Content Deployment
# Profile: L1 | NIST: CM-3
# https://howtoharden.com/guides/crowdstrike/#41-implement-staged-content-deployment

from datetime import datetime
from falconpy import Hosts

# HTH Guide Excerpt: begin monitor-canary-health
# Monitor for update-related issues
def monitor_canary_health(falcon):
    """Detect issues after content updates"""

    canary_group_id = "canary_group_id_here"

    # Get canary hosts
    hosts = falcon.command("QueryDevicesByFilterScroll",
                          filter=f"host_group.id:'{canary_group_id}'")

    issues = []
    for host in hosts['body']['resources']:
        # Check last seen time
        last_seen = datetime.fromisoformat(host['last_seen'])
        if (datetime.now() - last_seen).minutes > 15:
            issues.append(f"Canary host {host['hostname']} not reporting")

        # Check for crash events
        # (Would require Windows event log correlation)

    return issues
# HTH Guide Excerpt: end monitor-canary-health
