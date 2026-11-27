#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: coralogix-1.3
#   guide: https://howtoharden.com/guides/coralogix/#13-review-groups-and-limit-api-key-permissions
#   profile: L1
#   mode: read-only
#   requires: Bash, official cx CLI, authorized reviewed profile
# Vendor contract: https://coralogix.com/docs/external/cx-cli/documents/command-reference/
# HTH Guide Excerpt: begin list-team-groups
set +x
set -euo pipefail

: "${CX_REVIEWED_PROFILE:?Set the previously reviewed Coralogix profile name}"
[[ "$CX_REVIEWED_PROFILE" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || exit 2
unset CX_API_KEY
cx --profile "$CX_REVIEWED_PROFILE" --output json iam groups list
# HTH Guide Excerpt: end list-team-groups
