#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-federal-3.1
#   guide: https://howtoharden.com/guides/devin-federal/#31-restrict-model-endpoints-and-credential-references
#   profile: L2
#   mode: read-only
#   requires: jq; approved model name, HTTPS base URL, key environment NAME and context limit
# Sources: https://docs.devin.ai/federal/air-gapped/models-file
# https://docs.devin.ai/federal/changelog (Nov 3 query/fragment rejection; retrieved 2026-11-05)
# HTH Guide Excerpt: begin model-policy
set +x
set -Eeuo pipefail
umask 077
unknown() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
case "${HTH_PROFILE_LEVEL:-1}" in 2|3|4) ;; *) unknown 'HTH_PROFILE_LEVEL=2..4 required before generation' ;; esac
command -v jq >/dev/null || unknown 'jq required'
[[ "${DEVIN_MODEL_NAME:-}" =~ ^[A-Za-z0-9][A-Za-z0-9._:/-]*$ ]] || unknown 'supply approved model name'
[[ "${DEVIN_MODEL_BASE_URL:-}" =~ ^https://[A-Za-z0-9][A-Za-z0-9.:-]*(/[A-Za-z0-9._~/-]*)?$ ]] || unknown 'HTTPS base URL required without credentials, query or fragment'
[[ "${DEVIN_MODEL_KEY_ENV:-}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || unknown 'supply credential environment variable NAME, not its value'
[[ "${DEVIN_MODEL_CONTEXT:-}" =~ ^[1-9][0-9]{0,8}$ ]] || unknown 'positive context token limit required'
[[ "${DEVIN_MODEL_API:-chat_completions}" == chat_completions || "${DEVIN_MODEL_API:-}" == responses ]] || unknown 'unsupported API type'
jq -n --arg name "$DEVIN_MODEL_NAME" --arg url "$DEVIN_MODEL_BASE_URL" --arg env "$DEVIN_MODEL_KEY_ENV" \
 --arg api "${DEVIN_MODEL_API:-chat_completions}" --argjson context "$DEVIN_MODEL_CONTEXT" \
 '{schema_version:0,models:[{name:$name,base_url:$url,api_key:{env:$env},api:$api,max_context_tokens:$context,default:true}]}'
printf 'EMITTED ONLY: merge reviewed model policy, protect host file and run installed devin models validate.\n' >&2
# HTH Guide Excerpt: end model-policy
