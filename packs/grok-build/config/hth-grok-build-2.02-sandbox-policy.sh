#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-build-2.2
#   guide: https://howtoharden.com/guides/grok-build/#22-enforce-a-sandbox-and-test-its-platform-specific-limits
#   profile: L2
#   mode: read-only
#   requires: bash; bun; HTH_CANDIDATE_POLICY for verify
#   changes: prints one candidate TOML document at a time or reads supplied files; no deployment
#   source: https://docs.x.ai/build/settings/reference#sandboxtoml-custom-profiles
# HTH Guide Excerpt: begin sandbox-policy
set -euo pipefail
command -v bun >/dev/null || { echo 'PRECONDITION: Bun is required.' >&2; exit 2; }
export HTH_GROK_ACTION="${1:-policy}"
bun - <<'JS'
const action = process.env.HTH_GROK_ACTION;
const denied = ["**/.env", "**/*.pem", "**/.ssh/**", "**/.aws/**"];
if (action === "policy") {
  console.log(`# Merge into root-owned /etc/grok/requirements.toml.
[sandbox]
profile = "strict"
auto_allow_bash = false`);
} else if (action === "profile") {
  console.log(`# Optional candidate ~/.grok/sandbox.toml; not activated by the strict policy output.
# Activate only after proving definition integrity/precedence and testing the target host.
# A profile name pinned in requirements.toml does not prove its definition is immutable.
[profiles.hth-strict]
extends = "strict"
restrict_network = true
deny = ${JSON.stringify(denied)}`);
} else if (action === "verify") {
  const policyPath = process.env.HTH_CANDIDATE_POLICY;
  if (!policyPath) { console.error("PRECONDITION: supply HTH_CANDIDATE_POLICY."); process.exit(2); }
  let p;
  try { p = Bun.TOML.parse(await Bun.file(policyPath).text()); }
  catch { console.error("PRECONDITION: supplied policy is unreadable or invalid TOML."); process.exit(2); }
  const ok = p.sandbox?.profile === "strict" && p.sandbox?.auto_allow_bash === false;
  console.log(JSON.stringify({candidate_fields_match: ok, not_proven: ["optional custom profile active", "sandbox definition precedence and integrity", "kernel enforcement", "Linux bubblewrap availability", "macOS child networking", "in-process networking", "inherited environment secrets"]}));
  process.exit(ok ? 0 : 1);
} else { console.error("Usage: sandbox-policy.sh [policy|profile|verify]"); process.exit(2); }
JS
# HTH Guide Excerpt: end sandbox-policy
