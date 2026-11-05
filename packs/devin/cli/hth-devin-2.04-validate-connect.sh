#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-2.4
#   guide: https://howtoharden.com/guides/devin/#24-constrain-devin-connect-routes-and-gateway-identity
#   profile: L3
#   mode: read-only
#   requires: Trusted preinstalled first-party gateway binary; reviewed YAML file
# Source: https://docs.devin.ai/enterprise/deployment/devin-connect (2026-11-05)
# HTH Guide Excerpt: begin validate-connect
set +x
set -Eeuo pipefail
case "${HTH_PROFILE_LEVEL:-1}" in 3|4) ;; *) printf 'UNKNOWN: HTH_PROFILE_LEVEL=3..4 required.\n' >&2; exit 2 ;; esac
[[ $# == 1 && -f "$1" && ! -L "$1" ]] || { printf 'Usage: bash %s REVIEWED_CONFIG.yml\n' "$0" >&2; exit 2; }
command -v gateway >/dev/null || { printf 'UNKNOWN: install the approved gateway binary separately.\n' >&2; exit 2; }
# validate-config is the offline validation command; doctor probes and serve starts a daemon.
exec gateway validate-config --config "$1"
# HTH Guide Excerpt: end validate-connect
