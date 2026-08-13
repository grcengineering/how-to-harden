#!/usr/bin/env bash
# =============================================================================
# HTH Google Chat Control 2.2: Restrict Google Chat File Sharing
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.3 | NIST 800-53 AC-3 | CISA SCuBA GWS.CHAT.2.1v1
# Guide: https://howtoharden.com/guides/google-chat/#22-restrict-google-chat-file-sharing
#
# INTERFACE: Cloud Identity Policy API (read-only audit)
#   https://cloud.google.com/identity/docs/concepts/supported-policy-api-settings
#
# READ-ONLY: enforcement of the file-sharing dropdowns stays ClickOps.
# Requires: super administrator + domain-wide delegation
#   Scope: https://www.googleapis.com/auth/cloud-identity.policies.readonly
# =============================================================================
set -euo pipefail

# HTH Guide Excerpt: begin api-verify-filesharing-policy
# chat.chat_file_sharing exposes both dropdowns as enums:
#   external_file_sharing / internal_file_sharing
#     ALL_FILES | IMAGES_ONLY | NO_FILES | FILE_SHARING_OPTION_UNSPECIFIED
# SCuBA GWS.CHAT.2.1v1 requires external_file_sharing = NO_FILES.
curl -s -G "https://cloudidentity.googleapis.com/v1/policies" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  --data-urlencode 'filter=setting.type.matches("chat.chat_file_sharing")' \
  | python3 -c '
import json, sys
fail = False
for p in json.load(sys.stdin).get("policies", []):
    v = p.get("setting", {}).get("value", {})
    ou = p.get("policyQuery", {}).get("orgUnit", "(customer default)")
    ext, internal = v.get("external_file_sharing"), v.get("internal_file_sharing")
    print(f"orgUnit={ou} external={ext} internal={internal}")
    if ext != "NO_FILES":
        print("  SCuBA GWS.CHAT.2.1v1 FAIL: external Chat file sharing is not NO_FILES")
        fail = True
sys.exit(1 if fail else 0)
'
# HTH Guide Excerpt: end api-verify-filesharing-policy
