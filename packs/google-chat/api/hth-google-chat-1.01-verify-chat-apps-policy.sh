#!/usr/bin/env bash
# =============================================================================
# HTH Google Chat Control 1.1: Restrict & Allowlist Google Chat Apps
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 2.5/2.7 | NIST 800-53 AC-3, CM-7
# Guide: https://howtoharden.com/guides/google-chat/#11-restrict--allowlist-google-chat-apps
#
# INTERFACE: Cloud Identity Policy API (read-only audit of Chat settings)
#   https://cloud.google.com/identity/docs/concepts/supported-policy-api-settings
#   https://cloud.google.com/identity/docs/how-to/list-get-policies
#
# WHAT THIS CAN AND CANNOT DO — read before using:
#   The Policy API is READ-ONLY for every Chat setting ("Mutate supported: No").
#   It VERIFIES the console configuration; it cannot set it. Enforcement of Chat
#   app + webhook restrictions remains ClickOps in the Admin Console.
#
# Requires: super administrator; a service account with domain-wide delegation
#   Scope: https://www.googleapis.com/auth/cloud-identity.policies.readonly
# =============================================================================
set -euo pipefail

# HTH Guide Excerpt: begin api-verify-chat-apps-policy
# Read the live Chat app/webhook policy for the customer. The setting type is
# `chat.chat_apps_access`, with two boolean fields:
#   enable_apps     -> "Allow users to install Chat apps"
#   enable_webhooks -> "Allow users to add and use incoming webhooks"
curl -s -G "https://cloudidentity.googleapis.com/v1/policies" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  --data-urlencode 'filter=setting.type.matches("chat.chat_apps_access")' \
  | python3 -c '
import json, sys
for p in json.load(sys.stdin).get("policies", []):
    v = p.get("setting", {}).get("value", {})
    target = p.get("policyQuery", {}).get("orgUnit", "(customer default)")
    apps, hooks = v.get("enable_apps"), v.get("enable_webhooks")
    print(f"orgUnit={target} enable_apps={apps} enable_webhooks={hooks}")
    if apps:  print("  FINDING: users may install Chat apps - require a Marketplace allowlist")
    if hooks: print("  FINDING: incoming webhooks enabled - scope to an audited OU only")
'
# HTH Guide Excerpt: end api-verify-chat-apps-policy
