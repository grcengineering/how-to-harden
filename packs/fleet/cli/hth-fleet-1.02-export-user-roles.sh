#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: fleet-1.2
#   guide: https://howtoharden.com/guides/fleet/
#   profile: L1
#   mode: read-only
#   requires: fleetctl, configured least-privilege context
# HTH Fleet §1.2 Export User Roles | NIST AC-6
# Guide: https://howtoharden.com/guides/fleet/
# Source: https://fleetdm.com/guides/downgrade-fleet
# HTH Guide Excerpt: begin export-user-roles
set -euo pipefail
set +x
: "${FLEETCTL_CONTEXT:?Set the already configured CLI context for the intended Fleet tenant}"
umask 077
out=$(mktemp "${TMPDIR:-/tmp}/fleet-user-roles.XXXXXXXX")
if ! fleetctl get user_roles --context "$FLEETCTL_CONTEXT" > "$out" || [[ ! -s "$out" ]]; then
  rm -f -- "$out"
  printf 'Fleet role export failed or returned no data.\n' >&2
  exit 1
fi
printf 'Private role export: %s\n' "$out"
# HTH Guide Excerpt: end export-user-roles
