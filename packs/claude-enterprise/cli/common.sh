#!/usr/bin/env bash
# ant v2.7.0 read-only inventory helper. Explicit first-party host and stdin key.
set -euo pipefail
anthropic_cli_inventory() (
  local resource="$1" expected_type="$2" name key="${ANTHROPIC_ADMIN_KEY:-}"
  [[ -n "${key}" && "${key}" != *[[:space:]]* ]] || { echo 'Inject the scoped inventory key.' >&2; exit 2; }
  shift 2
  command -v ant >/dev/null || { echo 'Install the official ant CLI 2.7.0+.' >&2; exit 2; }
  # A named/active profile or cloud-provider env must never silently select another tenant/host.
  for name in $(compgen -e); do
    [[ "${name}" != ANTHROPIC_* ]] || unset "${name}"
  done
  umask 077
  local evidence
  evidence=$(mktemp -d "${TMPDIR:-/tmp}/hth-ant.XXXXXXXX")
  export ANTHROPIC_CONFIG_DIR="${evidence}/config"
  mkdir -m 700 "${ANTHROPIC_CONFIG_DIR}"
  trap 'rm -f "${evidence}/inventory.pending" "${evidence}/normalized.pending"' EXIT
  local operation=(list --max-items -1)
  [[ "${expected_type}" != compliance_settings ]] || operation=(retrieve)
  printf '%s' "${key}" | ant --base-url https://api.anthropic.com --api-key-stdin --format json \
    "${resource}" "${operation[@]}" "$@" > "${evidence}/inventory.pending"
  # ant 2.7.0 emits one JSON object per item, not an array or page envelope.
  # Normalize the stream, reject duplicates, and discard partial output if ant fails.
  jq -se --arg t "${expected_type}" 'if $t=="compliance_settings" then (if length==1 and .[0].type=="compliance_settings" and (.[0].state.type=="enabled" or .[0].state.type=="disabled") then .[0] else error("Invalid recording state") end) elif $t=="spend_limits" then (if all(.[]; type=="object" and (.scope|type)=="object" and (.period|type)=="string" and has("amount")) then . else error("Invalid spend row") end) elif all(.[]; type == "object" and .type == $t and (.id | type) == "string" and (.id | length) > 0) and (map(.id) | unique | length) == length then . else error("Invalid/repeated native CLI item") end' "${evidence}/inventory.pending" > "${evidence}/normalized.pending"
  mv "${evidence}/normalized.pending" "${evidence}/inventory.json"
  printf 'Private CLI inventory (native pagination; not a policy pass): %s\n' "${evidence}/inventory.json"
  if [[ "${expected_type}" == compliance_settings ]]; then
    jq -e '.state.type=="enabled"' "${evidence}/inventory.json" >/dev/null || { echo 'Compliance recording is disabled.' >&2; exit 1; }
  fi
)
