#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: claude-code-3.4
#   guide: https://howtoharden.com/guides/claude-code/#34-bind-runner-credential-exchange-to-verified-session-identity
#   profile: L2
#   mode: read-only
#   requires: HTH_RUN_NATIVE_CHECK=1, CLAUDE_RUNNER_CLAUDE_BIN(approved absolute binary), CLAUDE_CODE_SESSION_ACCESS_TOKEN(injected), HTH_EXPECTED_ENVIRONMENT_ID, HTH_EXPECTED_ACTOR_SUB, bash, jq
# Source: https://code.claude.com/docs/en/self-hosted-environments-identity
# Available, public beta; checked 2026-11-16. Run inside a trusted session wrapper.
# Native decode-token verifies signature/expiry using vendor JWKS, but not
# issuer/audience/role. Never replace it with a base64-only decoder.
# No token/claims/actor IDs are printed. No credential is minted or exchanged.
set +x
set -euo pipefail

# HTH Guide Excerpt: begin verify-runner-session-identity
if [[ "${HTH_RUN_NATIVE_CHECK:-}" != 1 ]]; then
  printf '%s\n' 'SKIPPED: native token verification was not requested.'
  exit 2
fi
: "${CLAUDE_RUNNER_CLAUDE_BIN:?Set the approved absolute Claude binary path}"
: "${CLAUDE_CODE_SESSION_ACCESS_TOKEN:?Inject the session token without printing it}"
: "${HTH_EXPECTED_ENVIRONMENT_ID:?Set the independently approved environment ID}"
: "${HTH_EXPECTED_ACTOR_SUB:?Set the independently approved exact actor subject}"
[[ "$CLAUDE_RUNNER_CLAUDE_BIN" = /* && -x "$CLAUDE_RUNNER_CLAUDE_BIN" ]] || exit 2
[[ "$HTH_EXPECTED_ENVIRONMENT_ID" =~ ^ccpool_[A-Za-z0-9_-]+$ ]] || exit 2
[[ "$HTH_EXPECTED_ACTOR_SUB" =~ ^(user|agent):[A-Za-z0-9_-]+$ ]] || exit 2
[[ "$CLAUDE_CODE_SESSION_ACCESS_TOKEN" == sk-ant-cc-* ]] || {
  printf '%s\n' 'DENIED: token is not a self-hosted session token.' >&2; exit 1;
}
claims="$("$CLAUDE_RUNNER_CLAUDE_BIN" self-hosted-runner decode-token 2>/dev/null)" || {
  printf '%s\n' 'DENIED: native signature or expiry verification failed.' >&2; exit 1;
}
if ! printf '%s' "$claims" | jq -e \
  --arg pool "$HTH_EXPECTED_ENVIRONMENT_ID" \
  --arg actor "$HTH_EXPECTED_ACTOR_SUB" '
    type == "object" and .iss == "ccr" and
    (.aud | type == "array" and index($pool) != null) and
    .["ccr:role"] == "session_worker" and
    (.exp | type == "number" and . > now) and
    (.act | type == "object" and .sub == $actor)
  ' >/dev/null 2>&1; then
  unset claims
  printf '%s\n' 'DENIED: session claims do not match the approved authorization boundary.' >&2
  exit 1
fi
unset claims
printf '%s\n' 'IDENTITY MATCHED: separately authorize each resource and credential scope.'
# HTH Guide Excerpt: end verify-runner-session-identity
