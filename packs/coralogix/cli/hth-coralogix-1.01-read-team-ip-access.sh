#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: coralogix-1.1
#   guide: https://howtoharden.com/guides/coralogix/#11-scope-network-access-to-approved-egress
#   profile: L2
#   mode: read-only
#   requires: Bash, official cx CLI, authorized reviewed profile
# Vendor contract: https://coralogix.com/docs/external/cx-cli/documents/command-reference/
# HTH Guide Excerpt: begin read-team-ip-access
set +x
set -euo pipefail

: "${CX_REVIEWED_PROFILE:?Set the previously reviewed Coralogix profile name}"
[[ "$CX_REVIEWED_PROFILE" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || exit 2
unset CX_API_KEY
cx --profile "$CX_REVIEWED_PROFILE" --output json iam ip-access get
# HTH Guide Excerpt: end read-team-ip-access
