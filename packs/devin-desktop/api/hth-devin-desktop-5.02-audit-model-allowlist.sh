#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-desktop-5.2
#   guide: https://howtoharden.com/guides/devin-desktop/#52-audit-the-effective-model-allowlist
#   profile: L2
#   mode: read-only
#   requires: curl; python3; DEVIN_API_KEY (cog_ service user with Use Devin Desktop)
# HTH Devin Desktop 5.2: Audit the Effective Model Allowlist
# Profile Level: L2 (Walk) | NIST 800-53: CA-7
# Source: https://docs.devin.ai/desktop/accounts/api-reference/list-models
# Status: alpha (v2alpha); verified 2026-10-29, no live API validation.
set +x
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin audit-model-allowlist
# Read only. Inject DEVIN_API_KEY through your approved secret manager, not arguments.
# Redirect stdout under umask 077 if retaining the snapshot for a proposed update.
# The report omits account-specific prices and model response contents.
[ "$#" -eq 0 ] || { echo "usage: run without arguments" >&2; exit 2; }
desktop_require_key
umask 077
HTH_TMP=$(mktemp -d)
trap 'rm -rf "$HTH_TMP"' EXIT
desktop_request GET
desktop_report
# HTH Guide Excerpt: end audit-model-allowlist
