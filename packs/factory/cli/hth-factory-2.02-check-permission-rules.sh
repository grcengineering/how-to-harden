#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: factory-2.2
#   guide: https://howtoharden.com/guides/factory/#22-enforce-tested-command-permission-rules
#   profile: L2
#   mode: read-only
#   requires: FACTORY_PROJECT_DIR(trusted absolute repository path), FACTORY_SETTINGS_FILE(reviewed strict JSON settings object), FACTORY_RULE_REPORT_OUTPUT(new private file), Droid CLI, jq, python3
# HTH Factory 2.2 — NIST AC-6, CM-7
# Source: https://docs.factory.com/autonomy-and-safety/permission-rules (available; rollout/version-gated; verified 2026-10-30)
# Checker success does not enable policy. Preview never executes the supplied command.
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin check-permission-rules
hth_init 2
hth_project
[[ -n "${FACTORY_SETTINGS_FILE:-}" && -n "${FACTORY_RULE_REPORT_OUTPUT:-}" ]] ||
  hth_unknown 'provide FACTORY_SETTINGS_FILE and FACTORY_RULE_REPORT_OUTPUT'
# --file accepts the rules container, NOT a settings.json wrapper.
jq -e '.permissionRules | select(type == "object")' "$FACTORY_SETTINGS_FILE" > "$HTH_TEMP/rules.json" ||
  hth_unknown 'settings must be strict JSON with a permissionRules object'
cd -- "$FACTORY_PROJECT_DIR"
droid rules check --file "$HTH_TEMP/rules.json" --command 'git push origin main' --json > "$HTH_TEMP/candidate.json" 2> "$HTH_TEMP/droid.stderr" ||
  hth_unknown 'candidate checker failed; retain existing policy'
droid rules check --command 'git push origin main' --json > "$HTH_TEMP/effective.json" 2> "$HTH_TEMP/droid.stderr" ||
  hth_unknown 'resolved checker failed; no effective-policy evidence'
jq -e 'type == "object"' "$HTH_TEMP/candidate.json" >/dev/null || hth_unknown 'invalid candidate report'
jq -e 'type == "object"' "$HTH_TEMP/effective.json" >/dev/null || hth_unknown 'invalid effective report'
jq -n --slurpfile candidate "$HTH_TEMP/candidate.json" --slurpfile effective "$HTH_TEMP/effective.json" \
  '{candidate: $candidate[0], effective: $effective[0]}' > "$HTH_TEMP/report.json"
hth_save_private "$HTH_TEMP/report.json" "$FACTORY_RULE_REPORT_OUTPUT"
printf 'COLLECTED: candidate and resolved previews. Inspect decisions and diagnostics; exit 0 can include a block or no-match.\n'
# HTH Guide Excerpt: end check-permission-rules
