#!/usr/bin/env bash
# HTH Control claude-enterprise 2.2: Read Compliance recording state
# Profile: L2 | Read-only; requires existing authorized ANTHROPIC_ADMIN_KEY
# https://howtoharden.com/guides/claude-enterprise/#22-enable-the-compliance-api-with-least-privilege-keys
# Source: https://platform.claude.com/docs/en/api/http/organization/compliance_settings/retrieve
# Exact minimum Enterprise key scope is not specified in the inspected public
# scope table. Verify existing authorization; never create/broaden a key to test.
set -euo pipefail
source "$(dirname "$0")/../../anthropic-claude/api/common.sh"
# HTH Guide Excerpt: begin compliance-recording-state
evidence=$(anthropic_evidence_dir)
trap 'rm -f "${evidence}/recording.pending"' EXIT
anthropic_get /v1/organizations/compliance_settings > "${evidence}/recording.pending"
jq -e '.type=="compliance_settings" and (.state|type)=="object" and (.state.type=="enabled" or .state.type=="disabled")' "${evidence}/recording.pending" >/dev/null || exit 2
mv "${evidence}/recording.pending" "${evidence}/recording-state.json"
printf 'Private recording-state evidence: %s. Linked child state is inherited from its parent.\n' "${evidence}/recording-state.json"
jq -e '.state.type=="enabled"' "${evidence}/recording-state.json" >/dev/null || { echo 'Compliance recording is disabled.' >&2; exit 1; }
echo 'Recording enabled for the credential’s organization; not proof of historic capture, every child, posture status or SIEM delivery.'
# HTH Guide Excerpt: end compliance-recording-state
