#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-build-4.2
#   guide: https://howtoharden.com/guides/grok-build/#42-control-local-persistence-telemetry-and-zdr-output
#   profile: L2
#   mode: read-only
#   requires: bash; bun; HTH_CANDIDATE_POLICY for verify
#   changes: prints candidate TOML or environment assignments, or reads supplied TOML; no ZDR activation
#   source: https://docs.x.ai/build/settings/reference
# HTH Guide Excerpt: begin data-policy
set -euo pipefail
command -v bun >/dev/null || { echo 'PRECONDITION: Bun is required.' >&2; exit 2; }
export HTH_GROK_ACTION="${1:-policy}"
bun - <<'JS'
const action = process.env.HTH_GROK_ACTION;
if (action === "policy") {
  console.log(`# Merge into root-owned /etc/grok/requirements.toml.
# This does not activate team ZDR or delete local sessions, exports, memory or logs.
[memory]
enabled = false

[tools]
respect_gitignore = true
disable_zdr_incompatible_tools = true`);
} else if (action === "environment") {
  console.log(`# Review for your managed launcher; output is not automatically evaluated.
export DISABLE_TELEMETRY=1
export DISABLE_ERROR_REPORTING=1
export GROK_CRASH_HANDLER=0`);
} else if (action === "verify") {
  const path = process.env.HTH_CANDIDATE_POLICY;
  if (!path) { console.error("PRECONDITION: supply HTH_CANDIDATE_POLICY."); process.exit(2); }
  let p;
  try { p = Bun.TOML.parse(await Bun.file(path).text()); }
  catch { console.error("PRECONDITION: supplied policy is unreadable or invalid TOML."); process.exit(2); }
  const ok = p.memory?.enabled === false && p.tools?.respect_gitignore === true && p.tools?.disable_zdr_incompatible_tools === true;
  console.log(JSON.stringify({candidate_fields_match: ok, not_proven: ["team ZDR enabled", "telemetry launcher settings", "local retention/deletion", "model or connector retention", "ZDR video bucket policy", "effective pins"]}));
  process.exit(ok ? 0 : 1);
} else { console.error("Usage: data-policy.sh [policy|environment|verify]"); process.exit(2); }
JS
# HTH Guide Excerpt: end data-policy
