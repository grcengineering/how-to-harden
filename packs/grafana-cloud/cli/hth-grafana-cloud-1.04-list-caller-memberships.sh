#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grafana-cloud-1.4
#   guide: https://howtoharden.com/guides/grafana-cloud/#14-separate-portal-and-stack-administrator-roles
#   profile: L2
#   mode: read-only
#   requires: Bash, gcx, GRAFANA_GCX_CONFIG, authorized cloud session
# Grafana Cloud 1.4 | L2 | NIST AC-6 | https://howtoharden.com/guides/grafana-cloud/#14-separate-portal-and-stack-administrator-roles
# Caller membership only. This doesn't enumerate the organization's members.
# https://grafana.com/docs/grafana/latest/ai-tools/grafana-cli/gcx/cli-reference/
# HTH Guide Excerpt: begin list-grafana-cloud-caller-memberships
set -euo pipefail

: "${GRAFANA_GCX_CONFIG:?Set the path to the intended existing gcx config}"
[[ -r "$GRAFANA_GCX_CONFIG" ]] || exit 2
gcx cloud orgs list --config "$GRAFANA_GCX_CONFIG" --json slug,role
# HTH Guide Excerpt: end list-grafana-cloud-caller-memberships
