#!/usr/bin/env bash
# HTH BeyondTrust Control 6.02: Vulnerability Management
# Profile: L1 | NIST: SI-2, RA-5
# https://howtoharden.com/guides/beyondtrust/#62-vulnerability-management

# HTH Guide Excerpt: begin api-check-version
# Check current version
curl -s "https://${BEYONDTRUST_HOST}/api/system/version" \
  -H "Authorization: Bearer ${API_TOKEN}"

# Verify patches applied
# Compare version against BeyondTrust security advisories
# HTH Guide Excerpt: end api-check-version
