#!/usr/bin/env bash
# HTH GitHub Control 5.10: Configure Repository Custom Properties
# Profile: L2 | NIST: RA-2, SC-16, CM-8
# https://howtoharden.com/guides/github/#56-configure-repository-custom-properties-for-security-classification
source "$(dirname "$0")/common.sh"

banner "5.10: Configure Repository Custom Properties"
should_apply 2 || { increment_skipped; summary; exit 0; }

info "5.10 Checking custom properties in ${GITHUB_ORG}..."

PROPERTIES=$(gh_get "/orgs/${GITHUB_ORG}/properties/schema") || {
  fail "5.10 Unable to retrieve custom properties schema"
  increment_failed
  summary
  exit 0
}

PROP_COUNT=$(echo "${PROPERTIES}" | jq '. | length')
if [ "${PROP_COUNT}" -gt "0" ]; then
  pass "5.10 Custom properties defined (${PROP_COUNT} found)"
  echo "${PROPERTIES}" | jq '.[] | {property_name, value_type, required}'
fi

# HTH Guide Excerpt: begin api-create-custom-properties
# Create security classification custom properties for the organization
gh api --method POST \
  "/orgs/${GITHUB_ORG}/properties/schema" \
  --input - <<'JSON'
[
  {
    "property_name": "security-tier",
    "value_type": "single_select",
    "required": true,
    "default_value": "standard",
    "description": "Security classification tier",
    "allowed_values": ["critical", "high", "standard", "low"]
  },
  {
    "property_name": "data-classification",
    "value_type": "single_select",
    "required": true,
    "default_value": "internal",
    "description": "Data classification level",
    "allowed_values": ["public", "internal", "confidential", "restricted"]
  },
  {
    "property_name": "compliance-scope",
    "value_type": "multi_select",
    "required": false,
    "description": "Applicable compliance frameworks",
    "allowed_values": ["soc2", "pci-dss", "hipaa", "fedramp", "none"]
  }
]
JSON
# HTH Guide Excerpt: end api-create-custom-properties

# HTH Guide Excerpt: begin api-set-repo-properties
# Set custom property values on a specific repository
REPO="${GITHUB_REPO:-how-to-harden}"
gh api --method PATCH \
  "/orgs/${GITHUB_ORG}/properties/values" \
  --input - <<JSON
{
  "repository_names": ["${REPO}"],
  "properties": [
    {"property_name": "security-tier", "value": "high"},
    {"property_name": "data-classification", "value": "internal"},
    {"property_name": "compliance-scope", "value": ["soc2"]}
  ]
}
JSON
# HTH Guide Excerpt: end api-set-repo-properties

increment_applied
summary
