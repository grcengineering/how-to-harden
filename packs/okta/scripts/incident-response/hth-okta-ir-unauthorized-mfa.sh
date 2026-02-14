#!/usr/bin/env bash
# unauthorized-mfa.sh -- Incident Response: Unauthorized MFA Enrollment
# Based on How to Harden Okta Guide, Section 7.5, Runbook 4
# https://howtoharden.com/guides/okta/#75-establish-identity-incident-response-procedures
#
# Executes the containment, investigation, and remediation steps when an
# unauthorized MFA factor is discovered on a user account. Unauthorized
# factor enrollment is a persistence technique -- attackers who gain
# temporary access immediately register their own authenticator to maintain
# access after the initial vector is closed.
#
# Steps:
#   1. REMOVE:      Delete the unauthorized MFA factor
#   2. AUDIT:       Review all account activity since the unauthorized enrollment
#   3. RESET:       Force password reset for the compromised account
#   4. REVOKE:      Clear all active sessions
#   5. REPORT:      Output structured investigation findings
#
# Requirements:
#   - curl, jq
#   - OKTA_DOMAIN environment variable (e.g., yourorg.okta.com)
#   - OKTA_API_TOKEN environment variable (SSWS token with admin privileges)
#
# Usage:
#   export OKTA_DOMAIN="yourorg.okta.com"
#   export OKTA_API_TOKEN="00aBcDeFgHiJkLmNoPqRsTuVwXyZ"
#   ./unauthorized-mfa.sh <USER_ID> <FACTOR_ID>
#   ./unauthorized-mfa.sh <USER_ID> --list-factors          # List all enrolled factors
#   ./unauthorized-mfa.sh 00u123 fuf456 --since 2026-02-01T00:00:00Z
#
# Output:
#   - Investigation report written to stdout as JSON
#   - Progress messages written to stderr
#   - Exit code 0 on success, 1 on error
#
# Guide reference: Section 7.5 — Runbook 4: Unauthorized MFA Enrollment

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly VERSION="1.0.0"

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

usage() {
    cat <<EOF
${SCRIPT_NAME} v${VERSION} -- Okta IR Runbook 4: Unauthorized MFA Enrollment

USAGE:
  ${SCRIPT_NAME} <USER_ID> <FACTOR_ID> [OPTIONS]
  ${SCRIPT_NAME} <USER_ID> --list-factors

ARGUMENTS:
  USER_ID                   The Okta user ID of the affected account
                            (e.g., 00u1234567890abcdef)
  FACTOR_ID                 The Okta factor ID to remove
                            (e.g., fuf1234567890abcdef)

OPTIONS:
  --since <TIMESTAMP>       ISO 8601 timestamp for investigation start
                            (default: 7 days ago)
  --list-factors            List all enrolled factors for the user and exit
  --skip-password-reset     Skip the forced password reset step
  --dry-run                 Show what would happen without making changes
  -h, --help                Show this help message

REQUIRED ENVIRONMENT VARIABLES:
  OKTA_DOMAIN               Your Okta domain (e.g., yourorg.okta.com)
  OKTA_API_TOKEN            Okta API token with admin privileges

EXAMPLES:
  ${SCRIPT_NAME} 00u123 --list-factors
  ${SCRIPT_NAME} 00u123 fuf456
  ${SCRIPT_NAME} 00u123 fuf456 --since 2026-01-20T00:00:00Z
  ${SCRIPT_NAME} 00u123 fuf456 --dry-run

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
# Utility Functions
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
        lastLogin: .lastLogin
    }'
}

list_factors() {
    local user_id="$1"
    info "Listing enrolled factors for ${user_id}..."
    local factors
    factors=$(okta_api GET "/api/v1/users/${user_id}/factors")

    echo "$factors" | jq '[.[] | {
        id: .id,
        factorType: .factorType,
        provider: .provider,
        status: .status,
        created: .created,
        lastUpdated: .lastUpdated,
        profile: .profile
    }]'
}

# ---------------------------------------------------------------------------
# IR Steps
# ---------------------------------------------------------------------------

step1_remove_factor() {
    local user_id="$1"
    local factor_id="$2"
    local dry_run="$3"

    info "STEP 1: REMOVE -- Deleting unauthorized factor ${factor_id} from user ${user_id}"

    if [[ "$dry_run" == "true" ]]; then
        info "[DRY RUN] Would delete factor ${factor_id} from user ${user_id}"
        echo '{"action": "remove_factor", "status": "dry_run"}'
        return
    fi

    # First, get factor details before deletion for the report
    local factor_info
    factor_info=$(okta_api GET "/api/v1/users/${user_id}/factors/${factor_id}" | jq '{
        id: .id,
        factorType: .factorType,
        provider: .provider,
        status: .status,
        created: .created,
        profile: .profile
    }' 2>/dev/null || echo '{"error": "could not retrieve factor info"}')

    local response
    response=$(okta_api DELETE "/api/v1/users/${user_id}/factors/${factor_id}")

    if [[ -z "$response" ]]; then
        info "Factor ${factor_id} removed successfully"
        jq -n --argjson factor "$factor_info" '{action: "remove_factor", status: "success", removed_factor: $factor}'
    else
        local error_code
        error_code=$(echo "$response" | jq -r '.errorCode // empty')
        if [[ -n "$error_code" ]]; then
            warn "Factor removal returned error: ${error_code}"
            echo "$response" | jq --argjson factor "$factor_info" '{action: "remove_factor", status: "error", attempted_factor: $factor, details: .}'
        else
            info "Factor ${factor_id} removed successfully"
            jq -n --argjson factor "$factor_info" '{action: "remove_factor", status: "success", removed_factor: $factor}'
        fi
    fi
}

step2_audit_activity() {
    local user_id="$1"
    local since="$2"

    info "STEP 2: AUDIT -- Reviewing account activity for ${user_id} since ${since}"

    local encoded_since
    encoded_since=$(printf '%s' "$since" | jq -sRr @uri)
    local encoded_filter
    encoded_filter=$(printf '%s' "actor.id eq \"${user_id}\"" | jq -sRr @uri)

    # Get all activity by this user
    local events
    events=$(okta_api GET "/api/v1/logs?filter=${encoded_filter}&since=${encoded_since}&limit=1000")

    # Get events targeting this user (actions performed ON the user by others)
    local encoded_target_filter
    encoded_target_filter=$(printf '%s' "target.id eq \"${user_id}\"" | jq -sRr @uri)
    local target_events
    target_events=$(okta_api GET "/api/v1/logs?filter=${encoded_target_filter}&since=${encoded_since}&limit=1000")

    # Summarize user-initiated events by type
    local event_summary
    event_summary=$(echo "$events" | jq '[.[] | .eventType] | group_by(.) | map({eventType: .[0], count: length}) | sort_by(-.count)')

    # Find MFA enrollment events (how the unauthorized factor was enrolled)
    local mfa_events
    mfa_events=$(echo "$target_events" | jq '[.[] | select(
        .eventType == "user.mfa.factor.activate" or
        .eventType == "user.mfa.factor.enroll" or
        .eventType == "user.mfa.factor.deactivate" or
        .eventType == "user.mfa.factor.reset_all" or
        .eventType == "system.mfa.factor.activate"
    ) | {
        eventType: .eventType,
        actor: .actor.displayName,
        actorId: .actor.id,
        factorType: (.target[]? | select(.type == "Factor") | .displayName),
        ipAddress: .client.ipAddress,
        userAgent: .client.userAgent.rawUserAgent,
        city: .client.geographicalContext.city,
        country: .client.geographicalContext.country,
        published: .published,
        outcome: .outcome.result
    }]')

    # Find authentication events (sessions the attacker may have used)
    local auth_events
    auth_events=$(echo "$events" | jq '[.[] | select(
        .eventType == "user.authentication.sso" or
        .eventType == "user.authentication.auth_via_mfa" or
        .eventType == "user.session.start"
    ) | {
        eventType: .eventType,
        ipAddress: .client.ipAddress,
        city: .client.geographicalContext.city,
        country: .client.geographicalContext.country,
        userAgent: .client.userAgent.rawUserAgent,
        published: .published,
        outcome: .outcome.result
    }]')

    # Find suspicious events (password changes, app access, etc.)
    local suspicious_events
    suspicious_events=$(echo "$events" | jq '[.[] | select(
        .eventType == "user.account.update_password" or
        .eventType == "user.account.reset_password" or
        .eventType == "application.user_membership.add" or
        .eventType == "group.user_membership.add"
    ) | {
        eventType: .eventType,
        target: [.target[]? | .displayName],
        ipAddress: .client.ipAddress,
        published: .published
    }]')

    # Extract unique source IPs
    local source_ips
    source_ips=$(echo "$events" | jq '[.[] | .client.ipAddress] | unique')

    local total_events
    total_events=$(echo "$events" | jq 'length')
    info "Found ${total_events} user-initiated events"

    local mfa_event_count
    mfa_event_count=$(echo "$mfa_events" | jq 'length')
    info "Found ${mfa_event_count} MFA-related events"

    jq -n \
        --argjson summary "$event_summary" \
        --argjson mfa "$mfa_events" \
        --argjson auth "$auth_events" \
        --argjson suspicious "$suspicious_events" \
        --argjson ips "$source_ips" \
        --arg total "$total_events" \
        --arg since "$since" \
        '{
            investigation_window: $since,
            total_events: ($total | tonumber),
            event_summary: $summary,
            mfa_events: $mfa,
            authentication_events: $auth,
            suspicious_events: $suspicious,
            source_ips: $ips
        }'
}

step3_reset_password() {
    local user_id="$1"
    local dry_run="$2"

    info "STEP 3: RESET -- Forcing password reset for ${user_id}"

    if [[ "$dry_run" == "true" ]]; then
        info "[DRY RUN] Would force password reset for ${user_id}"
        echo '{"action": "password_reset", "status": "dry_run"}'
        return
    fi

    local response
    response=$(okta_api POST "/api/v1/users/${user_id}/lifecycle/reset_password?sendEmail=true")

    if echo "$response" | jq -e '.resetPasswordUrl' &>/dev/null; then
        info "Password reset initiated for ${user_id}"
        echo '{"action": "password_reset", "status": "success", "note": "Reset email sent to user"}'
    else
        local error_code
        error_code=$(echo "$response" | jq -r '.errorCode // empty')
        if [[ -n "$error_code" ]]; then
            warn "Password reset returned error: ${error_code}"
            echo "$response" | jq '{action: "password_reset", status: "error", details: .}'
        else
            info "Password reset initiated for ${user_id}"
            echo '{"action": "password_reset", "status": "success"}'
        fi
    fi
}

step4_revoke_sessions() {
    local user_id="$1"
    local dry_run="$2"

    info "STEP 4: REVOKE -- Clearing all active sessions for ${user_id}"

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

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    local user_id=""
    local factor_id=""
    local since=""
    local list_factors_mode=false
    local skip_password_reset=false
    local dry_run=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)              usage ;;
            --since)
                [[ $# -lt 2 ]] && error "--since requires a timestamp argument"
                since="$2"
                shift 2
                ;;
            --list-factors)         list_factors_mode=true; shift ;;
            --skip-password-reset)  skip_password_reset=true; shift ;;
            --dry-run)              dry_run=true; shift ;;
            -*)                     error "Unknown option: $1" ;;
            *)
                if [[ -z "$user_id" ]]; then
                    user_id="$1"
                elif [[ -z "$factor_id" ]]; then
                    factor_id="$1"
                else
                    error "Unexpected argument: $1"
                fi
                shift
                ;;
        esac
    done

    [[ -z "$user_id" ]] && error "USER_ID is required. Usage: ${SCRIPT_NAME} <USER_ID> <FACTOR_ID>"

    check_dependencies
    validate_env

    # List factors mode
    if [[ "$list_factors_mode" == "true" ]]; then
        list_factors "$user_id"
        exit 0
    fi

    [[ -z "$factor_id" ]] && error "FACTOR_ID is required. Use --list-factors to see enrolled factors."

    # Default investigation window: 7 days ago
    if [[ -z "$since" ]]; then
        if date --version &>/dev/null 2>&1; then
            since=$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S.000Z)
        else
            since=$(date -u -v-7d +%Y-%m-%dT%H:%M:%S.000Z)
        fi
    fi

    info "================================================="
    info "Okta IR Runbook 4: Unauthorized MFA Enrollment"
    info "================================================="
    info "Target user:   ${user_id}"
    info "Target factor: ${factor_id}"
    info "Okta domain:   ${OKTA_DOMAIN}"
    info "Since:         ${since}"
    info "Dry run:       ${dry_run}"
    info "================================================="

    # Get user info
    local user_info
    user_info=$(get_user_info "$user_id")
    info "User: $(echo "$user_info" | jq -r '.login // .email')"

    # List all current factors for context
    local all_factors
    all_factors=$(list_factors "$user_id")
    local factor_count
    factor_count=$(echo "$all_factors" | jq 'length')
    info "User has ${factor_count} enrolled factor(s)"

    # Step 1: Remove the unauthorized factor
    local remove_result
    remove_result=$(step1_remove_factor "$user_id" "$factor_id" "$dry_run")

    # Step 2: Audit account activity
    local audit_result
    audit_result=$(step2_audit_activity "$user_id" "$since")

    # Step 3: Force password reset (unless skipped)
    local reset_result='{"action": "password_reset", "status": "skipped"}'
    if [[ "$skip_password_reset" == "false" ]]; then
        reset_result=$(step3_reset_password "$user_id" "$dry_run")
    else
        info "STEP 3: RESET -- Skipped (--skip-password-reset flag)"
    fi

    # Step 4: Revoke sessions
    local revoke_result
    revoke_result=$(step4_revoke_sessions "$user_id" "$dry_run")

    # Build final report
    info "Generating investigation report..."
    jq -n \
        --arg runbook "Unauthorized MFA Enrollment" \
        --arg runbook_id "7.5-4" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg user_id "$user_id" \
        --arg factor_id "$factor_id" \
        --arg domain "$OKTA_DOMAIN" \
        --arg dry_run "$dry_run" \
        --argjson user_info "$user_info" \
        --argjson all_factors "$all_factors" \
        --argjson removal "$remove_result" \
        --argjson audit "$audit_result" \
        --argjson reset "$reset_result" \
        --argjson revocation "$revoke_result" \
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
                },
                target_factor: $factor_id
            },
            actions: {
                factor_removal: $removal,
                password_reset: $reset,
                session_revocation: $revocation
            },
            investigation: {
                enrolled_factors_at_time_of_response: $all_factors,
                mfa_events: $audit.mfa_events,
                authentication_events: ($audit.authentication_events | length),
                suspicious_events: $audit.suspicious_events,
                source_ips: $audit.source_ips,
                event_summary: $audit.event_summary
            },
            next_steps: [
                "Verify the unauthorized factor has been removed",
                "Contact the user to verify their identity before MFA re-enrollment",
                "Investigate how the enrollment occurred (account takeover, helpdesk social engineering)",
                "Check if the enrollment IP/user-agent matches known attacker infrastructure",
                "Review all applications accessed during the compromise window",
                "Check for data exfiltration from accessed applications",
                "Re-enroll legitimate MFA factors under verified identity only",
                "Enable end-user notifications if not already active (Section 1.11)"
            ]
        }'

    info "================================================="
    info "IR Runbook 4 complete. Review the JSON report above."
    info "================================================="
}

main "$@"
