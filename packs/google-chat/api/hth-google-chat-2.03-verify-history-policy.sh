#!/usr/bin/env bash
# =============================================================================
# HTH Google Chat Control 2.3: Enforce Google Chat History & Retention
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 8.2/8.10 | NIST 800-53 AU-2, AU-9
# CISA SCuBA: GWS.CHAT.1.1v1, GWS.CHAT.1.2v1, GWS.CHAT.3.1v1
# Guide: https://howtoharden.com/guides/google-chat/#23-enforce-google-chat-history--retention
#
# INTERFACE: Cloud Identity Policy API (read-only audit)
#   https://cloud.google.com/identity/docs/concepts/supported-policy-api-settings
#
# READ-ONLY: history defaults are set in the Admin Console; this proves them.
# Requires: super administrator + domain-wide delegation
#   Scope: https://www.googleapis.com/auth/cloud-identity.policies.readonly
# =============================================================================
set -euo pipefail

# HTH Guide Excerpt: begin api-verify-history-policy
# Three SCuBA baselines are provable from two settings:
#   chat.chat_history   history_on_by_default (GWS.CHAT.1.1v1)
#                       allow_user_modification (GWS.CHAT.1.2v1 - must be false)
#   chat.space_history  history_state (GWS.CHAT.3.1v1)
#     DEFAULT_HISTORY_ON | DEFAULT_HISTORY_OFF | HISTORY_ALWAYS_ON |
#     HISTORY_ALWAYS_OFF | HISTORY_STATE_UNSPECIFIED
curl -s -G "https://cloudidentity.googleapis.com/v1/policies" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  --data-urlencode 'filter=setting.type.matches("chat.chat_history|chat.space_history")' \
  | python3 -c '
import json, sys
fail = False
for p in json.load(sys.stdin).get("policies", []):
    s = p.get("setting", {}); t = s.get("type", ""); v = s.get("value", {})
    ou = p.get("policyQuery", {}).get("orgUnit", "(customer default)")
    print(f"{t} orgUnit={ou} {v}")
    if t.endswith("chat_history"):
        if not v.get("history_on_by_default"):
            print("  SCuBA GWS.CHAT.1.1v1 FAIL: chat history not on by default"); fail = True
        if v.get("allow_user_modification"):
            print("  SCuBA GWS.CHAT.1.2v1 FAIL: users can change their history setting"); fail = True
    if t.endswith("space_history"):
        # ALWAYS_ON is the only state users cannot turn off per space.
        if v.get("history_state") != "HISTORY_ALWAYS_ON":
            print("  SCuBA GWS.CHAT.3.1v1 REVIEW: space history is not HISTORY_ALWAYS_ON"); fail = True
sys.exit(1 if fail else 0)
'
# HTH Guide Excerpt: end api-verify-history-policy
