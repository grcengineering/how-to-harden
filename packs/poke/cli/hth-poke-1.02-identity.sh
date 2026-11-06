#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: poke-1.2
#   guide: https://howtoharden.com/guides/poke/#12-protect-messaging-identity-and-account-lifecycle
#   profile: L1
#   mode: read-only
#   requires: trusted preinstalled local poke package; HTH_EVIDENCE_DIR trusted existing directory
# Source: https://poke.com/docs/creating-recipes (2026-11-05)
# HTH Guide Excerpt: begin identity
set +x
set -Eeuo pipefail
umask 077
case "${HTH_PROFILE_LEVEL:-1}" in 1|2|3|4) ;; *) printf 'UNKNOWN: HTH_PROFILE_LEVEL must be 1..4.\n' >&2; exit 2 ;; esac
[[ $# == 0 && -d ${HTH_EVIDENCE_DIR:-} && ! -L ${HTH_EVIDENCE_DIR:-} ]] || { printf 'UNKNOWN: set a trusted existing HTH_EVIDENCE_DIR.\n' >&2; exit 2; }
command -v npx >/dev/null || { printf 'UNKNOWN: npx and an approved local poke package are required.\n' >&2; exit 2; }
out="$(mktemp -d "$HTH_EVIDENCE_DIR/poke-identity.XXXXXX")"
if ! npm_config_offline=true npm_config_yes=false npx --no-install poke whoami > "$out/identity.txt" 2> "$out/error.txt"; then
 printf 'UNKNOWN: identity command failed; protected diagnostic file: %s/error.txt\n' "$out" >&2; exit 2
fi
printf 'COLLECTED identity only: %s/identity.txt (review privately; not an access-policy verdict).\n' "$out"
# HTH Guide Excerpt: end identity
