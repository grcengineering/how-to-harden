#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-2.2
#   guide: https://howtoharden.com/guides/cursor/#22-govern-model-selection-with-cursor-router
#   profile: L2
#   mode: read-only
#   requires: CURSOR_ADMIN_API_KEY(models:read or admin:*), curl, jq, bash
# Cursor preview model-access API, verified against documentation 2026-11-11.
# https://cursor.com/docs/account/teams/admin-api#model-access
# Team baseline only: NOT Organization Group grants, BYOK or a host denylist.
# Exit 0 = scoped success, 1 = findings, 2 = incomplete/error. No tenant tested.
# HTH Guide Excerpt: begin api-audit-model-access
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
    code=$(printf 'user = "%s:"\n' "$CURSOR_ADMIN_API_KEY" | curl --disable --silent --show-error --config - --proto '=https' --connect-timeout 10 --max-time 45 --output "$WORK/body" --write-out '%{http_code}' "https://api.cursor.com$path" 2>/dev/null) || fail "GET transport error"
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
configuration
state=$(jq -r .state "$WORK/config")
if [ "$state" != custom ]; then
  echo "FINDING: policy state=$state; no custom baseline audited (legacy is not equivalent to unrestricted)"
  exit 1
fi
catalog
jq '{teamId,state,newProviderDefault,newModelDefault}' "$WORK/config"
jq '{teamId,providers:[.providers[]|{id,enabled,models:[.models[]|{id,enabled,parameters}]}]}' "$WORK/catalog"
if ! jq -e '.newProviderDefault=="disabled" and .newModelDefault=="disabled"' "$WORK/config" >/dev/null; then
  echo 'FINDING: new providers AND new models must default to disabled pending approval'
  exit 1
fi
echo 'BASELINE CHECK ONLY: custom policy and disabled defaults. Review catalog against approved models; inspect ALL Organization Group grants and team BYOK separately. This is not an effective-access or inference-host PASS.'
# HTH Guide Excerpt: end api-audit-model-access
