#!/usr/bin/env bash
# Structural helper for the Ona Connect API packs. Download beside entrypoints.
# Source: https://ona.com/docs/api-reference (retrieved 2026-11-05).
# No request is made by sourcing this file; entrypoints call ona_init first.
# Keep stdout private: it can contain names, policy metadata or audit events.
# Redirect it from a caller using umask 077; partial evidence is never published.
# Optional ONA_OUTPUT: new absolute file in an owned mode0700 directory outside
# this checkout. Complete evidence is atomically linked as mode0600, without
# overwriting existing files. When set, stdout contains only a completion note.

ona_fail() {
  if [[ -n "${ONA_WORK_DIR:-}" ]]; then : > "$ONA_WORK_DIR/failed"; fi
  printf 'PRECONDITION: %s; no complete evidence published.\n' "$1" >&2
  exit 2
}

ona_complete() { ONA_COMPLETED=1; }

ona_finish() {
  local code="$1"
  # Command substitutions must not publish or remove their parent's staging area.
  (( BASH_SUBSHELL == 0 )) || return
  trap - EXIT
  if [[ -f "$ONA_WORK_DIR/failed" || "$ONA_COMPLETED" != 1 || "$code" -gt 1 ]]; then
    (( code > 1 )) || code=2
    printf 'PRECONDITION: incomplete operation; staged evidence discarded.\n' >&2
  else
    # Both 0 (observed posture) and 1 (completed findings) retain native output.
    if [[ -n "$ONA_OUTPUT_TARGET" ]]; then
      local private_output
      if private_output="$(mktemp "$ONA_OUTPUT_PARENT/.hth-ona-output.XXXXXX" 2> "$ONA_WORK_DIR/output-error")" &&
        [[ ! -e "$ONA_OUTPUT_TARGET" && ! -L "$ONA_OUTPUT_TARGET" ]] &&
        cat "$ONA_WORK_DIR/evidence" > "$private_output" &&
        ln "$private_output" "$ONA_OUTPUT_TARGET" 2> "$ONA_WORK_DIR/output-error"; then
        printf 'COMPLETE: private evidence saved; exit status retains the assessment result.\n' >&3
      else
        printf 'PRECONDITION: private output could not be committed; no complete evidence published.\n' >&2
        code=2
      fi
      rm -f "$private_output"
    else
      cat "$ONA_WORK_DIR/evidence" >&3 || code=2
    fi
  fi
  rm -rf "$ONA_WORK_DIR"
  exit "$code"
}

ona_init() {
  set +x
  set -euo pipefail
  ONA_WORK_DIR=''
  local minimum="$1" profile="${HTH_PROFILE_LEVEL:-1}" authority host port mode owner source_root
  if [[ ! "$profile" =~ ^[1-4]$ ]] || (( profile < minimum )); then ona_fail 'HTH_PROFILE_LEVEL is below the required profile or invalid'; fi
  command -v curl >/dev/null 2>&1 || ona_fail 'curl is required'
  command -v jq >/dev/null 2>&1 || ona_fail 'jq is required'
  [[ -n "${ONA_TOKEN:-}" && ${#ONA_TOKEN} -le 8192 && "$ONA_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || ona_fail 'inject an approved Bearer token without control characters'

  # Retain the historical pack default; current docs name app.ona.com. No redirect
  # is followed between them. Use the origin on which the token was issued.
  ONA_API_BASE="${ONA_API_BASE:-https://app.gitpod.io/api}"
  [[ "$ONA_API_BASE" =~ ^https://[A-Za-z0-9.-]+(:[0-9]{1,5})?/api$ ]] || ona_fail 'API base must be an exact HTTPS management-plane origin ending in /api'
  authority="${ONA_API_BASE#https://}"; authority="${authority%/api}"
  host="${authority%%:*}"; port="${authority#"$host"}"
  [[ "$host" != .* && "$host" != *. && "$host" != *..* && "$host" != -* && "$host" != *- ]] || ona_fail 'invalid management-plane host'
  if [[ -n "$port" ]]; then
    port="${port#:}"
    (( 10#$port >= 1 && 10#$port <= 65535 )) || ona_fail 'invalid HTTPS port'
  fi
  case "$ONA_API_BASE" in
    https://app.gitpod.io/api|https://app.ona.com/api) ;;
    *) [[ "${ONA_REVIEWED_API_BASE:-}" == "$ONA_API_BASE" ]] || ona_fail 'set ONA_REVIEWED_API_BASE to the exact independently reviewed custom base; use same-domain tokens' ;;
  esac
  ONA_MAX_PAGES="${ONA_MAX_PAGES:-200}"
  if [[ ! "$ONA_MAX_PAGES" =~ ^[1-9][0-9]{0,2}$ ]] || (( ONA_MAX_PAGES > 200 )); then ona_fail 'ONA_MAX_PAGES must be 1 to 200'; fi
  ONA_OUTPUT_TARGET=''; ONA_OUTPUT_PARENT=''
  if [[ -n "${ONA_OUTPUT:-}" ]]; then
    [[ "$ONA_OUTPUT" == /* && ! -e "$ONA_OUTPUT" && ! -L "$ONA_OUTPUT" ]] || ona_fail 'ONA_OUTPUT must be a new absolute file'
    ONA_OUTPUT_PARENT="$(cd -P "$(dirname "$ONA_OUTPUT")" 2>/dev/null && pwd)" || ona_fail 'private output parent unavailable'
    mode="$(stat -f '%Lp' "$ONA_OUTPUT_PARENT" 2>/dev/null)" || mode="$(stat -c '%a' "$ONA_OUTPUT_PARENT" 2>/dev/null)" || ona_fail 'private output permissions unavailable'
    owner="$(stat -f '%u' "$ONA_OUTPUT_PARENT" 2>/dev/null)" || owner="$(stat -c '%u' "$ONA_OUTPUT_PARENT" 2>/dev/null)" || ona_fail 'private output ownership unavailable'
    [[ "$mode" =~ ^[0-7]{3,4}$ && "$owner" == "$UID" ]] || ona_fail 'output parent must be owned by the caller'
    (( (8#$mode & 077) == 0 )) || ona_fail 'output parent must deny group and other access'
    source_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
    if [[ -e "$source_root/.git" || -f "$source_root/AGENTS.md" ]]; then
      [[ "$ONA_OUTPUT_PARENT" != "$source_root" && "$ONA_OUTPUT_PARENT" != "$source_root/"* ]] || ona_fail 'private evidence must be outside the source checkout'
    fi
    ONA_OUTPUT_TARGET="$ONA_OUTPUT_PARENT/$(basename "$ONA_OUTPUT")"
  fi
  umask 077
  ONA_WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/hth-ona.XXXXXX")" || ona_fail 'private staging directory unavailable'
  chmod 700 "$ONA_WORK_DIR"
  ONA_COMPLETED=0
  RPC_BODY='{}'; RPC_CODE=''; ORG_ID=''; ORG_TIER=''; PAGE_ITEMS='[]'
  BODY_FILE="$ONA_WORK_DIR/response"
  : > "$BODY_FILE"
  : > "$ONA_WORK_DIR/evidence"
  exec 3>&1
  exec > "$ONA_WORK_DIR/evidence"
  trap 'ona_finish "$?"' EXIT
}

# Preserve jq semantics while moving --arg/--argjson values out of process argv.
# Inputs can include opaque page tokens or response data; only private file paths
# and filters are passed to the external jq process. Parser diagnostics are private.
jq() {
  local -a args=(--monochrome-output)
  local prefix='' file name value filter='' code
  while (( $# )); do
    case "$1" in
      --arg|--argjson)
        (( $# >= 3 )) || ona_fail 'invalid local JSON arguments'
        name="$2"; value="$3"
        [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || ona_fail 'invalid local JSON binding'
        file="$(mktemp "$ONA_WORK_DIR/json.XXXXXX")" || ona_fail 'private JSON staging failed'
        printf '%s' "$value" > "$file"
        if [[ "$1" == --arg ]]; then
          args+=(--rawfile "$name" "$file")
        else
          command jq -se 'length == 1' "$file" >/dev/null 2> "$ONA_WORK_DIR/json-error" || ona_fail 'invalid single JSON binding'
          args+=(--slurpfile "$name" "$file")
          prefix+="(\$${name}[0]) as \$${name} | "
        fi
        shift 3 ;;
      -*) args+=("$1"); shift ;;
      *) filter="$1"; shift; break ;;
    esac
  done
  [[ -n "$filter" ]] || ona_fail 'missing local JSON filter'
  if command jq "${args[@]}" "$prefix$filter" "$@" 2> "$ONA_WORK_DIR/json-error"; then
    return 0
  else
    code=$?
    # jq -e false is a predicate, not a parser/transport failure.
    (( code == 1 )) && return 1
    ona_fail 'invalid JSON response or local JSON operation'
  fi
}

ona_call() {
  local method="$1" request="$2" write="${3:-0}" code
  local -a extra=(--header 'Accept: application/json')
  [[ "$method" =~ ^[A-Za-z][A-Za-z0-9]*Service/[A-Za-z][A-Za-z0-9]*$ ]] || ona_fail 'unsupported RPC path'
  # Entry points supply these literal methods; no URL or credential-disclosure
  # RPC can be selected through a response, pagination token or base override.
  if [[ "$write" == 1 ]]; then
    case "$method" in
      OrganizationService/CreateDomainVerification|OrganizationService/VerifyDomain|OrganizationService/UpdateOrganization|OrganizationService/CreateOrganizationInvite) ;;
      *) ona_fail 'unsupported write RPC' ;;
    esac
    extra+=(--request POST)
  else
    case "$method" in
      IdentityService/GetAuthenticatedIdentity|OrganizationService/GetOrganizationPolicies|OrganizationService/GetOrganization|OrganizationService/GetOrganizationInvite|OrganizationService/GetOIDCConfig|OrganizationService/ListSSOConfigurations|OrganizationService/ListDomainVerifications|OrganizationService/ListSCIMConfigurations|OrganizationService/ListMembers|GroupService/ListGroups|GroupService/ListRoleAssignments|ServiceAccountService/ListServiceAccounts|ServiceAccountService/ListServiceAccountTokens|UserService/ListPersonalAccessTokens|SecurityService/ListSecurityPolicies|IntegrationService/ListIntegrations|RunnerService/ListRunners|RunnerConfigurationService/ListLLMIntegrations|RunnerConfigurationService/ListSCMIntegrations|RunnerService/CheckAuthenticationForHost|RunnerService/CheckRepositoryAccess|SecretService/ListSecrets|EventService/ListAuditLogs|WebhookService/ListWebhooks) ;;
      *) ona_fail 'unsupported read RPC' ;;
    esac
  fi
  printf '%s' "$request" > "$ONA_WORK_DIR/request"
  command jq -se 'length == 1 and (.[0] | type == "object")' "$ONA_WORK_DIR/request" >/dev/null 2> "$ONA_WORK_DIR/json-error" || ona_fail 'invalid request object'
  : > "$BODY_FILE"
  # Auth goes through stdin config, request data through a private file; neither
  # appears in curl argv. -q is first: a user curlrc cannot enable tracing/redirects.
  if ! code=$(printf 'header = "Authorization: Bearer %s"\n' "$ONA_TOKEN" |
    command curl -q --config - --silent --proto '=https' --proto-redir '=https' \
      --tlsv1.2 --connect-timeout 10 --max-time 45 --max-filesize 10485760 \
      --max-redirs 0 --output "$BODY_FILE" --write-out '%{http_code}' \
      --header 'Content-Type: application/json' --data-binary "@$ONA_WORK_DIR/request" \
      "${extra[@]}" "$ONA_API_BASE/gitpod.v1.$method" 2> "$ONA_WORK_DIR/transport-error"); then
    if [[ "$write" == 1 ]]; then ona_fail 'transport failed or exceeded bounds; write outcome may be uncertain, do not blindly retry'; fi
    ona_fail 'transport failed or exceeded bounds'
  fi
  [[ "$code" =~ ^[0-9]{3}$ ]] || ona_fail 'invalid HTTP transport result'
  RPC_CODE="$code"
  (( $(wc -c < "$BODY_FILE") <= 10485760 )) || ona_fail 'response exceeded bounds'
  if [[ "$RPC_CODE" == 200 ]]; then
    command jq -se 'length == 1 and (.[0] | type == "object" and (has("code") | not))' "$BODY_FILE" >/dev/null 2> "$ONA_WORK_DIR/json-error" || ona_fail 'invalid successful RPC envelope'
    # These message fields are required by their generated method references;
    # unlike omitted empty repeated fields, absence cannot prove a clean state.
    # https://ona.com/docs/api-reference/generated/organization/get-organization
    # https://ona.com/docs/api-reference/generated/organization/get-organization-invite
    case "$method" in
      OrganizationService/GetOrganization)
        command jq -e '.organization | type == "object" and (.id | type == "string" and length > 0) and (.inviteDomains == null or (.inviteDomains | type == "object")) and (.inviteDomains.domains == null or (.inviteDomains.domains | type == "array" and all(.[]; type == "string")))' "$BODY_FILE" >/dev/null 2> "$ONA_WORK_DIR/json-error" || ona_fail 'required organization response incomplete' ;;
      OrganizationService/GetOrganizationInvite|OrganizationService/CreateOrganizationInvite)
        command jq -e '.invite | type == "object" and (.inviteId | type == "string" and length > 0)' "$BODY_FILE" >/dev/null 2> "$ONA_WORK_DIR/json-error" || ona_fail 'required invite response incomplete; reconcile before retrying a write' ;;
    esac
    RPC_BODY="$(cat "$BODY_FILE")"
  else
    # Only a bounded standard Connect code is retained. Never expose its message,
    # a proxy error page, request echo, URL, token or arbitrary code string.
    local safe_code
    safe_code="$(command jq -r 'if type == "object" then .code else "unknown" end' "$BODY_FILE" 2>/dev/null || true)"
    case "$safe_code" in canceled|unknown|invalid_argument|deadline_exceeded|not_found|already_exists|permission_denied|resource_exhausted|failed_precondition|aborted|out_of_range|unimplemented|internal|unavailable|data_loss|unauthenticated) ;; *) safe_code='unknown' ;; esac
    RPC_BODY="{\"code\":\"$safe_code\"}"
  fi
}

api() { ona_call "$1" "$2"; }
rpc_err() { printf '%s' "$RPC_BODY" | jq -r '.code // "unknown"'; }
rpc_msg() { printf '%s\n' 'vendor message withheld'; }
api_strict() {
  api "$1" "$2"
  [[ "$RPC_CODE" == 200 ]] || ona_fail "RPC refused (HTTP $RPC_CODE; $(rpc_err)); check origin, permission and feature eligibility"
}
ona_write_rpc() {
  ona_call "$1" "$2" 1
  [[ "$RPC_CODE" == 200 ]] || ona_fail "write refused (HTTP $RPC_CODE; $(rpc_err)); outcome unproven, reconcile before retrying"
}

# Proto3 omits empty lists. Missing/null list and nextToken mean their native
# defaults; a non-array list, non-object item or non-string cursor is a failure.
ona_page() {
  local field="$1"
  jq -e --arg field "$field" '
    type == "object" and
    (.[$field] as $items | $items == null or ($items | type == "array" and length <= 100 and all(.[]; type == "object"))) and
    (.pagination == null or (.pagination | type == "object")) and
    (.pagination.nextToken == null or (.pagination.nextToken | type == "string"))' >/dev/null <<< "$RPC_BODY" || ona_fail 'invalid page contract'
}

paginate() {
  local method="$1" base="$2" field="$3" maximum="${4:-$ONA_MAX_PAGES}" token='' req pages=0 tmp seen previous
  if [[ ! "$maximum" =~ ^[1-9][0-9]{0,2}$ ]] || (( maximum > 500 )); then ona_fail 'invalid pagination ceiling'; fi
  tmp="$(mktemp "$ONA_WORK_DIR/page.XXXXXX")"; seen="$(mktemp "$ONA_WORK_DIR/cursors.XXXXXX")"
  while :; do
    req=$(jq -nc --argjson base "$base" --arg t "$token" '$base + {pagination: ({pageSize: 100} + (if $t == "" then {} else {token: $t} end))}')
    api_strict "$method" "$req"
    ona_page "$field"
    jq -c --arg f "$field" '(.[$f] // [])[]' <<< "$RPC_BODY" >> "$tmp"
    token=$(jq -r '.pagination.nextToken // ""' <<< "$RPC_BODY")
    pages=$((pages + 1))
    [[ -n "$token" ]] || break
    (( pages < maximum )) || ona_fail 'pagination ceiling reached with more data; incomplete inventory'
    [[ "$token" != *$'\n'* && "$token" != *$'\r'* && ${#token} -le 8192 ]] || ona_fail 'invalid pagination token'
    while IFS= read -r previous; do
      [[ "$previous" != "$token" ]] || ona_fail 'repeated pagination token; incomplete inventory'
    done < "$seen"
    printf '%s\n' "$token" >> "$seen"
  done
  PAGE_ITEMS=$(jq -s '.' "$tmp")
}

resolve_org() {
  if [[ -n "${ONA_ORGANIZATION_ID:-}" ]]; then ORG_ID="$ONA_ORGANIZATION_ID"; ORG_TIER='(not read)'; return; fi
  api_strict 'IdentityService/GetAuthenticatedIdentity' '{}'
  jq -e '(.organizationId | type == "string" and length > 0) and ((.organizationTier // "") | type == "string")' >/dev/null <<< "$RPC_BODY" || ona_fail 'identity response has no valid organization'
  ORG_ID=$(jq -r '.organizationId' <<< "$RPC_BODY")
  ORG_TIER=$(jq -r '.organizationTier // "(unset)"' <<< "$RPC_BODY")
}

get_policies() {
  resolve_org
  api_strict 'OrganizationService/GetOrganizationPolicies' "$(jq -nc --arg o "$ORG_ID" '{organizationId:$o}')"
  jq -e '.policies == null or (.policies | type == "object")' >/dev/null <<< "$RPC_BODY" || ona_fail 'invalid policy response'
  POLICIES=$(jq -c '.policies // {}' <<< "$RPC_BODY")
  # Omitted proto3 defaults are valid. A supplied string "true" must never be
  # mistaken for a real Boolean by the shell's existing posture comparisons.
  jq -e '
    def optional_boolean($path): getpath($path) as $v | $v == null or ($v | type == "boolean");
    . as $policies | all([
      ["restrictAccountCreationToScim"], ["portSharingDisabled"], ["webBrowserDisabled"],
      ["maximumEnvironmentLifetimeStrict"], ["disableFromScratch"], ["membersRequireProjects"],
      ["membersCreateProjects"], ["allowLocalRunners"], ["agentPolicy","mcpDisabled"],
      ["agentPolicy","scmToolsDisabled"], ["agentPolicy","goalModeDisabled"],
      ["securityAgentPolicy","crowdstrike","enabled"]][]; . as $path | $policies | optional_boolean($path))' >/dev/null <<< "$POLICIES" || ona_fail 'invalid policy Boolean value'
}
