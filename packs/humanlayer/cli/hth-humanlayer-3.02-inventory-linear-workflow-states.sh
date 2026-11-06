#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: humanlayer-3.2
#   guide: https://howtoharden.com/guides/humanlayer/#32-scope-github-linear-and-jira-integration-grants
#   profile: L1
#   mode: read-only
#   requires: HUMANLAYER_LINEAR_TEAM(explicit team key), HUMANLAYER_LINEAR_STATES_OUTPUT(new private file), approved @humanlayer/linear-cli, jq
# HTH HumanLayer 3.2 — NIST AC-3, AC-6, AC-21
# Source: https://docs.humanlayer.com/guide/linear-integration (available; checked 2026-11-05)
# Use the HumanLayer companion, not another vendor's command named linear. Authenticate through its approved login flow first.
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin inventory-linear-workflow-states
hl_level 1
hl_jq
command -v linear >/dev/null 2>&1 || hl_unknown 'approved @humanlayer/linear-cli is required'
[[ "${HUMANLAYER_LINEAR_TEAM:-}" =~ ^[A-Za-z][A-Za-z0-9_-]{0,49}$ ]] || hl_unknown 'provide an explicit team key'
[[ "${HUMANLAYER_LINEAR_STATES_OUTPUT:-}" == /* ]] || hl_unknown 'provide an absolute private output path'
hl_parent="$(dirname "$HUMANLAYER_LINEAR_STATES_OUTPUT")"
[[ -d "$hl_parent" ]] || hl_unknown 'output parent must be an existing trusted directory'
hl_temp="$(mktemp -d "$hl_parent/.hth-humanlayer.XXXXXX")" || hl_unknown 'cannot create private temp directory'
trap 'rm -rf -- "$hl_temp"' EXIT
linear list-workflow-states "$HUMANLAYER_LINEAR_TEAM" --output-format json \
  > "$hl_temp/states.json" 2> "$hl_temp/cli.stderr" || hl_unknown 'workflow-state collection failed'
# The docs establish JSON output but no stable envelope. Require structured JSON, without inventing fields.
jq -e 'type == "array" or type == "object"' "$hl_temp/states.json" >/dev/null || hl_unknown 'invalid JSON inventory'
# Same-directory hard link publishes a complete private file, refusing existing files/symlinks.
if ! ln "$hl_temp/states.json" "$HUMANLAYER_LINEAR_STATES_OUTPUT" 2>/dev/null; then
  hl_unknown 'output must be a new file in an existing trusted directory'
fi
printf 'COLLECTED: one team workflow-state response. No columns, issue status or OAuth grants were changed.\n'
# HTH Guide Excerpt: end inventory-linear-workflow-states
