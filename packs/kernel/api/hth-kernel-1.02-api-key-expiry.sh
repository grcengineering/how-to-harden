#!/usr/bin/env bash
# Control: 1.2 Set Expiration on Every API Key
# Profile Level: L1 (Baseline)
# Frameworks: NIST 800-53 IA-5, CIS Controls v8 5, SOC 2 CC6.1
# Guide: https://howtoharden.com/guides/kernel/
# Interface: Kernel REST API — POST /org/api_keys (OpenAPI: api.onkernel.com/spec.json)
set -euo pipefail

# HTH Guide Excerpt: begin create-expiring-key
# days_to_expire: 1-3650; null means never — do not ship null.
# The plaintext key appears once in this response and never again;
# subsequent list/get calls return only masked_key.
curl -sS -X POST https://api.onkernel.com/org/api_keys \
  -H "Authorization: Bearer ${KERNEL_ADMIN_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "reporting-agent",
    "days_to_expire": 30,
    "project_id": "proj_production_a1b2"
  }'
# HTH Guide Excerpt: end create-expiring-key

# HTH Guide Excerpt: begin flag-non-expiring-keys
# Inventory check: list keys (masked) and flag any without an expiry.
curl -sS "https://api.onkernel.com/org/api_keys" \
  -H "Authorization: Bearer ${KERNEL_ADMIN_KEY}" |
  python3 -c "
import json, sys
keys = json.load(sys.stdin)
items = keys if isinstance(keys, list) else keys.get('items', keys.get('data', []))
for k in items:
    if not k.get('expires_at'):
        print('NO EXPIRY:', k.get('id'), k.get('name'))
"
# HTH Guide Excerpt: end flag-non-expiring-keys
