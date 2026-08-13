#!/usr/bin/env bash
# =============================================================================
# HTH Google Chat Control 2.7: Govern Third-Party Chat Archiving
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.3 | NIST 800-53 AC-4, AU-9, SI-4
# Guide: https://howtoharden.com/guides/google-chat/#27-govern-third-party-chat-archiving
#
# INTERFACE: Cloud Identity Policy API (read-only audit)
#   https://cloud.google.com/identity/docs/concepts/supported-policy-api-settings
#
# WHY THIS MATTERS: third-party archiving delivers Chat CONTENT to an email
# address on a schedule. Configured deliberately it is a compliance archive;
# configured by an attacker — or left pointed at a decommissioned vendor — it is
# a standing, sanctioned exfiltration channel that no DLP rule inspects, because
# the platform itself is doing the sending.
#
# READ-ONLY: "Mutate supported: No". Enforcement stays ClickOps.
# Requires: super administrator + domain-wide delegation
#   Scope: https://www.googleapis.com/auth/cloud-identity.policies.readonly
# =============================================================================
set -euo pipefail

# HTH Guide Excerpt: begin api-verify-third-party-archiving
# chat.third_party_archiving fields:
#   enabled                   boolean
#   destination_email_address string   <- the address Chat content is sent to
#   archival_frequency        Duration (documented range 1-24 hours)
#   custom headers            comma-separated string
#
# Set ARCHIVE_ALLOWED to the address your organization has actually approved.
ARCHIVE_ALLOWED="${ARCHIVE_ALLOWED:-}"

curl -s -G "https://cloudidentity.googleapis.com/v1/policies" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  --data-urlencode 'filter=setting.type.matches("chat.third_party_archiving")' \
  | ARCHIVE_ALLOWED="${ARCHIVE_ALLOWED}" python3 -c '
import json, os, sys
allowed = os.environ.get("ARCHIVE_ALLOWED", "").strip().lower()
fail = False
for p in json.load(sys.stdin).get("policies", []):
    v = p.get("setting", {}).get("value", {})
    ou = p.get("policyQuery", {}).get("orgUnit", "(customer default)")
    if not v.get("enabled"):
        print(f"orgUnit={ou} third-party archiving DISABLED")
        continue
    dest = (v.get("destination_email_address") or "").lower()
    print(f"orgUnit={ou} ENABLED -> {dest} every {v.get(\"archival_frequency\")}")
    if not allowed:
        print("  REVIEW: archiving is on and no approved destination was supplied")
        fail = True
    elif dest != allowed:
        print(f"  FINDING: Chat content is delivered to an UNAPPROVED address ({dest})")
        fail = True
sys.exit(1 if fail else 0)
'
# HTH Guide Excerpt: end api-verify-third-party-archiving
