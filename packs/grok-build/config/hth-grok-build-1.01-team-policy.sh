#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grok-build-1.1
#   guide: https://howtoharden.com/guides/grok-build/#11-pin-native-system-policy-and-approved-team-identity
#   profile: L1
#   mode: read-only
#   requires: bash; bun; HTH_ALLOWED_TEAM_UUID; HTH_CANDIDATE_POLICY for verify
#   changes: prints a candidate policy or reads an explicitly supplied TOML file; never installs policy
#   source: https://docs.x.ai/build/enterprise#restricting-login-methods
# HTH Guide Excerpt: begin team-policy
set -euo pipefail
command -v bun >/dev/null || { echo 'PRECONDITION: Bun is required.' >&2; exit 2; }
export HTH_GROK_ACTION="${1:-render}"
bun - <<'JS'
const action = process.env.HTH_GROK_ACTION;
const team = process.env.HTH_ALLOWED_TEAM_UUID ?? "";
if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(team)) {
  console.error("PRECONDITION: HTH_ALLOWED_TEAM_UUID must be the approved team's UUID."); process.exit(2);
}
if (action === "render") {
  console.log("# Candidate for root-owned /etc/grok/requirements.toml; merge with existing policy.");
  console.log(`[grok_com_config]\ndisable_api_key_auth = true\nforce_login_team_uuid = ${JSON.stringify(team)}`);
} else if (action === "verify") {
  const path = process.env.HTH_CANDIDATE_POLICY;
  if (!path) { console.error("PRECONDITION: supply HTH_CANDIDATE_POLICY."); process.exit(2); }
  let config;
  try { config = Bun.TOML.parse(await Bun.file(path).text()); }
  catch { console.error("PRECONDITION: supplied policy is unreadable or invalid TOML."); process.exit(2); }
  const p = config.grok_com_config;
  const ok = p?.disable_api_key_auth === true && p?.force_login_team_uuid === team;
  console.log(JSON.stringify({candidate_fields_match: ok, not_proven: ["installed root ownership", "effective policy", "runtime login rejection", "BYOK authorization"]}));
  process.exit(ok ? 0 : 1);
} else { console.error("Usage: team-policy.sh [render|verify]"); process.exit(2); }
JS
# HTH Guide Excerpt: end team-policy
