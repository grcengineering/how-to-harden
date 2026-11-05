#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: chatgpt-work-codex-4.1
#   guide: https://howtoharden.com/guides/chatgpt-work-codex/#41-constrain-codex-security-scans-and-their-configuration
#   profile: L1
#   mode: read-only
#   requires: approved installed codex-security; HTH_SCAN_REPO and trusted HTH_SCAN_CONFIG outside checkout
# Source: https://learn.chatgpt.com/docs/security/cli/reference (fetched 2026-11-05)
set -euo pipefail
umask 077
# HTH Guide Excerpt: begin cli-check
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"
[[ "$HTH_PROFILE_LEVEL" =~ ^[1234]$ && "$HTH_PROFILE_LEVEL" -ge 1 ]] || { echo 'This pack requires profile 1 or higher (1-4)' >&2; exit 2; }
command -v codex-security >/dev/null || { echo 'Install the approved Codex Security CLI separately' >&2; exit 2; }
[[ -d "${HTH_SCAN_REPO:-}" && -f "${HTH_SCAN_CONFIG:-}" ]] || { echo 'Set HTH_SCAN_REPO and HTH_SCAN_CONFIG to approved absolute paths' >&2; exit 2; }
[[ "$HTH_SCAN_REPO" = /* && "$HTH_SCAN_CONFIG" = /* ]] || exit 2
[[ ! -L "$HTH_SCAN_CONFIG" ]] || { echo 'Trusted scan configuration must not be a symlink' >&2; exit 2; }
repo="$(cd "$HTH_SCAN_REPO" && pwd -P)"
config_dir="$(cd "$(dirname "$HTH_SCAN_CONFIG")" && pwd -P)"
case "$config_dir/" in "$repo/"*) echo 'Trusted scan configuration must be outside the checkout' >&2; exit 2;; esac
codex-security info --json
codex-security scan "$repo" --config "$HTH_SCAN_CONFIG" --dry-run
echo 'Dry run only: no scan, model-access test, validation, patch or PR.' >&2
# HTH Guide Excerpt: end cli-check
