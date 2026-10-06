#!/usr/bin/env bash
# HTH Cloudflare Control 5.2: Protect Tunnels with Access Policies
# Profile: L1 | NIST: AC-3 | CIS: 6.4
# https://howtoharden.com/guides/cloudflare/#52-protect-tunnels-with-access-policies
#
# Read-only audit. Every public hostname published by a tunnel must be covered
# by an Access application that actually enforces Access.
#   Coverage follows Access's own matching rules
#   (developers.cloudflare.com/cloudflare-one/access-controls/policies/app-paths/):
#   an application covers a whole hostname when its host matches it and its
#   path is empty or "/*"; a "*" matches within one label only, so
#   "*.example.com" covers a.example.com but not a.b.example.com; and when
#   several applications match, the most specific one decides. Substring
#   matches never count.
#   Enforcement is the pack 2.1 test: the deciding application has at least
#   one non-Bypass policy and no Bypass policy that includes Everyone.
# Counted as UNVERIFIED: tunnels whose configuration cannot be read or parsed,
# locally managed tunnels (their ingress rules are not in the API), and
# hostnames whose deciding application's policies cannot be read. The final
# PASS requires that at least one hostname was checked and none was
# unprotected or unverified.
source "$(dirname "$0")/common.sh"

banner "5.2: Protect Tunnels with Access Policies"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "5.2 Verifying tunnel endpoints have Access protection..."

# HTH Guide Excerpt: begin api-verify-tunnel-access
# Cross-reference tunnel hostnames with enforcing Access applications
TUNNELS=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/cfd_tunnel?is_deleted=false") || {
  fail "5.2 Unable to retrieve tunnels"
  increment_failed
  summary
  exit 0
}

APPS=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/access/apps") || {
  fail "5.2 Unable to retrieve Access applications"
  increment_failed
  summary
  exit 0
}

# Every whole-hostname pattern an application covers: its host as an anchored
# regex ("*" = one label's worth of characters) and its specificity (the
# number of literal characters). Path-scoped entries do not cover a hostname.
APP_COVER=$(echo "${APPS}" | jq -c '[.result[] | {id, name} as $a
  | (.domain, .self_hosted_domains[]?, (.destinations[]? | .uri?))
  | select(type == "string" and . != "") | ascii_downcase
  | (sub("/.*$"; "")) as $h
  | (if test("/") then sub("^[^/]*"; "") else "" end) as $p
  | select(($p == "" or $p == "/*") and ($h | test("^[a-z0-9.*-]+$")))
  | {id: $a.id, name: ($a.name // $a.id),
     re: ("^" + ($h | gsub("\\."; "\\.") | gsub("\\*"; "[^.]*")) + "$"),
     spec: ($h | gsub("\\*"; "") | length)}]')

# app_status <app-id>: sets APP_STATUS to enforced | bypass-everyone |
# bypass-only | no-policy | unreadable. Called as a plain statement (not in
# $(...)) so the cache survives and each application's policies are read once.
STATUS_CACHE=""
APP_STATUS=""
app_status() {
  local id=$1 pol
  APP_STATUS=$(printf '%s\n' "${STATUS_CACHE}" | awk -v id="${id}" '$1 == id { print $2; exit }')
  [ -n "${APP_STATUS}" ] && return 0
  if pol=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/access/apps/${id}/policies"); then
    APP_STATUS=$(echo "${pol}" | jq -r '.result as $p
      | if ($p | length) == 0 then "no-policy"
        elif any($p[]; .decision == "bypass" and any(.include[]?; has("everyone"))) then "bypass-everyone"
        elif (any($p[]; (.decision // "allow") != "bypass") | not) then "bypass-only"
        else "enforced" end') || APP_STATUS=unreadable
  else
    APP_STATUS=unreadable
  fi
  STATUS_CACHE="${STATUS_CACHE}
${id} ${APP_STATUS}"
}

CHECKED=0
UNPROTECTED=0
UNVERIFIED=0
while IFS= read -r tunnel; do
  TUNNEL_NAME=$(echo "${tunnel}" | jq -r '.name')
  TUNNEL_ID=$(echo "${tunnel}" | jq -r '.id')

  CONFIG=$(cf_get "/accounts/${CF_ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}/configurations") || {
    warn "5.2 Tunnel '${TUNNEL_NAME}': configuration not readable -- UNVERIFIED"
    UNVERIFIED=$((UNVERIFIED + 1))
    continue
  }
  # A locally managed tunnel keeps its ingress rules in a file on the origin
  if [ "$(echo "${CONFIG}" | jq -r 'if .result.source == "local" or (.result.config | type) != "object" then "no" else "yes" end')" != "yes" ]; then
    warn "5.2 Tunnel '${TUNNEL_NAME}': locally managed, ingress rules not in the API -- UNVERIFIED"
    UNVERIFIED=$((UNVERIFIED + 1))
    continue
  fi
  # Parse before looping: a jq failure inside `done < <(jq ...)` is silent
  HOSTNAMES=$(echo "${CONFIG}" | jq -r '(.result.config.ingress // [])
    | if type == "array" then .[] | (.hostname // empty) | ascii_downcase
      else error("ingress is not a list") end') || {
    warn "5.2 Tunnel '${TUNNEL_NAME}': configuration could not be parsed -- UNVERIFIED"
    UNVERIFIED=$((UNVERIFIED + 1))
    continue
  }

  while IFS= read -r hostname; do
    [ -z "${hostname}" ] && continue
    CHECKED=$((CHECKED + 1))
    # The most specific application(s) covering this hostname
    DECIDING=$(echo "${APP_COVER}" | jq -r --arg h "${hostname}" '[.[] | . as $e | select($h | test($e.re))]
      | (map(.spec) | max) as $m | [.[] | select(.spec == $m)] | unique_by(.id) | .[] | "\(.id)\t\(.name)"') || {
      warn "5.2 Tunnel '${TUNNEL_NAME}' hostname '${hostname}': Access coverage could not be evaluated -- UNVERIFIED"
      UNVERIFIED=$((UNVERIFIED + 1))
      continue
    }
    if [ -z "${DECIDING}" ]; then
      warn "5.2 Tunnel '${TUNNEL_NAME}' hostname '${hostname}' has NO Access application"
      UNPROTECTED=$((UNPROTECTED + 1))
      continue
    fi
    VERDICT=enforced
    BAD_APP=""
    while IFS=$'\t' read -r app_id app_name; do
      app_status "${app_id}"
      case "${APP_STATUS}" in
        enforced) ;;
        unreadable) [ "${VERDICT}" = "enforced" ] && VERDICT=unreadable ;;
        *) VERDICT="${APP_STATUS}"; BAD_APP="${app_name}" ;;
      esac
    done < <(printf '%s\n' "${DECIDING}")
    case "${VERDICT}" in
      enforced)
        info "5.2 Tunnel '${TUNNEL_NAME}' hostname '${hostname}' has Access protection" ;;
      unreadable)
        warn "5.2 Tunnel '${TUNNEL_NAME}' hostname '${hostname}': policies of its Access application could not be read -- UNVERIFIED"
        UNVERIFIED=$((UNVERIFIED + 1)) ;;
      *)
        warn "5.2 Tunnel '${TUNNEL_NAME}' hostname '${hostname}': Access application '${BAD_APP}' does not enforce Access (${VERDICT})"
        UNPROTECTED=$((UNPROTECTED + 1)) ;;
    esac
  done < <(printf '%s\n' "${HOSTNAMES}")
done < <(echo "${TUNNELS}" | jq -c '.result[]')
# HTH Guide Excerpt: end api-verify-tunnel-access

if [ "${UNPROTECTED}" -gt 0 ] || [ "${UNVERIFIED}" -gt 0 ]; then
  fail "5.2 ${UNPROTECTED} unprotected and ${UNVERIFIED} unverified tunnel endpoint(s) -- create Access applications with identity-based policies before exposing"
  increment_failed
elif [ "${CHECKED}" = "0" ]; then
  info "5.2 No published tunnel hostnames found -- nothing was checked"
  increment_skipped
else
  pass "5.2 All ${CHECKED} tunnel hostname(s) have Access protection"
  increment_applied
fi

summary
