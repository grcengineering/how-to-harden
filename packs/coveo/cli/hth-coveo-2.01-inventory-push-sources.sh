#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: coveo-2.1
#   guide: https://howtoharden.com/guides/coveo/#21-preserve-source-item-permissions
#   profile: L1
#   mode: read-only
#   requires: Bash; authenticated Coveo CLI v3 in approved context
# HTH coveo 2.1: Preserve source item permissions
# Profile: L1 (Crawl)
# Guide: https://howtoharden.com/guides/coveo/
# Reference: https://docs.coveo.com/en/cli/
# HTH Guide Excerpt: begin inventory-push-sources
set -euo pipefail
: "${COVEO_ORGANIZATION_ID:?Set the approved Coveo organization ID}"
[[ "$COVEO_ORGANIZATION_ID" =~ ^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$ ]] || exit 2
if [[ "$(coveo config:get organization)" != "$COVEO_ORGANIZATION_ID" ]]; then
  printf '%s\n' 'Coveo CLI context does not match the requested organization' >&2
  exit 2
fi
coveo source:list --output=json
# HTH Guide Excerpt: end inventory-push-sources
