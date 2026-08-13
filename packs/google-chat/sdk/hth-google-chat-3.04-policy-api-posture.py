#!/usr/bin/env python3
# =============================================================================
# HTH Google Chat Control 3.4: Continuously Verify Chat Configuration with the Policy API
# (whole-tenant Chat posture check — every Chat setting the Policy API exposes)
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 4.2/8.5 | NIST 800-53 CM-2, CM-3, CM-6, SI-4
# CISA SCuBA: GWS.CHAT.1.1v1, 1.2v1, 2.1v1, 3.1v1, 4.1v1
# Guide: https://howtoharden.com/guides/google-chat/#34-continuously-verify-chat-configuration-with-the-policy-api
#
# INTERFACE: Cloud Identity Policy API
#   https://cloud.google.com/identity/docs/concepts/supported-policy-api-settings
#
# SCOPE OF WHAT THIS CAN DO — read before using:
#   The Policy API is READ-ONLY for every Chat setting ("Mutate supported: No").
#   This script AUDITS the tenant against the guide's baseline; it never writes.
#   Enforcement of every setting below remains ClickOps in the Admin Console.
#
# Requires: pip install google-api-python-client google-auth
#   Super administrator; service account with domain-wide delegation
#   Scope: https://www.googleapis.com/auth/cloud-identity.policies.readonly
# =============================================================================

# HTH Guide Excerpt: begin sdk-policy-api-chat-posture
from googleapiclient.discovery import build

# Every Chat setting type the Policy API exposes, mapped to the guide control
# that owns it and the value this guide recommends.
BASELINE = {
    "chat.chat_apps_access": {
        "control": "1.1",
        "expect": {"enable_apps": False, "enable_webhooks": False},
    },
    "chat.external_chat_restriction": {
        "control": "2.1",
        "expect": {"external_chat_restriction": "TRUSTED_DOMAINS"},  # or allow_external_chat False
    },
    "chat.external_spaces": {
        "control": "2.1",
        "expect": {"domain_allowlist_mode": "TRUSTED_DOMAINS"},
    },
    "chat.chat_file_sharing": {
        "control": "2.2",
        "expect": {"external_file_sharing": "NO_FILES"},  # SCuBA GWS.CHAT.2.1v1
    },
    "chat.chat_history": {
        "control": "2.3",
        "expect": {"history_on_by_default": True, "allow_user_modification": False},
    },
    "chat.space_history": {
        "control": "2.3",
        "expect": {"history_state": "HISTORY_ALWAYS_ON"},
    },
    "chat.space_access_default": {
        "control": "2.6",
        "expect": {"access_type": "RESTRICTED"},
    },
    "chat.third_party_archiving": {
        "control": "2.7",
        "expect": {"enabled": False},  # any archiving destination must be reviewed
    },
}

service = build("cloudidentity", "v1", credentials=credentials)

# One call returns every Chat policy; filter syntax is `setting.type.matches(...)`.
policies = service.policies().list(
    filter='setting.type.matches("chat.*")'
).execute().get("policies", [])

findings = []
for policy in policies:
    setting = policy.get("setting", {})
    # Setting types come back namespaced, e.g. "settings/chat.chat_history".
    stype = setting.get("type", "").split("/")[-1]
    value = setting.get("value", {})
    spec = BASELINE.get(stype)
    if not spec:
        continue
    target = policy.get("policyQuery", {}).get("orgUnit") or "(customer default)"
    for field, want in spec["expect"].items():
        got = value.get(field)
        if got != want:
            findings.append(
                f"[{spec['control']}] {stype}.{field} = {got!r} (expected {want!r}) @ {target}"
            )

print(f"Chat policies read: {len(policies)}")
for f in findings:
    print("FINDING:", f)
print("PASS" if not findings else f"{len(findings)} finding(s)")
# HTH Guide Excerpt: end sdk-policy-api-chat-posture

# HTH Guide Excerpt: begin sdk-policy-api-enumerate
# Discovery aid: list every Chat policy the tenant actually returns, including
# settings this guide does not yet model. Run this after a Workspace release to
# spot new Chat settings before they drift.
for policy in policies:
    setting = policy.get("setting", {})
    print(setting.get("type"), "->", setting.get("value"))
# HTH Guide Excerpt: end sdk-policy-api-enumerate
