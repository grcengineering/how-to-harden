#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: snowflake-1.6
#   profile: L3
#   mode: read-only
# HTH Snowflake 1.06: Inspect independent approval policy
# Profile: L3 | NIST: AC-5, IA-5
# https://howtoharden.com/guides/snowflake/
# Source: https://docs.snowflake.com/en/developer-guide/snowflake-cli/command-reference/sql-commands/sql
# Read-only; configured connection credentials remain in Snowflake CLI's secure setup.
# HTH Guide Excerpt: begin cli-inspect-approval-policy
set +x
set -euo pipefail
level="${HTH_PROFILE_LEVEL:-1}"
if [[ ! "$level" =~ ^[1-4]$ ]] || (( level < 3 )); then
  echo 'Requires HTH_PROFILE_LEVEL >= 3 (valid range 1-4)' >&2
  exit 2
fi
: "${HTH_SNOW_CONNECTION:?Set a preconfigured Snowflake CLI connection name}"
: "${HTH_POLICY:?Set an unquoted DATABASE.SCHEMA.POLICY identifier}"
if [[ ! "$HTH_POLICY" =~ ^[A-Za-z_][A-Za-z0-9_]*\.[A-Za-z_][A-Za-z0-9_]*\.[A-Za-z_][A-Za-z0-9_]*$ ]]; then
  echo "HTH_POLICY must be three unquoted SQL identifiers; quoted names are not supported" >&2
  exit 2
fi
command -v snow >/dev/null || { echo "Install the official Snowflake CLI first" >&2; exit 2; }
snow sql --connection "$HTH_SNOW_CONNECTION" --enable-templating NONE --enhanced-exit-codes \
  --query "DESCRIBE MULTI PARTY APPROVAL POLICY $HTH_POLICY;" --format JSON
# Empty output, insufficient privileges, or an unassigned policy is not a pass.
# HTH Guide Excerpt: end cli-inspect-approval-policy
