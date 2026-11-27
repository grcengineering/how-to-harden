#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: bitwarden-1.2
#   guide: https://howtoharden.com/guides/bitwarden/#12-limit-shared-collection-permissions
#   profile: L1
#   mode: read-only
#   requires: Bash, bw, jq, BITWARDEN_ORG_ID, BW_SESSION
# Bitwarden 1.2 | L1 | NIST AC-6 | https://howtoharden.com/guides/bitwarden/#12-limit-shared-collection-permissions
# https://bitwarden.com/help/cli/#organization-ids
# HTH Guide Excerpt: begin list-bitwarden-collection-metadata
set +x
set -euo pipefail

: "${BITWARDEN_ORG_ID:?Set the intended organization UUID}"
: "${BW_SESSION:?Inject the unlocked Bitwarden CLI session in the environment}"
[[ "$BITWARDEN_ORG_ID" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]] || exit 2
bw list org-collections --organizationid "$BITWARDEN_ORG_ID" |
  jq -e 'if type == "array" then map({id, name}) else error("not a collection list") end'
# HTH Guide Excerpt: end list-bitwarden-collection-metadata
