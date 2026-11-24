#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: claude-code-3.3
#   guide: https://howtoharden.com/guides/claude-code/#33-isolate-self-hosted-runners-and-enforce-repository-settings
#   profile: L2
#   mode: read-only
#   requires: bash
# Source: https://code.claude.com/docs/en/self-hosted-environments-deploy
# Source: https://code.claude.com/docs/en/self-hosted-environments-reference
# Source: https://code.claude.com/docs/en/self-hosted-environments-configuration
# Available, public beta; checked 2026-11-16. Emits a launcher, never starts it.
# Run the emitted script only INSIDE a fresh, dedicated per-session container/VM.
# The provisioner must destroy it on exit; restarting a container is insufficient.
# Copy the orchestrator's temporary work order into the new workload before its
# spawn hook exits. Mount that copy read-only. Never supply the environment secret.
# The approved image must provide the binary, /workspace and a writable user home.
# Independently enforce network/metadata isolation and immutable hooks/settings.
set +x
set -euo pipefail

# HTH Guide Excerpt: begin self-hosted-runner-launcher
cat <<'RUNNER'
#!/usr/bin/env bash
set +x
set -euo pipefail
: "${CLAUDE_RUNNER_CLAUDE_BIN:?Set the approved absolute Claude binary path}"
: "${HTH_RUNNER_WORK_ORDER_FILE:?Set the mounted single-use work-order path}"
[[ "$CLAUDE_RUNNER_CLAUDE_BIN" = /* && -x "$CLAUDE_RUNNER_CLAUDE_BIN" ]] || exit 2
[[ "$HTH_RUNNER_WORK_ORDER_FILE" = /* && -r "$HTH_RUNNER_WORK_ORDER_FILE" ]] || exit 2
# Do not inherit a value-form secret that could override the file or reach a child.
unset SELF_HOSTED_RUNNER_ENVIRONMENT_SECRET SELF_HOSTED_RUNNER_POOL_SECRET
unset SELF_HOSTED_RUNNER_DEBUG_TOKEN_DIR
exec "$CLAUDE_RUNNER_CLAUDE_BIN" self-hosted-runner \
  --environment-secret-file "$HTH_RUNNER_WORK_ORDER_FILE" \
  --base-dir /workspace \
  --capacity 1 \
  --drain-grace-sec 0 \
  --confine-repo-settings enforce \
  --health-port 0
RUNNER
# HTH Guide Excerpt: end self-hosted-runner-launcher
