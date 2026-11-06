#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-federal-2.2
#   guide: https://howtoharden.com/guides/devin-federal/#22-protect-offline-licenses-and-verified-release-bundles
#   profile: L1
#   mode: read-only
#   requires: trusted preinstalled AIR-GAPPED devin; trusted evidence directory; --probe for endpoint probes
# Sources: https://docs.devin.ai/federal/air-gapped/license and /network-and-certificates (2026-11-05)
# HTH Guide Excerpt: begin health-inventory
set +x
set -Eeuo pipefail
umask 077
case "${HTH_PROFILE_LEVEL:-1}" in 1|2|3|4) ;; *) printf 'UNKNOWN: HTH_PROFILE_LEVEL must be 1..4.\n' >&2; exit 2 ;; esac
[[ $# == 0 || ( $# == 1 && "$1" == --probe ) ]] || { printf 'Usage: health-inventory.sh [--probe]\n' >&2; exit 2; }
[[ -d ${HTH_EVIDENCE_DIR:-} && ! -L ${HTH_EVIDENCE_DIR:-} ]] || { printf 'UNKNOWN: set a trusted existing HTH_EVIDENCE_DIR.\n' >&2; exit 2; }
command -v devin >/dev/null || { printf 'UNKNOWN: approved air-gapped devin required.\n' >&2; exit 2; }
out="$(mktemp -d "$HTH_EVIDENCE_DIR/federal-health.XXXXXX")"
failed=0
devin --version > "$out/version.txt" 2> "$out/version-error.txt" || failed=1
devin models validate > "$out/models.txt" 2> "$out/models-error.txt" || failed=1
# Auth status can refresh against IdP; doctor probes model/OIDC endpoints. Explicit only.
if [[ ${1:-} == --probe ]]; then
  devin auth status > "$out/auth.txt" 2> "$out/auth-error.txt" || failed=1
  devin airgap doctor > "$out/doctor.txt" 2> "$out/doctor-error.txt" || failed=1
fi
[[ "$failed" == 0 ]] || { printf 'UNKNOWN: at least one diagnostic failed; private evidence: %s\n' "$out" >&2; exit 2; }
printf 'COLLECTED private diagnostics: %s; review warnings. Not license, trust or SSO enforcement proof.\n' "$out"
# HTH Guide Excerpt: end health-inventory
