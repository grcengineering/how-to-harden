#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-2.2
#   guide: https://howtoharden.com/guides/tailscale/#22-test-policy-changes-before-deployment
#   profile: L1
#   mode: read-only
#   requires: TAILSCALE_ACCESS_TOKEN(policy_file:read plus devices:core:read and devices:posture_attributes:read), TAILSCALE_TAILNET, TAILSCALE_OUTPUT, TAILSCALE_POLICY_FILE, bash, curl, jq, python3
# HTH Tailscale 2.2 — Test Policy Changes Before Deployment; NIST CM-3, CM-5; SOC 2 CC8.1
# Source: https://github.com/tailscale/tailscale-client-go-v2/blob/main/policyfile.go (available; 2026-11-04)
# POST /acl/validate evaluates a candidate; POST /acl would APPLY and is forbidden here.
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin validate-candidate
hth_api_init 1
[[ -n "${TAILSCALE_POLICY_FILE:-}" && -f "$TAILSCALE_POLICY_FILE" ]] || hth_unknown 'set TAILSCALE_POLICY_FILE to the complete reviewed candidate'
[[ $(wc -c < "$TAILSCALE_POLICY_FILE") -le 2097152 && -s "$TAILSCALE_POLICY_FILE" ]] || hth_unknown 'candidate must be nonempty and at most 2 MiB'
# Copy once to avoid validating a moving local input. No credential is placed in it.
cp -- "$TAILSCALE_POLICY_FILE" "$HTH_TEMP/candidate.hujson"
hth_request POST "/api/v2/tailnet/${HTH_TAILNET}/acl/validate" "$HTH_TEMP/result" application/json "$HTH_TEMP/candidate.hujson"
# The documented successful validation response is HTTP 200 with an EMPTY body.
# Some failures use HTTP 200 with error content; never turn that into success.
[[ ! -s "$HTH_TEMP/result" ]] || hth_unknown 'candidate validation returned content; review through the policy editor, no pass claimed'
printf '{"candidateValidated":true,"applied":false}\n' > "$HTH_TEMP/report.json"
hth_save "$HTH_TEMP/report.json"
printf 'VALIDATED-CANDIDATE: server accepted candidate tests; policy was not applied.\n'
# HTH Guide Excerpt: end validate-candidate
