#!/usr/bin/env bash
# Control: 4.3 Route Egress Through Managed, Inspectable Proxies
# Profile Level: L3 (Run)
# Frameworks: NIST 800-53 SC-7/AC-4, CIS Controls v8 13, SOC 2 CC6.6
# Guide: https://howtoharden.com/guides/kernel/
# Interface: Kernel REST API — POST /proxies, POST /proxies/{id}/check
#   (docs: https://www.kernel.sh/docs/proxies/custom; OpenAPI: api.onkernel.com/spec.json)
set -euo pipefail

# HTH Guide Excerpt: begin create-inspecting-proxy
# Register your inspecting proxy. Credentials are WRITE-ONLY: responses
# report has_password: true but never return the value. A ca_bundle
# (PEM) marks a TLS-terminating proxy — Kernel validates the bundle and
# installs it in the browser trust store. CA-bundle proxies must be bound
# at browser creation; they cannot be hot-swapped onto a running browser.
curl -sS -X POST https://api.onkernel.com/proxies \
  -H "Authorization: Bearer ${KERNEL_API_KEY}" \
  -H "Content-Type: application/json" \
  -d @- << EOF
{
  "type": "custom",
  "name": "egress-inspection",
  "protocol": "https",
  "config": {
    "host": "proxy.internal.example.com",
    "port": 8443,
    "username": "kernel-fleet",
    "password": "${PROXY_PASSWORD}",
    "ca_bundle": "$(awk 'BEGIN{ORS="\\n"} {print}' ./inspection-ca.pem)"
  },
  "bypass_hosts": []
}
EOF
# Keep bypass_hosts EMPTY (or minimal and reviewed): every entry is
# egress your inspection layer never sees. Max 100 entries.
# HTH Guide Excerpt: end create-inspecting-proxy

# HTH Guide Excerpt: begin verify-proxy-health
# Health-check from the proxy's exit, optionally against a specific target.
curl -sS -X POST "https://api.onkernel.com/proxies/PROXY_ID/check" \
  -H "Authorization: Bearer ${KERNEL_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{ "url": "https://crm.example.com" }'
# HTH Guide Excerpt: end verify-proxy-health
