#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: imanage-work-1.3
#   guide: https://howtoharden.com/guides/imanage-work/#13-verify-the-saml-metadata-matches-the-approved-cutover
#   profile: L1
#   mode: read-only
#   requires: bash, curl, python3, approved subdomain/customer ID and metadata digest
# Source (checked 2026-11-27): https://docs.imanage.com/cloud/cc-help/en-US/Network_Settings.html
# Review locally; protect evidence from unnecessary disclosure.

# HTH Guide Excerpt: begin imanage-work-evidence
set -euo pipefail
: "${HTH_IMANAGE_SUBDOMAIN:?Set the approved iManage custom subdomain.}"
: "${HTH_IMANAGE_CUSTOMER_ID:?Set the approved customer ID.}"
: "${HTH_IMANAGE_METADATA_DIGEST:?Set the independently approved metadata SHA-256.}"
[[ "$HTH_IMANAGE_SUBDOMAIN" =~ ^[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$ &&
   "$HTH_IMANAGE_CUSTOMER_ID" =~ ^[A-Za-z0-9_-]{1,64}$ &&
   "$HTH_IMANAGE_METADATA_DIGEST" =~ ^[0-9a-f]{64}$ ]] ||
  { printf 'Invalid iManage metadata inputs.\n' >&2; exit 2; }
curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --max-filesize 1048576 \
  "https://$HTH_IMANAGE_SUBDOMAIN.cloudimanage.com/auth/api/v1/saml/metadata/$HTH_IMANAGE_CUSTOMER_ID" |
  python3 -c '
import hashlib, json, sys, xml.etree.ElementTree as ET
limit = 1048576
raw = sys.stdin.buffer.read(limit + 1)
if not raw or len(raw) > limit or b"\x00" in raw or b"<!DOCTYPE" in raw or b"<!ENTITY" in raw:
    sys.exit("Metadata must be bounded UTF-8 XML with no DTD or entity declaration")
try:
    doc = ET.fromstring(raw.decode("utf-8-sig"))
except (ET.ParseError, UnicodeError):
    sys.exit("Invalid SAML metadata XML")
ns = "{urn:oasis:names:tc:SAML:2.0:metadata}"
if doc.tag != ns + "EntityDescriptor" or not doc.get("entityID") or doc.find(ns + "SPSSODescriptor") is None:
    sys.exit("Expected a single SAML service-provider entity descriptor")
matches = hashlib.sha256(raw).hexdigest() == sys.argv[1]
print(json.dumps({"matches_approved_metadata": matches}))
sys.exit(0 if matches else 1)
' "$HTH_IMANAGE_METADATA_DIGEST"
# HTH Guide Excerpt: end imanage-work-evidence
