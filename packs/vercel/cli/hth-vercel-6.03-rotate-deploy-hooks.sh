#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 6.3: Rotate Deploy Hooks
# Profile Level: L1 (Crawl)
# Frameworks: NIST IA-5, SA-15
# Source: https://howtoharden.com/guides/vercel/#63-rotate-deploy-hooks
# Rationale: Deploy Hook URLs are unauthenticated — the URL IS the credential.
# Anyone with the URL can trigger a deployment. Rotate quarterly or on team
# membership changes.
# Reference: https://vercel.com/docs/deploy-hooks
# CLI: https://vercel.com/docs/cli/deploy-hooks (vercel deploy-hooks list|create|delete).
#      The CLI reads VERCEL_TOKEN from the environment.
# Inventory and leak scan are read-only; rotation (HTH_HOOK_* set) is MUTATING.
# =============================================================================

set -euo pipefail

: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"
: "${VERCEL_PROJECT_ID:?Set VERCEL_PROJECT_ID}"

# HTH Guide Excerpt: begin cli

VC=(vercel --scope "${VERCEL_TEAM_ID}")
HOOK_URL_RE='^https://api\.vercel\.com/v1/integrations/deploy/prj_[A-Za-z0-9]+/[A-Za-z0-9]+$'

# --- 1. Inventory existing deploy hooks (the hook URL is never printed) ---
echo "=== Existing Deploy Hooks for ${VERCEL_PROJECT_ID} ==="
"${VC[@]}" deploy-hooks list --project "${VERCEL_PROJECT_ID}" --json | \
  jq '(if type == "array" then . else .hooks end)[] | {id, name, ref, createdAt}'

# --- 2. Create replacement; retire only in a SEPARATE invocation after cutover ---
# Usage: HTH_HOOK_ID=<hook_id> HTH_HOOK_NAME="ci-deploy" HTH_HOOK_REF="main" ./rotate.sh
rotate_hook() {
  local old_id="$1" name="$2" ref="$3"

  echo ""
  echo "=== Creating replacement hook: ${name} (ref: ${ref}) ==="
  local created new_id new_url url_file old_umask private_dir
  if [ -n "${HTH_HOOK_URL_FILE:-}" ]; then
    url_file="${HTH_HOOK_URL_FILE}"
    # noclobber refuses existing regular files and symlinks; the private umask
    # applies at creation, not after a window of public readability.
    old_umask="$(umask)"
    umask 077
    set -C
    exec 3> "${url_file}"
    set +C
    umask "${old_umask}"
  else
    private_dir="$(mktemp -d "${TMPDIR:-/tmp}/hth-hook.XXXXXX")"
    url_file="${private_dir}/url"
    (umask 077; set -C; : > "${url_file}")
    exec 3> "${url_file}"
  fi
  created="$("${VC[@]}" deploy-hooks create "${name}" --git-branch "${ref}" \
    --project "${VERCEL_PROJECT_ID}" --non-interactive)"
  new_id="$(echo "${created}" | jq -r '.hook.id // empty')"
  new_url="$(echo "${created}" | jq -r '.hook.url // empty')"
  if [ -z "${new_id}" ] || ! [[ "${new_url}" =~ ${HOOK_URL_RE} ]]; then
    echo "ABORT: replacement hook was not confirmed; old hook ${old_id} left in place." >&2
    return 1
  fi

  # Reserve a NEW file with noclobber, never follow/overwrite an existing path.
  # The descriptor was reserved before creation; failed creates leave it empty.
  printf '%s\n' "${new_url}" >&3
  exec 3>&-
  echo "New hook ${new_id} created; URL written to ${url_file} (mode 600)."
  echo "Old hook ${old_id} is STILL ACTIVE. Update every consumer and verify cutover."
  echo "Then rerun with HTH_RETIRE_HOOK_ID=${old_id} HTH_CONFIRM_CUTOVER=1."

}

# Phase 2 is a separate invocation after the operator verifies consumer cutover.
if [ -n "${HTH_RETIRE_HOOK_ID:-}" ]; then
  if [ "${HTH_CONFIRM_CUTOVER:-0}" != "1" ] || [ -n "${HTH_HOOK_ID:-}" ]; then
    echo "ERROR: retirement requires HTH_CONFIRM_CUTOVER=1 and cannot be combined with creation." >&2
    exit 2
  fi
  "${VC[@]}" deploy-hooks delete "${HTH_RETIRE_HOOK_ID}" --project "${VERCEL_PROJECT_ID}" --yes --non-interactive >/dev/null
  remaining="$("${VC[@]}" deploy-hooks list --project "${VERCEL_PROJECT_ID}" --json)"
  if ! printf '%s' "${remaining}" | jq -e '(if type == "array" then . else .hooks end) | type == "array"' >/dev/null; then
    echo "ERROR: retirement outcome cannot be verified from the hook response." >&2
    exit 2
  fi
  if printf '%s' "${remaining}" | jq -e --arg id "${HTH_RETIRE_HOOK_ID}" '(if type == "array" then . else .hooks end) | any(.id == $id)' >/dev/null; then
    echo "ERROR: old hook is still present." >&2
    exit 1
  fi
  echo "Old hook retired after confirmed cutover."
  exit 0
fi

if [ -n "${HTH_HOOK_ID:-}" ] && [ -n "${HTH_HOOK_NAME:-}" ] && [ -n "${HTH_HOOK_REF:-}" ]; then
  rotate_hook "${HTH_HOOK_ID}" "${HTH_HOOK_NAME}" "${HTH_HOOK_REF}"
else
  echo ""
  echo "To rotate a specific hook, rerun with:"
  echo "  HTH_HOOK_ID=<id> HTH_HOOK_NAME=<name> HTH_HOOK_REF=<branch> $0"
fi

# --- 3. Detect deploy hook URLs committed to git (lists FILES, never the URL) ---
echo ""
echo "=== Scanning tracked files for leaked deploy hook URLs ==="
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  rc=0
  leaked="$(git grep -lE 'api\.vercel\.com/v1/integrations/deploy/prj_[A-Za-z0-9]+/[A-Za-z0-9]+')" || rc=$?
  if [ "${rc}" -eq 0 ]; then
    echo "WARNING: deploy hook URL found in tracked files:"
    echo "${leaked}"
    echo "Action required: rotate these hooks and purge them from history (git-filter-repo or BFG)."
    exit 1
  elif [ "${rc}" -eq 1 ]; then
    echo "No deploy hook URLs found in tracked files."
  else
    echo "ERROR: git grep failed (exit ${rc}); the scan did not run." >&2
    exit "${rc}"
  fi
else
  echo "(Skipping — not inside a git work tree.)"
fi

# HTH Guide Excerpt: end cli
