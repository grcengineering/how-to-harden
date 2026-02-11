#!/usr/bin/env bash
# malicious-idp.sh -- Incident Response: Malicious IdP Creation
# Based on How to Harden Okta Guide, Section 7.5, Runbook 3
# https://howtoharden.com/guides/okta/#75-establish-identity-incident-response-procedures
#
# Executes the containment and investigation steps for a malicious Identity
# Provider discovered in the Okta tenant. A malicious IdP enables cross-tenant
# impersonation — an attacker can authenticate as ANY user without credentials.
#
# Steps:
#   1. DEACTIVATE:   Immediately deactivate the malicious IdP
#   2. AUDIT:        Find all authentications that used the malicious IdP
#   3. REVOKE:       Revoke sessions for all users who authenticated via the IdP
#   4. INVESTIGATE:  Determine which admin created it and check for compromise
#   5. REPORT:       Output structured investigation findings
#
# Requirements:
#   - curl, jq
#   - OKTA_DOMAIN environment variable (e.g., yourorg.okta.com)
#   - OKTA_API_TOKEN environment variable (SSWS token with admin privileges)
#
# Usage:
#   export OKTA_DOMAIN="yourorg.okta.com"
#   export OKTA_API_TOKEN="00aBcDeFgHiJkLmNoPqRsTuVwXyZ"
#   ./malicious-idp.sh <IDP_ID> [--since <ISO8601_TIMESTAMP>]
#   ./malicious-idp.sh 0oa1234567890 --since 2026-02-01T00:00:00Z
#
# Output:
#   - Investigation report written to stdout as JSON
#   - Progress messages written to stderr
#   - Exit code 0 on success, 1 on error
#
# Guide reference: Section 7.5 — Runbook 3: Malicious IdP Creation

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly VERSION="1.0.0"

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

usage() {
    cat <<EOF
${SCRIPT_NAME} v${VERSION} -- Okta IR Runbook 3: Malicious IdP Creation

USAGE:
  ${SCRIPT_NAME} <IDP_ID> [OPTIONS]

ARGUMENTS:
  IDP_ID                    The Okta Identity Provider ID to investigate
                            (e.g., 0oa1234567890abcdef)

OPTIONS:
  --since <TIMESTAMP>       ISO 8601 timestamp for investigation start
                            (default: 7 days ago)
  --dry-run                 Show what would happen without making changes
  --skip-deactivate         Skip IdP deactivation (if already deactivated)
  -h, --help                Show this help message

REQUIRED ENVIRONMENT VARIABLES:
  OKTA_DOMAIN               Your Okta domain (e.g., yourorg.okta.com)
  OKTA_API_TOKEN            Okta API token with admin privileges

EXAMPLES:
  ${SCRIPT_NAME} 0oa1234567890abcdef
  ${SCRIPT_NAME} 0oa1234567890abcdef --since 2026-01-15T00:00:00Z
  ${SCRIPT_NAME} 0oa1234567890abcdef --dry-run

EOF
    exit 0
}

error() {
    echo "ERROR: $1" >&2
    exit 1
}

info() {
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] INFO: $1" >&2
}

warn() {
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARN: $1" >&2
}

check_dependencies() {
    for cmd in curl jq; do
        if ! command -v "$cmd" &>/dev/null; then
            error "${cmd} is required but not installed"
        fi
    done
}

validate_env() {
    [[ -z "${OKTA_DOMAIN:-}" ]] && error "OKTA_DOMAIN environment variable is not set"
    [[ -z "${OKTA_API_TOKEN:-}" ]] && error "OKTA_API_TOKEN environment variable is not set"
}

okta_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    local url="https://${OKTA_DOMAIN}${endpoint}"
    local args=(
        -s -S
        -X "$method"
        -H "Authorization: SSWS ${OKTA_API_TOKEN}"
        -H "Content-Type: application/json"
        -H "Accept: application/json"
    )

    if [[ -n "$data" ]]; then
        args+=(-d "$data")
    fi

    curl "${args[@]}" "$url"
}

# ---------------------------------------------------------------------------
# IR Steps
# ---------------------------------------------------------------------------

get_idp_info() {
    local idp_id="$1"
    info "Retrieving Identity Provider details for ${idp_id}..."
    okta_api GET "/api/v1/idps/${idp_id}" | jq '{
        id: .id,
        name: .name,
        type: .type,
        status: .status,
        created: .created,
        lastUpdated: .lastUpdated,
        protocol: {
            type: .protocol.type,
            issuer: (.protocol.issuer // null)
        }
    }'
}

step1_deactivate() {
    local idp_id="$1"
    local dry_run="$2"

    info "STEP 1: DEACTIVATE -- Deactivating IdP ${idp_id}"

    if [[ "$dry_run" == "true" ]]; then
        info "[DRY RUN] Would deactivate IdP ${idp_id}"
        echo '{"action": "deactivate_idp", "status": "dry_run"}'
        return
    fi

    local response
    response=$(okta_api POST "/api/v1/idps/${idp_id}/lifecycle/deactivate")

    if [[ -z "$response" ]] || echo "$response" | jq -e '.status == "INACTIVE"' &>/dev/null; then
        info "IdP ${idp_id} deactivated successfully"
        echo '{"action": "deactivate_idp", "status": "success"}'
    else
        local error_code
        error_code=$(echo "$response" | jq -r '.errorCode // empty')
        if [[ -n "$error_code" ]]; then
            warn "Deactivation returned error: ${error_code}"
            echo "$response" | jq '{action: "deactivate_idp", status: "error", details: .}'
        else
            info "IdP ${idp_id} deactivated successfully"
            echo '{"action": "deactivate_idp", "status": "success"}'
        fi
    fi
}

step2_audit_authentications() {
    local idp_id="$1"
    local since="$2"

    info "STEP 2: AUDIT -- Finding authentications via IdP ${idp_id} since ${since}"

    # Search for authentications that used this IdP
    local encoded_since
    encoded_since=$(printf '%s' "$since" | jq -sRr @uri)

    # Look for IdP-related authentication events
    local events
    events=$(okta_api GET "/api/v1/logs?filter=eventType+eq+%22user.authentication.auth_via_IDP%22&since=${encoded_since}&limit=1000")

    # Filter for events referencing this specific IdP
    local idp_auth_events
    idp_auth_events=$(echo "$events" | jq --arg idp_id "$idp_id" '[
        .[] | select(
            (.target[]? | .id == $idp_id) or
            (.debugContext.debugData.externalIdpId? == $idp_id)
        ) | {
            userId: .actor.id,
            userLogin: .actor.alternateId,
            userDisplayName: .actor.displayName,
            ipAddress: .client.ipAddress,
            city: .client.geographicalContext.city,
            country: .client.geographicalContext.country,
            published: .published,
            outcome: .outcome.result
        }
    ]')

    # Also search for IdP lifecycle events to understand creation context
    local lifecycle_events
    lifecycle_events=$(okta_api GET "/api/v1/logs?filter=eventType+sw+%22system.idp.lifecycle%22&since=${encoded_since}&limit=100")

    local idp_lifecycle
    idp_lifecycle=$(echo "$lifecycle_events" | jq --arg idp_id "$idp_id" '[
        .[] | select(.target[]? | .id == $idp_id) | {
            eventType: .eventType,
            actor: .actor.displayName,
            actorId: .actor.id,
            published: .published,
            ipAddress: .client.ipAddress
        }
    ]')

    # Extract unique affected users
    local affected_users
    affected_users=$(echo "$idp_auth_events" | jq '[.[] | {id: .userId, login: .userLogin}] | unique_by(.id)')

    local affected_count
    affected_count=$(echo "$affected_users" | jq 'length')
    info "Found ${affected_count} users who authenticated via the malicious IdP"

    if [[ "$affected_count" -gt 0 ]]; then
        warn "CRITICAL: ${affected_count} users may have been impersonated"
    fi

    jq -n \
        --argjson auth_events "$idp_auth_events" \
        --argjson lifecycle "$idp_lifecycle" \
        --argjson affected "$affected_users" \
        '{
            authentications_via_idp: $auth_events,
            idp_lifecycle_events: $lifecycle,
            affected_users: $affected,
            affected_user_count: ($affected | length)
        }'
}

step3_revoke_sessions() {
    local affected_users_json="$1"
    local dry_run="$2"

    local user_ids
    user_ids=$(echo "$affected_users_json" | jq -r '.[].id')

    local count=0
    local results="[]"

    for user_id in $user_ids; do
        count=$((count + 1))
        info "STEP 3: REVOKE -- Revoking sessions for affected user ${user_id} (${count})"

        if [[ "$dry_run" == "true" ]]; then
            info "[DRY RUN] Would revoke sessions for ${user_id}"
            results=$(echo "$results" | jq --arg uid "$user_id" '. + [{user_id: $uid, action: "revoke_sessions", status: "dry_run"}]')
            continue
        fi

        local response
        response=$(okta_api DELETE "/api/v1/users/${user_id}/sessions")

        if [[ -z "$response" ]]; then
            results=$(echo "$results" | jq --arg uid "$user_id" '. + [{user_id: $uid, action: "revoke_sessions", status: "success"}]')
        else
            local error_code
            error_code=$(echo "$response" | jq -r '.errorCode // empty')
            if [[ -n "$error_code" ]]; then
                results=$(echo "$results" | jq --arg uid "$user_id" --arg err "$error_code" '. + [{user_id: $uid, action: "revoke_sessions", status: "error", error: $err}]')
            else
                results=$(echo "$results" | jq --arg uid "$user_id" '. + [{user_id: $uid, action: "revoke_sessions", status: "success"}]')
            fi
        fi
    done

    info "Session revocation complete. Processed ${count} users."
    echo "$results"
}

step4_investigate_creator() {
    local lifecycle_events="$1"

    info "STEP 4: INVESTIGATE -- Identifying IdP creator"

    # Find the admin who created the IdP
    local creator
    creator=$(echo "$lifecycle_events" | jq 'map(select(.eventType == "system.idp.lifecycle.create")) | .[0] // {actor: "unknown", actorId: "unknown"}')

    local creator_id
    creator_id=$(echo "$creator" | jq -r '.actorId // empty')

    if [[ -n "$creator_id" && "$creator_id" != "null" && "$creator_id" != "unknown" ]]; then
        info "IdP created by user: ${creator_id}"
        warn "INVESTIGATE: Check if admin account ${creator_id} is compromised"

        # Get the creating admin's recent activity
        local admin_info
        admin_info=$(okta_api GET "/api/v1/users/${creator_id}" | jq '{
            id: .id,
            login: .profile.login,
            email: .profile.email,
            status: .status,
            lastLogin: .lastLogin
        }' 2>/dev/null || echo '{"error": "could not retrieve admin info"}')

        jq -n \
            --argjson creator "$creator" \
            --argjson admin_info "$admin_info" \
            '{
                creator: $creator,
                admin_account: $admin_info,
                recommendation: "Investigate this admin account for compromise. Run compromised-admin.sh if compromise confirmed."
            }'
    else
        warn "Could not determine IdP creator from logs"
        echo '{"creator": "unknown", "recommendation": "Expand investigation window or check audit logs manually"}'
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    local idp_id=""
    local since=""
    local dry_run=false
    local skip_deactivate=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)          usage ;;
            --since)
                [[ $# -lt 2 ]] && error "--since requires a timestamp argument"
                since="$2"
                shift 2
                ;;
            --dry-run)          dry_run=true; shift ;;
            --skip-deactivate)  skip_deactivate=true; shift ;;
            -*)                 error "Unknown option: $1" ;;
            *)
                [[ -n "$idp_id" ]] && error "Multiple IdP IDs not supported"
                idp_id="$1"
                shift
                ;;
        esac
    done

    [[ -z "$idp_id" ]] && error "IDP_ID is required. Usage: ${SCRIPT_NAME} <IDP_ID>"

    check_dependencies
    validate_env

    # Default investigation window: 7 days ago (IdP attacks may be stealthy)
    if [[ -z "$since" ]]; then
        if date --version &>/dev/null 2>&1; then
            since=$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S.000Z)
        else
            since=$(date -u -v-7d +%Y-%m-%dT%H:%M:%S.000Z)
        fi
    fi

    info "=========================================="
    info "Okta IR Runbook 3: Malicious IdP Creation"
    info "=========================================="
    info "Target IdP:   ${idp_id}"
    info "Okta domain:  ${OKTA_DOMAIN}"
    info "Since:        ${since}"
    info "Dry run:      ${dry_run}"
    info "=========================================="

    # Get IdP info
    local idp_info
    idp_info=$(get_idp_info "$idp_id")
    info "IdP: $(echo "$idp_info" | jq -r '.name') (type: $(echo "$idp_info" | jq -r '.type'))"

    # Step 1: Deactivate
    local deactivate_result='{"action": "deactivate_idp", "status": "skipped"}'
    if [[ "$skip_deactivate" == "false" ]]; then
        deactivate_result=$(step1_deactivate "$idp_id" "$dry_run")
    else
        info "STEP 1: DEACTIVATE -- Skipped (--skip-deactivate flag)"
    fi

    # Step 2: Audit authentications
    local audit_result
    audit_result=$(step2_audit_authentications "$idp_id" "$since")

    # Step 3: Revoke affected sessions
    local affected_users
    affected_users=$(echo "$audit_result" | jq '.affected_users')
    local revoke_result
    revoke_result=$(step3_revoke_sessions "$affected_users" "$dry_run")

    # Step 4: Investigate creator
    local lifecycle_events
    lifecycle_events=$(echo "$audit_result" | jq '.idp_lifecycle_events')
    local creator_result
    creator_result=$(step4_investigate_creator "$lifecycle_events")

    # Build final report
    info "Generating investigation report..."
    jq -n \
        --arg runbook "Malicious IdP Creation" \
        --arg runbook_id "7.5-3" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg idp_id "$idp_id" \
        --arg domain "$OKTA_DOMAIN" \
        --arg dry_run "$dry_run" \
        --argjson idp_info "$idp_info" \
        --argjson deactivation "$deactivate_result" \
        --argjson audit "$audit_result" \
        --argjson revocations "$revoke_result" \
        --argjson creator "$creator_result" \
        '{
            report: {
                runbook: $runbook,
                runbook_id: $runbook_id,
                generated_at: $timestamp,
                okta_domain: $domain,
                dry_run: ($dry_run == "true"),
                target_idp: {
                    id: $idp_id,
                    details: $idp_info
                }
            },
            actions: {
                deactivation: $deactivation,
                session_revocations: $revocations
            },
            investigation: {
                affected_users: $audit.affected_user_count,
                authentications_via_idp: ($audit.authentications_via_idp | length),
                idp_creator: $creator
            },
            audit_details: $audit,
            next_steps: [
                "Verify the malicious IdP is fully deactivated",
                "Review all routing rules for references to this IdP and remove them",
                "Investigate the admin who created the IdP using compromised-admin.sh",
                "Force password reset and MFA re-enrollment for all affected users",
                "Check for additional malicious IdPs created by the same admin",
                "Review authentication policies for unauthorized modifications",
                "Document incident and update IdP monitoring alerts"
            ]
        }'

    info "=========================================="
    info "IR Runbook 3 complete. Review the JSON report above."
    info "=========================================="
}

main "$@"
