#!/usr/bin/env bash
# HTH Mimecast Control 1.1: Verify MX Record Configuration
# Profile: L1 | NIST: SC-7
# https://howtoharden.com/guides/mimecast/#11-verify-mx-record-configuration

# HTH Guide Excerpt: begin cli-verify-mx-records
# Verify MX records
nslookup -type=MX yourdomain.com

# Expected: Mimecast servers at highest priority (lowest number)
# Example:
# yourdomain.com MX preference = 10, mail exchanger = xx-smtp-inbound-1.mimecast.com
# HTH Guide Excerpt: end cli-verify-mx-records
