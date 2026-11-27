#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: aptible-1.2
#   guide: https://howtoharden.com/guides/aptible/#12-restrict-application-endpoints
#   profile: L1
#   mode: read-only
#   requires: Bash, aptible CLI, authorized CLI session, APTIBLE_ENVIRONMENT, APTIBLE_APP
# Vendor contract: https://www.aptible.com/docs/reference/aptible-cli/cli-commands/cli-endpoints-list
# HTH Guide Excerpt: begin inspect-app-endpoints
set +x
set -euo pipefail

: "${APTIBLE_ENVIRONMENT:?Set the approved environment handle}"
: "${APTIBLE_APP:?Set the approved app handle}"
[[ "$APTIBLE_ENVIRONMENT" =~ ^[a-z0-9][a-z0-9-]*$ && "$APTIBLE_APP" =~ ^[a-z0-9][a-z0-9-]*$ ]] || exit 2

# Confirm your authenticated account points at the intended organization.
aptible endpoints:list --environment "$APTIBLE_ENVIRONMENT" --app "$APTIBLE_APP"
# HTH Guide Excerpt: end inspect-app-endpoints
