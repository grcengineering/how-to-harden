#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-3.2
#   guide:   https://howtoharden.com/guides/ona/#32-control-the-in-environment-web-browser
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional); HTH_PROFILE_LEVEL >= 2; sibling common.sh
# =============================================================================
# HTH Ona Control 3.2: Control the In-Environment Web Browser
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 9.2
# Source: https://howtoharden.com/guides/ona/#32-control-the-in-environment-web-browser
# Dependencies: Bash, curl, jq; sibling common.sh; HTH_PROFILE_LEVEL >= 2
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# `ona_organization_policies` can set `web_browser_disabled`, but the singleton
# is resolved from the authenticated token's own organization and only exists in
# Terraform once you import it (`current`). Auditing an organization you do not
# manage as code means reading the live value, and
# `UpdateOrganizationPolicies` returns an EMPTY message, so even a Terraform-run
# org needs this read to prove the setting landed. No CLI verb exists.
#
# ── TRAP 1: absent means false means THE BROWSER IS AVAILABLE ───────────────
# Proto3 omits default values. On a real organization `webBrowserDisabled` was
# missing from the policies response entirely. The field is documented
# `required=true` on the message, which tempts a reader into assuming it will
# always be present — it is not, because "required" describes the proto contract,
# not the JSON encoding. `(.webBrowserDisabled // false)` is the only safe read.
#
# ── TRAP 2: this does NOT cover VS Code Browser ────────────────────────────
# Verbatim: "web_browser_disabled controls whether users can open the built-in
# web browser from environment pages. THIS DOES NOT AFFECT VS CODE BROWSER."
# Disabling it closes one browsing surface, not browsing. Anything the control
# claims beyond that is overstated, and the pack says so in its own output so the
# evidence cannot be quoted out of context.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition
# =============================================================================

set +x
set -euo pipefail
# Download the complete api directory; common.sh is required.
# Use same-domain tokens. Custom HTTPS bases also require matching
# ONA_REVIEWED_API_BASE. Stdout is staged until completion; keep it private.
# shellcheck source=packs/ona/api/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
ona_init 2
# HTH Guide Excerpt: begin web-browser-policy-audit
audit() {
  get_policies
  echo "Ona 3.2 — in-environment web browser"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  # TRAP 1: `required=true` is a proto constraint, not a promise that the JSON
  # will carry the key. Absent == false == the browser is available.
  local disabled
  disabled=$(jq -r '.webBrowserDisabled // false' <<<"${POLICIES}")
  echo "  webBrowserDisabled: ${disabled} (absent in the JSON means false)"

  if [ "${disabled}" = "true" ]; then
    echo "COMPLIANT: the built-in web browser cannot be opened from environment pages."
    echo "  Scope note: this does NOT disable VS Code Browser (TRAP 2) — do not record this"
    echo "  evidence as 'browsing disabled in environments'."
    ona_complete
    return 0
  fi
  echo "FINDING: the in-environment web browser is available to every member."
  echo "  It is a full browser inside the environment, so an agent-driven or human session can"
  echo "  reach an internal service, authenticate to it with environment-resident credentials,"
  echo "  and move data out without leaving the environment's network path."
  ona_complete
  return 1
}
# HTH Guide Excerpt: end web-browser-policy-audit

audit
