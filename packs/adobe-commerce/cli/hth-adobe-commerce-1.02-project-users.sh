#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: adobe-commerce-1.2
#   guide: https://howtoharden.com/guides/adobe-commerce/#12-review-cloud-infrastructure-project-roles
#   profile: L1
#   mode: read-only
#   requires: bash, authenticated Adobe Commerce Cloud CLI and exact PaaS project ID
# Source (checked 2026-11-27): https://experienceleague.adobe.com/en/docs/commerce-on-cloud/user-guide/dev-tools/cloud-cli/cloud-cli-reference
# Review locally; protect evidence from unnecessary disclosure.

# HTH Guide Excerpt: begin adobe-commerce-evidence
set +x
set -euo pipefail
fail() { printf '%s\n' "$*" >&2; exit 2; }
: "${HTH_COMMERCE_PROJECT:?Set the exact PaaS Commerce project ID.}"
[[ "$HTH_COMMERCE_PROJECT" =~ ^[a-z0-9]+$ ]] || fail 'Invalid PaaS Commerce project ID.'
magento-cloud user:list --project "$HTH_COMMERCE_PROJECT" --no-interaction
# HTH Guide Excerpt: end adobe-commerce-evidence
