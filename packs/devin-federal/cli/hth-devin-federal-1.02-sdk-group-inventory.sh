#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-federal-1.2
#   guide: https://howtoharden.com/guides/devin-federal/#12-reconcile-group-model-access-and-acu-limits
#   profile: L2
#   mode: read-only
#   requires: actual portal-downloaded SDK; Python 3/requests; existing key and trusted evidence directory
# Source: https://docs.devin.ai/federal/api/python-sdk (2026-11-05)
# HTH Guide Excerpt: begin sdk-group-inventory
set +x
set -Eeuo pipefail
umask 077
unknown() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
case "${HTH_PROFILE_LEVEL:-1}" in 2|3|4) ;; *) unknown 'HTH_PROFILE_LEVEL=2..4 required before collection' ;; esac
[[ $# == 0 ]] || unknown 'configuration is supplied through environment, never a key argument'
[[ -f ${DEVIN_FEDERAL_SDK:-} && ! -L ${DEVIN_FEDERAL_SDK:-} ]] || unknown 'supply the trusted portal-downloaded windsurf_analytics.py path'
[[ "${DEVIN_FEDERAL_API_URL:-}" =~ ^https://[A-Za-z0-9][A-Za-z0-9.-]*(:[0-9]{1,5})?$ ]] || unknown 'supply the confirmed HTTPS origin'
[[ -n ${WINDSURF_SERVICE_KEY:-} ]] || unknown 'inject an existing scoped WINDSURF_SERVICE_KEY'
[[ -d ${HTH_EVIDENCE_DIR:-} && ! -L ${HTH_EVIDENCE_DIR:-} ]] || unknown 'supply a trusted existing evidence directory'
command -v python3 >/dev/null || unknown 'Python 3 required for the actual vendor SDK'
command -v jq >/dev/null || unknown 'jq required to recognize output'
out="$(mktemp -d "$HTH_EVIDENCE_DIR/federal-groups.XXXXXX")"
# This is a wrapper around the actual vendor SDK CLI, not a substitute SDK.
if ! python3 "$DEVIN_FEDERAL_SDK" list-groups --api-url "$DEVIN_FEDERAL_API_URL" > "$out/groups.json" 2> "$out/error.txt"; then
 unknown "vendor SDK failed; no complete evidence. Review ${out}/error.txt privately"
fi
jq -se 'length==1 and (.[0]|type=="object" and (.groups|type=="array"))' "$out/groups.json" >/dev/null 2>&1 || unknown 'unrecognized SDK output; not a policy pass'
printf 'COLLECTED visible group list only: %s/groups.json; no effective-policy verdict.\n' "$out"
# HTH Guide Excerpt: end sdk-group-inventory
