#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: niteshift-2.2
#   guide: https://howtoharden.com/guides/niteshift/#22-keep-internal-services-unpublished
#   profile: L1
#   mode: read-only
#   requires: first-party ns CLI inside an existing Niteshift task
# Source: https://docs.niteshift.dev/environment-configuration/services (available; checked 2026-11-18)
# HTH Guide Excerpt: begin service-status
set -euo pipefail
command -v ns >/dev/null || { printf '%s\n' 'Run inside an existing Niteshift task.' >&2; exit 2; }
ns services status
# HTH Guide Excerpt: end service-status
