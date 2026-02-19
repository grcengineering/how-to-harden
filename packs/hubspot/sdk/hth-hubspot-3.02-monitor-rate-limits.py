#!/usr/bin/env python3
# HTH HubSpot Control 3.2: Configure API Rate Limiting Awareness
# Profile: L1
# https://howtoharden.com/guides/hubspot/#32-configure-api-rate-limiting-awareness

# HTH Guide Excerpt: begin sdk-monitor-rate-limits
# Monitor rate limit headers
response = requests.get(url, headers=headers)
remaining = response.headers.get('X-HubSpot-RateLimit-Remaining')
daily_remaining = response.headers.get('X-HubSpot-RateLimit-Daily-Remaining')
# HTH Guide Excerpt: end sdk-monitor-rate-limits
