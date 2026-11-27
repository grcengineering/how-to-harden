#!/usr/bin/env python3
# HTH Pack Contract: v1
#   control: cisco-meraki-1.1
#   guide: https://howtoharden.com/guides/cisco-meraki/
#   profile: L1
#   mode: read-only
#   requires: Python and the authorized official Meraki SDK
# HTH Cisco Meraki 1.1: Verify direct Dashboard two-factor policy.
# Profile: L1 (Crawl); NIST SP 800-53 Rev. 5 IA-2, IA-5.
# Guide: https://howtoharden.com/guides/cisco-meraki/
# Install Cisco's Dashboard API Python library in an isolated environment.
# HTH Guide Excerpt: begin audit-two-factor-sdk
import json
import os
import re

import meraki


def main():
    """Report the configured organization policy, not individual enrollment."""
    org = os.environ.get("MERAKI_ORG_ID", "")
    if not re.fullmatch(r"[0-9]+", org):
        raise SystemExit("MERAKI_ORG_ID must be numeric.")
    token = os.environ.get("MERAKI_DASHBOARD_API_KEY")
    if not token:
        raise SystemExit("Provide MERAKI_DASHBOARD_API_KEY via a secret manager.")
    dashboard = meraki.DashboardAPI(
        api_key=token,
        output_log=False,
        print_console=False,
        maximum_retries=0,
    )
    policy = dashboard.organizations.getOrganizationLoginSecurity(org)
    enabled = policy.get("enforceTwoFactorAuth") if isinstance(policy, dict) else None
    if not isinstance(enabled, bool):
        raise SystemExit("Missing expected Dashboard policy field.")
    print(json.dumps({"enforceTwoFactorAuth": enabled}))


if __name__ == "__main__":
    main()
# HTH Guide Excerpt: end audit-two-factor-sdk
