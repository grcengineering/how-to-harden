#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-build-5.1
#   guide: https://howtoharden.com/guides/grok-build/#51-record-posture-and-complete-containment-and-offboarding
#   profile: L1
#   mode: read-only
#   requires: bash; grok; HTH_RUN_GROK_READS=1
#   changes: opt-in native read commands and private local evidence files; never logs out or deletes state
#   source: https://docs.x.ai/build/cli/reference
# HTH Guide Excerpt: begin inventory-lifecycle
set -euo pipefail
if [[ "${HTH_RUN_GROK_READS:-}" != 1 ]]; then
  echo 'PRECONDITION: set HTH_RUN_GROK_READS=1 to collect local state metadata. It may contain sensitive paths and titles.' >&2
  exit 2
fi
command -v grok >/dev/null || { echo 'PRECONDITION: Grok Build is not installed; this pack does not install it.' >&2; exit 2; }
export GROK_DISABLE_AUTOUPDATER=1
umask 077
evidence_dir=$(mktemp -d "${TMPDIR:-/tmp}/hth-grok-build-lifecycle.XXXXXX")
trap 'echo "PARTIAL evidence retained at: $evidence_dir" >&2' ERR
grok --version >"$evidence_dir/version.txt" 2>"$evidence_dir/version.stderr"
grok inspect --json >"$evidence_dir/inspect.json" 2>"$evidence_dir/inspect.stderr"
grok plugin list >"$evidence_dir/plugins.txt" 2>"$evidence_dir/plugins.stderr"
grok sessions list >"$evidence_dir/sessions.txt" 2>"$evidence_dir/sessions.stderr"
grok worktree list >"$evidence_dir/worktrees.txt" 2>"$evidence_dir/worktrees.stderr"
printf 'COLLECTED: private evidence at %s\n' "$evidence_dir"
printf '%s\n' 'NOT ASSESSED: event completeness/tamper resistance, live tasks, credential revocation, exported copies, retention or effective policy. No authentication, update, inference or deletion was run.'
# HTH Guide Excerpt: end inventory-lifecycle
