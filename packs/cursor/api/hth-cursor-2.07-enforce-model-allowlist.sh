#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-2.7
#   guide: https://howtoharden.com/guides/cursor/#27-enforce-reviewed-model-and-inference-provider-allowlists
#   profile: L2
#   mode: mutating (explicit --apply only; default read-only plan)
#   requires: CURSOR_ADMIN_API_KEY(models:read for plan; models:* or admin:* for apply), curl, jq, bash
# Cursor preview model-access API, verified against documentation 2026-11-11.
# https://cursor.com/docs/account/teams/admin-api#model-access
# Team baseline only: NOT Organization Group grants, BYOK or a host denylist.
# Exit 0 = scoped success, 1 = findings, 2 = incomplete/error. No tenant tested.

# Usage: bash SCRIPT reviewed-policy.json [--apply]
# JSON: {"teamId":7,"models":[{"provider":"CATALOG_ID","id":"CATALOG_MODEL_ID"}]}
# IDs are not placeholders to execute: build from the GET catalog after reviewing
# actual hosts, fallback routes and processing purposes. An empty list is rejected.
# Initialize custom policy in the dashboard first; do not seed it blindly via API.
# Pause conflicting admin changes. Disable Router in the dashboard first if its
# required models are not approved. Review all group grants and BYOK separately.
# HTH Guide Excerpt: begin api-enforce-model-allowlist
set +x
set -euo pipefail
umask 077
# Never send credentials to a caller-supplied origin or follow redirects.
[ "${CURSOR_API_BASE:-https://api.cursor.com}" = "https://api.cursor.com" ] || { echo "PRECONDITION: only https://api.cursor.com is supported" >&2; exit 2; }
[[ "${CURSOR_ADMIN_API_KEY:-}" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "PRECONDITION: supply a nonempty Cursor Admin API key without config metacharacters" >&2; exit 2; }
for cmd in curl jq; do command -v "$cmd" >/dev/null || { echo "PRECONDITION: missing $cmd" >&2; exit 2; }; done
WORK=$(mktemp -d "${TMPDIR:-/tmp}/hth-cursor-models.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
fail() { echo "PRECONDITION: $*; stop and inspect current policy before retrying. Earlier writes, if any, are not rolled back." >&2; exit 2; }
api() {
  local method="$1" path="$2" body="${3:-}" code
  # Preview API: 20 requests/minute. No automatic retries of mutations.
  sleep 3.1
  if [ "$method" = GET ]; then
    code=$(printf 'user = "%s:"\n' "$CURSOR_ADMIN_API_KEY" | curl --disable --silent --show-error --config - --proto '=https' --connect-timeout 10 --max-time 45 --output "$WORK/body" --write-out '%{http_code}' "https://api.cursor.com$path" 2>/dev/null) || fail "GET transport error"
  else
    code=$(printf 'user = "%s:"\n' "$CURSOR_ADMIN_API_KEY" | curl --disable --silent --show-error --config - --proto '=https' --connect-timeout 10 --max-time 45 --request PUT --header 'Content-Type: application/json' --data "$body" --output "$WORK/body" --write-out '%{http_code}' "https://api.cursor.com$path" 2>/dev/null) || fail "PUT outcome uncertain"
  fi
  [ "$code" = 200 ] || fail "$method returned HTTP $code (400 may mean Router dependency; 401 scope; 403 entitlement; 409 non-custom policy)"
}
configuration() {
  api GET /teams/model-access/configuration
  jq -e '(.teamId|type=="number") and (.state|IN("custom","legacy","unrestricted")) and (if .state=="custom" then (.newProviderDefault|IN("enabled","disabled")) and (.newModelDefault|IN("enabled","disabled")) else true end)' "$WORK/body" >/dev/null || fail 'invalid configuration schema'
  cp "$WORK/body" "$WORK/config"
}
catalog() {
  api GET /teams/model-access/providers
  jq -e '(.state=="custom") and (.teamId|type=="number") and (.providers|type=="array" and length>0) and all(.providers[]; (.id|type=="string" and length>0) and (.enabled|type=="boolean") and (.models|type=="array") and all(.models[]; (.id|type=="string" and length>0) and (.enabled|type=="boolean"))) and ([.providers[].id]|length== (unique|length)) and all(.providers[]; [.models[].id]|length==(unique|length))' "$WORK/body" >/dev/null || fail 'invalid or empty catalog schema'
  [ "$(jq -r .teamId "$WORK/body")" = "$(jq -r .teamId "$WORK/config")" ] || fail 'catalog team mismatch'
  cp "$WORK/body" "$WORK/catalog"
}
#
[ "$#" -ge 1 ] && [ "$#" -le 2 ] || fail 'usage: SCRIPT reviewed-policy.json [--apply]'
[ "${2:-}" = '' ] || [ "${2:-}" = --apply ] || fail 'unknown option'
jq -e 'type=="object" and (.teamId|type=="number" and .>0 and floor==.) and (.models|type=="array" and length>0) and all(.models[]; (.provider|type=="string" and length>0) and (.id|type=="string" and length>0)) and ([.models[]|[.provider,.id]]|length==(unique|length))' "$1" > /dev/null || fail 'invalid reviewed policy'
cp "$1" "$WORK/desired"
configuration
[ "$(jq -r .teamId "$WORK/config")" = "$(jq -r .teamId "$WORK/desired")" ] || fail 'reviewed policy targets a different team'
[ "$(jq -r .state "$WORK/config")" = custom ] || fail 'initialize custom baseline in dashboard and review catalog first'
catalog
jq -e --slurpfile c "$WORK/catalog" 'all(.models[]; . as $m | any($c[0].providers[]; .id==$m.provider and any(.models[]; .id==$m.id)))' "$WORK/desired" >/dev/null || fail 'unknown model or provider ID'
# Explicitly write every model toggle, including currently masked/disabled models.
# Resolved flags cannot prove the underlying model override is already correct.
jq --slurpfile d "$WORK/desired" '{teamId,providers:[.providers[]|. as $p|{id,enabled:any($d[0].models[];.provider==$p.id),models:[.models[]|. as $m|{id,enabled:any($d[0].models[];.provider==$p.id and .id==$m.id)}]}]}' "$WORK/catalog" > "$WORK/plan"
echo 'PLAN: defaults disabled; explicitly reconcile every provider/model toggle; preserve model parameters.'
cat "$WORK/plan"
[ "${2:-}" = --apply ] || { echo 'READ-ONLY PLAN: no writes. Re-run with --apply only after review of group/BYOK/Router impact.'; exit 0; }
api PUT /teams/model-access/configuration '{"newProviderDefault":"disabled","newModelDefault":"disabled"}'
# Narrow before widening. No rollback: restoring a permissive baseline automatically
# after a partial failure could re-expose data. Stop, audit, and review recovery.
for enabled in false true; do
  jq -r --argjson e "$enabled" '.providers[]|. as $p|.models[]|select(.enabled==$e)|[($p.id|@uri),(.id|@uri)]|@tsv' "$WORK/plan" > "$WORK/rows"
  while IFS=$'\t' read -r provider model; do
    [ -n "$provider" ] || continue
    api PUT "/teams/model-access/providers/$provider/models/$model" "{\"enabled\":$enabled}"
  done < "$WORK/rows"
  jq -r --argjson e "$enabled" '.providers[]|select(.enabled==$e)|.id|@uri' "$WORK/plan" > "$WORK/rows"
  while IFS= read -r provider; do
    [ -n "$provider" ] || continue
    api PUT "/teams/model-access/providers/$provider" "{\"enabled\":$enabled}"
  done < "$WORK/rows"
done
configuration
jq -e '.newProviderDefault=="disabled" and .newModelDefault=="disabled"' "$WORK/config" >/dev/null || fail 'defaults read-back mismatch'
[ "$(jq -r .teamId "$WORK/config")" = "$(jq -r .teamId "$WORK/desired")" ] || fail 'team changed during apply'
catalog
jq '{teamId,providers:[.providers[]|{id,enabled,models:[.models[]|{id,enabled}]|sort_by(.id)}]|sort_by(.id)}' "$WORK/catalog" > "$WORK/actual"
jq '{teamId,providers:[.providers[]|{id,enabled,models:(.models|sort_by(.id))}]|sort_by(.id)}' "$WORK/plan" > "$WORK/expected"
cmp -s "$WORK/actual" "$WORK/expected" || fail 'catalog changed or baseline read-back mismatch'
echo 'VERIFIED: requested team baseline and defaults match. NOT proof of effective user access: inspect Organization Group grants, BYOK and integration/feature routes; test blocked requests with synthetic data.'
# HTH Guide Excerpt: end api-enforce-model-allowlist
