#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: microsoft-dynamics-365-1.1
#   guide: https://howtoharden.com/guides/microsoft-dynamics-365/#11-restrict-environment-users-and-effective-dataverse-roles
#   profile: L1
#   mode: read-only
#   requires: Power Platform CLI with reviewed existing auth profile
# Source (reviewed 2026-11-27): https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/admin#pac-admin-list-roles
# HTH Guide Excerpt: begin review-dataverse-role-definitions
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${HTH_DATAVERSE_ENV_ID:-}" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]] || fail 'Missing or invalid HTH_DATAVERSE_ENV_ID'

command -v pac >/dev/null || fail 'Power Platform CLI is not installed'
# Confirm the tenant using pac auth who before running.
pac admin list-roles --environment "$HTH_DATAVERSE_ENV_ID" --include-child-roles
# HTH Guide Excerpt: end review-dataverse-role-definitions
