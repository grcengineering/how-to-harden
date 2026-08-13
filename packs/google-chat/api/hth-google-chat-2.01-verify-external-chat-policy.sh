#!/usr/bin/env bash
# =============================================================================
# HTH Google Chat Control 2.1: Restrict External Google Chat & Spaces
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 3.3 | NIST 800-53 AC-3, AC-20 | CISA SCuBA GWS.CHAT.4.1v1
# Guide: https://howtoharden.com/guides/google-chat/#21-restrict-external-google-chat--spaces
#
# INTERFACE: Cloud Identity Policy API (read-only audit)
#   https://cloud.google.com/identity/docs/concepts/supported-policy-api-settings
#
# READ-ONLY: "Mutate supported: No" for all Chat settings. This verifies the
# SCuBA baseline rather than enforcing it; enforcement stays ClickOps.
#
# Requires: super administrator + domain-wide delegation
#   Scope: https://www.googleapis.com/auth/cloud-identity.policies.readonly
# =============================================================================
set -euo pipefail

# HTH Guide Excerpt: begin api-verify-external-chat-policy
# Two distinct settings govern the external surface. Audit BOTH — restricting
# 1:1 external chat while leaving external spaces open leaves the larger hole.
#
#   chat.external_chat_restriction
#     allow_external_chat        boolean
#     external_chat_restriction  NO_RESTRICTION | TRUSTED_DOMAINS | RESTRICTION_UNSPECIFIED
#   chat.external_spaces
#     enabled                    boolean
#     domain_allowlist_mode      TRUSTED_DOMAINS | ALL_DOMAINS | DOMAIN_ALLOWLIST_MODE_UNSPECIFIED
curl -s -G "https://cloudidentity.googleapis.com/v1/policies" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  --data-urlencode 'filter=setting.type.matches("chat.external_chat_restriction|chat.external_spaces")' \
  | python3 -c '
import json, sys
FAIL = False
for p in json.load(sys.stdin).get("policies", []):
    s = p.get("setting", {}); t = s.get("type", ""); v = s.get("value", {})
    print(t, v)
    # SCuBA GWS.CHAT.4.1v1: external chat off, or restricted to trusted domains.
    if t.endswith("external_chat_restriction"):
        if v.get("allow_external_chat") and v.get("external_chat_restriction") != "TRUSTED_DOMAINS":
            print("  SCuBA GWS.CHAT.4.1v1 FAIL: external chat unrestricted"); FAIL = True
    if t.endswith("external_spaces"):
        if v.get("enabled") and v.get("domain_allowlist_mode") == "ALL_DOMAINS":
            print("  FINDING: external spaces + group DMs open to ALL domains"); FAIL = True
sys.exit(1 if FAIL else 0)
'
# HTH Guide Excerpt: end api-verify-external-chat-policy
