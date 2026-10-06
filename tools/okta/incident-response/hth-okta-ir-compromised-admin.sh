#!/usr/bin/env bash
# compromised-admin.sh -- Incident Response: Compromised Admin Account
# Based on How to Harden Okta Guide, Section 7.5, Runbook 1
# https://howtoharden.com/guides/okta/#75-establish-identity-incident-response-procedures
#
# Executes the containment, revocation, and investigation steps for a
# compromised Okta admin account. Produces a structured investigation
# report in JSON format.
#
# Steps:
#   1. CONTAIN:     Suspend the admin account immediately
#   2. REVOKE:      Clear all active sessions
#   3. INVESTIGATE: Audit all changes made by the compromised account
#   4. REPORT:      Output structured investigation findings
#
# Requirements:
#   - curl, jq
#   - OKTA_DOMAIN environment variable (e.g., yourorg.okta.com)
#   - OKTA_API_TOKEN environment variable (SSWS token with admin privileges)
#
# Usage:
#   export OKTA_DOMAIN="yourorg.okta.com"
#   export OKTA_API_TOKEN="00aBcDeFgHiJkLmNoPqRsTuVwXyZ"
#   ./compromised-admin.sh <USER_ID> [--since <ISO8601_TIMESTAMP>]
#   ./compromised-admin.sh 00u1234567890 --since 2026-02-01T00:00:00Z
#
# Output:
#   - Investigation report written to stdout as JSON
#   - Progress messages written to stderr
#   - Exit code 0 on success, 1 on error
#
# Guide reference: Section 7.5 — Runbook 1: Compromised Admin Account

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly VERSION="1.0.0"

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

usage() {
    cat <<EOF
${SCRIPT_NAME} v${VERSION} -- Okta IR Runbook 1: Compromised Admin Account

USAGE:
  ${SCRIPT_NAME} <USER_ID> [OPTIONS]

ARGUMENTS:
  USER_ID                   The Okta user ID of the compromised admin account
                            (e.g., 00u1234567890abcdef)

OPTIONS:
  --since <TIMESTAMP>       ISO 8601 timestamp for investigation start
                            (default: 24 hours ago)
  --contain-only            Suspend and revoke sessions only; skip investigation
  --dry-run                 Show what would happen without making changes
  -h, --help                Show this help message

REQUIRED ENVIRONMENT VARIABLES:
  OKTA_DOMAIN               Your Okta domain (e.g., yourorg.okta.com)
  OKTA_API_TOKEN            Okta API token with admin privileges

EXAMPLES:
  ${SCRIPT_NAME} 00u1234567890abcdef
  ${SCRIPT_NAME} 00u1234567890abcdef --since 2026-02-01T00:00:00Z
  ${SCRIPT_NAME} 00u1234567890abcdef --dry-run

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

get_user_info() {
    local user_id="$1"
    info "Retrieving user information for ${user_id}..."
    okta_api GET "/api/v1/users/${user_id}" | jq '{
        id: .id,
        login: .profile.login,
        email: .profile.email,
        firstName: .profile.firstName,
        lastName: .profile.lastName,
        status: .status,
        lastLogin: .lastLogin,
        created: .created
    }'
}

step1_contain() {
    local user_id="$1"
    local dry_run="$2"

    info "STEP 1: CONTAIN -- Suspending admin account ${user_id}"

    if [[ "$dry_run" == "true" ]]; then
        info "[DRY RUN] Would suspend user ${user_id}"
        echo '{"action": "suspend", "status": "dry_run"}'
        return
    fi

    local response
    response=$(okta_api POST "/api/v1/users/${user_id}/lifecycle/suspend")

    if [[ -z "$response" ]]; then
        info "User ${user_id} suspended successfully"
        echo '{"action": "suspend", "status": "success"}'
    else
        local error_code
        error_code=$(echo "$response" | jq -r '.errorCode // empty')
        if [[ -n "$error_code" ]]; then
            warn "Suspend returned error: ${error_code}"
            echo "$response" | jq '{action: "suspend", status: "error", details: .}'
        else
            info "User ${user_id} suspended successfully"
            echo '{"action": "suspend", "status": "success"}'
        fi
    fi
}

step2_revoke() {
    local user_id="$1"
    local dry_run="$2"

    info "STEP 2: REVOKE -- Clearing all active sessions for ${user_id}"

    if [[ "$dry_run" == "true" ]]; then
        info "[DRY RUN] Would revoke all sessions for ${user_id}"
        echo '{"action": "revoke_sessions", "status": "dry_run"}'
        return
    fi

    local response
    response=$(okta_api DELETE "/api/v1/users/${user_id}/sessions")

    if [[ -z "$response" ]]; then
        info "All sessions revoked for ${user_id}"
        echo '{"action": "revoke_sessions", "status": "success"}'
    else
        local error_code
        error_code=$(echo "$response" | jq -r '.errorCode // empty')
        if [[ -n "$error_code" ]]; then
            warn "Session revocation returned error: ${error_code}"
            echo "$response" | jq '{action: "revoke_sessions", status: "error", details: .}'
        else
            info "All sessions revoked for ${user_id}"
            echo '{"action": "revoke_sessions", "status": "success"}'
        fi
    fi
}

step3_investigate() {
    local user_id="$1"
    local since="$2"

    info "STEP 3: INVESTIGATE -- Auditing changes by ${user_id} since ${since}"

    # Fetch all system log events for this actor
    local encoded_since
    encoded_since=$(printf '%s' "$since" | jq -sRr @uri)
    local encoded_filter
    encoded_filter=$(printf '%s' "actor.id eq \"${user_id}\"" | jq -sRr @uri)

    local events
    events=$(okta_api GET "/api/v1/logs?filter=${encoded_filter}&since=${encoded_since}&limit=1000")

    # Summarize events by type
    local event_summary
    event_summary=$(echo "$events" | jq '[.[] | .eventType] | group_by(.) | map({eventType: .[0], count: length}) | sort_by(-.count)')

    # Extract high-risk events
    local high_risk_events
    high_risk_events=$(echo "$events" | jq '[.[] | select(
        .eventType == "system.idp.lifecycle.create" or
        .eventType == "system.idp.lifecycle.activate" or
        .eventType == "policy.lifecycle.create" or
        .eventType == "policy.lifecycle.update" or
        .eventType == "policy.lifecycle.delete" or
        .eventType == "system.api_token.create" or
        .eventType == "system.role.create" or
        .eventType == "zone.lifecycle.create" or
        .eventType == "zone.lifecycle.update" or
        .eventType == "application.lifecycle.create" or
        .eventType == "group.user_membership.add"
    ) | {
        eventType: .eventType,
        target: [.target[]? | .displayName],
        published: .published,
        ipAddress: .client.ipAddress,
        outcome: .outcome.result
    }]')

    # Extract unique source IPs
    local source_ips
    source_ips=$(echo "$events" | jq '[.[] | .client.ipAddress] | unique')

    # Extract unique user agents
    local user_agents
    user_agents=$(echo "$events" | jq '[.[] | .client.userAgent.rawUserAgent] | unique')

    local total_events
    total_events=$(echo "$events" | jq 'length')
    info "Found ${total_events} events for user ${user_id}"

    local high_risk_count
    high_risk_count=$(echo "$high_risk_events" | jq 'length')
    if [[ "$high_risk_count" -gt 0 ]]; then
        warn "Found ${high_risk_count} HIGH-RISK events requiring review"
    fi

    # Return investigation results
    jq -n \
        --argjson summary "$event_summary" \
        --argjson high_risk "$high_risk_events" \
        --argjson ips "$source_ips" \
        --argjson agents "$user_agents" \
        --arg total "$total_events" \
        --arg since "$since" \
        '{
            investigation_window: $since,
            total_events: ($total | tonumber),
            event_summary: $summary,
            high_risk_events: $high_risk,
            source_ips: $ips,
            user_agents: $agents
        }'
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    local user_id=""
    local since=""
    local contain_only=false
    local dry_run=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)       usage ;;
            --since)
                [[ $# -lt 2 ]] && error "--since requires a timestamp argument"
                since="$2"
                shift 2
                ;;
            --contain-only)  contain_only=true; shift ;;
            --dry-run)       dry_run=true; shift ;;
            -*)              error "Unknown option: $1" ;;
            *)
                [[ -n "$user_id" ]] && error "Multiple user IDs not supported"
                user_id="$1"
                shift
                ;;
        esac
    done

    [[ -z "$user_id" ]] && error "USER_ID is required. Usage: ${SCRIPT_NAME} <USER_ID>"

    check_dependencies
    validate_env

    # Default investigation window: 24 hours ago
    if [[ -z "$since" ]]; then
        if date --version &>/dev/null 2>&1; then
            since=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S.000Z)
        else
            since=$(date -u -v-24H +%Y-%m-%dT%H:%M:%S.000Z)
        fi
    fi

    info "=========================================="
    info "Okta IR Runbook 1: Compromised Admin Account"
    info "=========================================="
    info "Target user:  ${user_id}"
    info "Okta domain:  ${OKTA_DOMAIN}"
    info "Since:        ${since}"
    info "Dry run:      ${dry_run}"
    info "=========================================="

    # Get user info
    local user_info
    user_info=$(get_user_info "$user_id")
    info "User: $(echo "$user_info" | jq -r '.login // .email')"

    # Step 1: Contain
    local contain_result
    contain_result=$(step1_contain "$user_id" "$dry_run")

    # Step 2: Revoke
    local revoke_result
    revoke_result=$(step2_revoke "$user_id" "$dry_run")

    # Step 3: Investigate (unless contain-only)
    local investigation_result='{"skipped": true}'
    if [[ "$contain_only" == "false" ]]; then
        investigation_result=$(step3_investigate "$user_id" "$since")
    fi

    # Build final report
    info "Generating investigation report..."
    jq -n \
        --arg runbook "Compromised Admin Account" \
        --arg runbook_id "7.5-1" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg user_id "$user_id" \
        --arg domain "$OKTA_DOMAIN" \
        --arg dry_run "$dry_run" \
        --argjson user_info "$user_info" \
        --argjson containment "$contain_result" \
        --argjson revocation "$revoke_result" \
        --argjson investigation "$investigation_result" \
        '{
            report: {
                runbook: $runbook,
                runbook_id: $runbook_id,
                generated_at: $timestamp,
                okta_domain: $domain,
                dry_run: ($dry_run == "true"),
                target_user: {
                    id: $user_id,
                    details: $user_info
                }
            },
            actions: {
                containment: $containment,
                session_revocation: $revocation
            },
            investigation: $investigation,
            next_steps: [
                "Review high-risk events for unauthorized configuration changes",
                "Reset user credentials and re-enroll MFA under verified identity",
                "Revert any unauthorized policy, IdP, or role changes",
                "Check for new API tokens or OAuth apps created by this account",
                "Notify security leadership and document in incident tracking system",
                "Reactivate account ONLY after identity re-verification"
            ]
        }'

    info "=========================================="
    info "IR Runbook 1 complete. Review the JSON report above."
    info "=========================================="
}

main "$@"
