#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: humanlayer-2.1
#   guide: https://howtoharden.com/guides/humanlayer/#21-review-workspace-setup-and-default-secret-copies
#   profile: L2
#   mode: read-only
#   requires: HUMANLAYER_SOURCE_REF(reviewed upstream ref or commit), jq
# HTH HumanLayer 2.1 — NIST CM-5, AC-6
# Source: https://docs.humanlayer.com/reference/workspace-config (available; checked 2026-11-05)
# Prints strict JSON only. Merge/review manually; local overrides and default secret-copy globs remain effective.
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin build-workspace-candidate
hl_level 2
hl_jq
[[ "${HUMANLAYER_SOURCE_REF:-}" =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*$ && ${#HUMANLAYER_SOURCE_REF} -le 200 ]] ||
  hl_unknown 'provide a reviewed upstream ref or exact commit (no shell syntax)'
jq -n --arg ref "$HUMANLAYER_SOURCE_REF" '{sourceRef: $ref, setupBlocksFirstSession: true}'
# HTH Guide Excerpt: end build-workspace-candidate
