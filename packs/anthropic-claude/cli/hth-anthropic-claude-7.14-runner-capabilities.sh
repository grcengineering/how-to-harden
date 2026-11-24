#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: claude-code-3.3
#   guide: https://howtoharden.com/guides/claude-code/#33-isolate-self-hosted-runners-and-enforce-repository-settings
#   profile: L2
#   mode: read-only
#   requires: HTH_RUN_NATIVE_CHECK=1, CLAUDE_RUNNER_CLAUDE_BIN(approved absolute binary), bash
# Source: https://code.claude.com/docs/en/self-hosted-environments-quickstart
# Source: https://code.claude.com/docs/en/self-hosted-environments-reference
# Available, public beta; checked 2026-11-16. No registration, setup or session.
set +x
set -euo pipefail

# HTH Guide Excerpt: begin check-runner-capabilities
if [[ "${HTH_RUN_NATIVE_CHECK:-}" != 1 ]]; then
  printf '%s\n' 'SKIPPED: set HTH_RUN_NATIVE_CHECK=1 to inspect approved native help.'
  exit 2
fi
: "${CLAUDE_RUNNER_CLAUDE_BIN:?Set the approved absolute Claude binary path}"
[[ "$CLAUDE_RUNNER_CLAUDE_BIN" = /* && -x "$CLAUDE_RUNNER_CLAUDE_BIN" ]] || exit 2
help_text="$("$CLAUDE_RUNNER_CLAUDE_BIN" self-hosted-runner --help 2>/dev/null)" || {
  printf '%s\n' 'UNKNOWN: native runner help failed.' >&2; exit 2;
}
for flag in --environment-secret-file --capacity --drain-grace-sec --confine-repo-settings --health-port; do
  if [[ "$help_text" != *"$flag"* ]]; then
    printf '%s\n' 'UNKNOWN: required runner capability missing from native help.' >&2
    exit 2
  fi
done
printf '%s\n' 'CAPABILITIES PRESENT: this does not verify deployment or enforcement.'
# HTH Guide Excerpt: end check-runner-capabilities
