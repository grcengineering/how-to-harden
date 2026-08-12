#!/usr/bin/env bash
# Control: 1.4 Audit and Remove Unused API Keys
# Profile Level: L2 (Hardened)
# Frameworks: NIST 800-53 AC-2, CIS Controls v8 5, SOC 2 CC6.2
# Guide: https://howtoharden.com/guides/kernel/
# Interface: Kernel REST API — GET/DELETE /org/api_keys (OpenAPI: api.onkernel.com/spec.json)
set -euo pipefail

# HTH Guide Excerpt: begin key-inventory
# List all keys for the organization. Responses are MASKED (masked_key),
# so this inventory is safe to archive with review records.
curl -sS "https://api.onkernel.com/org/api_keys" \
  -H "Authorization: Bearer ${KERNEL_ADMIN_KEY}" \
  -o api-key-inventory-$(date +%F).json

# Reconcile every key against a named owner/workload before deleting.
python3 -c "
import json
for k in json.load(open('api-key-inventory-$(date +%F).json')) or []:
    print(k.get('id'), '|', k.get('name'), '|', k.get('masked_key'), '|', k.get('expires_at'))
"
# HTH Guide Excerpt: end key-inventory

# HTH Guide Excerpt: begin delete-unowned-key
# Delete a key that no longer maps to a live workload.
# A key cannot delete itself: KERNEL_ADMIN_KEY must be a different key
# than the one being removed, so revocation can never be self-signed.
curl -sS -X DELETE "https://api.onkernel.com/org/api_keys/key_01jwv4tn5m8k3q2v7x9p0a1bc2" \
  -H "Authorization: Bearer ${KERNEL_ADMIN_KEY}"
# HTH Guide Excerpt: end delete-unowned-key
