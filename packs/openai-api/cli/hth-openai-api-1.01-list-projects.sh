#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: openai-api-1.1
#   guide: https://howtoharden.com/guides/openai-api/#11-isolate-projects-and-minimize-effective-access
#   profile: L1
#   mode: read-only
#   requires: OPENAI_ADMIN_KEY, official openai CLI, jq
# Source: https://github.com/openai/openai-cli (current nested commands; colon aliases supported)
# NIST 800-53 AC-2. CLI output is an inventory, not a least-privilege verdict.
set +x
set -euo pipefail
umask 077
case "${HTH_PROFILE_LEVEL:-1}" in
  1|2|3|4) ;;
  *) printf '%s\n' 'HTH_PROFILE_LEVEL must be 1, 2, 3, or 4.' >&2; exit 2 ;;
esac
: "${OPENAI_ADMIN_KEY:?Inject an Admin API key}"
command -v openai >/dev/null || { printf '%s\n' 'Install the official OpenAI CLI before running this inventory.' >&2; exit 2; }
work="$(mktemp -d "${TMPDIR:-/tmp}/hth-openai-cli.XXXXXX")"
trap 'rm -rf -- "$work"' EXIT
# HTH Guide Excerpt: begin cli-list-projects
if ! openai admin organization projects list --format json >"$work/response.json" 2>"$work/cli.err"; then
  printf '%s\n' 'OpenAI CLI inventory failed; inspect authentication and CLI help privately.' >&2
  exit 2
fi
if ! jq -e '.data // .' "$work/response.json" >"$work/result.json" 2>/dev/null; then
  printf '%s\n' 'OpenAI CLI returned an invalid inventory response.' >&2
  exit 2
fi
cat "$work/result.json"
# Inspect the CLI pagination/help for your installed version before treating
# this output as a complete organization inventory. REST packs page explicitly.
# stdout can contain organization metadata; redirect it to a private destination.
# HTH Guide Excerpt: end cli-list-projects
