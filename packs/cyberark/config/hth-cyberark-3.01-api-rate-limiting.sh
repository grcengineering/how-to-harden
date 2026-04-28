#!/usr/bin/env bash
# HTH CyberArk Control 3.1: Secure API Authentication — Rate Limiting
# Profile: L1 | NIST: IA-5, SC-8
# https://howtoharden.com/guides/cyberark/#31-secure-api-authentication
#
# CyberArk PVWA consumes PVConfiguration.xml natively. This script emits
# the hardened web-service rate-limiting block. Apply on the PVWA host.

set -euo pipefail

PVCONFIG_PATH="${PVCONFIG_PATH:-/CYBR/PVWA/Conf/PVConfiguration.xml}"

# HTH Guide Excerpt: begin config-api-rate-limiting
cat > "${PVCONFIG_PATH}.webservice.snippet.xml" <<'XML'
<WebService>
  <MaxConcurrentRequests>50</MaxConcurrentRequests>
  <RequestTimeoutSeconds>120</RequestTimeoutSeconds>
  <EnableRateLimiting>true</EnableRateLimiting>
</WebService>
XML
# HTH Guide Excerpt: end config-api-rate-limiting

echo "Wrote PVWA web-service hardening snippet."
echo "Merge the <WebService> block into ${PVCONFIG_PATH} and restart PVWA."
