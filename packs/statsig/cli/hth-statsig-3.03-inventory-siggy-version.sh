#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: statsig-3.3
#   guide: https://howtoharden.com/guides/statsig/#33-review-config-dependencies-and-iac-writers
#   profile: L2
#   mode: read-only
#   requires: existing approved siggy CLI, STATSIG_OUTPUT, bash, jq, Bun
# HTH Statsig 3.3 — Review Config Dependencies and IaC Writers; NIST CM-3, CM-8; SOC 2 CC8.1
# Source: https://docs.statsig.com/statsigcli/introduction (2026-11-05)
set +x
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
# HTH Guide Excerpt: begin inventory-siggy-version
statsig_init 2
command -v siggy >/dev/null 2>&1 || statsig_unknown 'install an approved pinned first-party @statsig/siggy package'
if ! siggy --version > "$STATSIG_TEMP/version" 2> "$STATSIG_TEMP/cli-error"; then statsig_unknown 'CLI version read failed'; fi
[[ $(wc -c < "$STATSIG_TEMP/version") -le 256 ]] || statsig_unknown 'unexpected CLI version response'
version=$(tr -d '\r\n' < "$STATSIG_TEMP/version")
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([+-][A-Za-z0-9.-]+)?$ ]] || statsig_unknown 'unrecognized CLI version'
jq -n --arg version "$version" '{version:$version,coverage:"Version only; not configuration or project-identity proof."}' > "$STATSIG_TEMP/evidence"
statsig_finish "$STATSIG_TEMP/evidence"
# HTH Guide Excerpt: end inventory-siggy-version
