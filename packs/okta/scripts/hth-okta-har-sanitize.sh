#!/usr/bin/env bash
# HTH Okta Code Pack — HAR File Sanitizer
# https://howtoharden.com/guides/okta/#71-sanitize-har-files-before-sharing
#
# Strips sensitive data from HTTP Archive (HAR) files before sharing with
# Okta support or any third party. Prevents session token theft as seen
# in the October 2023 Okta breach (134 customers affected via HAR files).
#
# Removes:
#   - Cookie / Set-Cookie headers
#   - Authorization / Bearer headers
#   - X-CSRF-Token / X-Okta-Session headers
#   - All request/response cookie values
#   - SSWS tokens and session IDs in URL parameters
#   - POST body fields containing tokens, passwords, or secrets
#
# Requirements: jq (https://jqlang.github.io/jq/)
#
# Usage:
#   ./har-sanitize.sh input.har                     # writes to input.sanitized.har
#   ./har-sanitize.sh input.har -o output.har       # writes to output.har
#   ./har-sanitize.sh input.har --verify            # sanitize + verify no tokens remain
#   cat input.har | ./har-sanitize.sh -             # read from stdin, write to stdout
#
# Guide reference: Section 7.1 — Sanitize HAR Files Before Sharing

set -euo pipefail

# --- Constants ---------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly VERSION="1.0.0"
readonly REDACTED="[REDACTED-BY-HTH]"

# Sensitive header names (case-insensitive matching in jq)
readonly SENSITIVE_HEADERS_PATTERN='^(Cookie|Authorization|X-CSRF-Token|X-Okta-Session|X-Forwarded-For|X-Real-IP|Set-Cookie|X-Okta-Request-Id)$'

# Sensitive patterns to search for in verification
readonly SENSITIVE_PATTERNS=(
  'sid='
  'sessionToken'
  'Bearer '
  'SSWS '
  'DT='
  'JSESSIONID'
  '_xsrfToken'
  'okta_session'
  'idx='
)

# --- Functions ---------------------------------------------------------------

usage() {
  cat <<EOF
${SCRIPT_NAME} v${VERSION} — HTH Okta HAR File Sanitizer

Strips sensitive data (session tokens, cookies, auth headers) from HAR files
before sharing with Okta support or any third party.

USAGE:
  ${SCRIPT_NAME} <input.har> [OPTIONS]
  cat input.har | ${SCRIPT_NAME} - [OPTIONS]

ARGUMENTS:
  <input.har>    Path to the HAR file to sanitize (use '-' for stdin)

OPTIONS:
  -o, --output <file>    Write sanitized output to <file>
                         Default: <input>.sanitized.har
  --stdout               Write sanitized output to stdout
  --verify               After sanitizing, verify no sensitive tokens remain
  --dry-run              Show what would be redacted without writing output
  -h, --help             Show this help message
  -v, --version          Show version

EXAMPLES:
  ${SCRIPT_NAME} troubleshooting.har
  ${SCRIPT_NAME} troubleshooting.har -o clean.har --verify
  ${SCRIPT_NAME} troubleshooting.har --dry-run
  cat troubleshooting.har | ${SCRIPT_NAME} - --stdout

CONTEXT:
  October 2023 Okta Breach: Unsanitized HAR files uploaded to Okta's support
  system contained active session cookies. Attackers exfiltrated these tokens
  to hijack sessions for 134 customers. ALWAYS sanitize before sharing.

EOF
  exit 0
}

version() {
  echo "${SCRIPT_NAME} v${VERSION}"
  exit 0
}

error() {
  echo "ERROR: $1" >&2
  exit 1
}

warn() {
  echo "WARNING: $1" >&2
}

info() {
  echo "INFO: $1" >&2
}

check_dependencies() {
  if ! command -v jq &>/dev/null; then
    error "jq is required but not installed. Install it:
  macOS:   brew install jq
  Ubuntu:  sudo apt-get install jq
  RHEL:    sudo yum install jq
  Windows: choco install jq"
  fi

  # Verify jq version supports the features we need
  local jq_version
  jq_version=$(jq --version 2>&1 | sed 's/jq-//')
  info "Using jq ${jq_version}"
}

validate_har() {
  local input="$1"

  if [[ "$input" == "-" ]]; then
    return 0  # Skip validation for stdin
  fi

  if [[ ! -f "$input" ]]; then
    error "File not found: ${input}"
  fi

  if [[ ! -r "$input" ]]; then
    error "File not readable: ${input}"
  fi

  # Verify it's valid JSON with HAR structure
  if ! jq -e '.log.entries' "$input" &>/dev/null; then
    error "Invalid HAR file: missing .log.entries structure"
  fi

  local entry_count
  entry_count=$(jq '.log.entries | length' "$input")
  info "HAR file contains ${entry_count} entries"
}

sanitize_har() {
  local input="$1"

  local jq_filter
  jq_filter=$(cat <<'JQFILTER'
    # Redact sensitive request headers
    .log.entries[].request.headers |= map(
      if (.name | test("^(Cookie|Authorization|X-CSRF-Token|X-Okta-Session|X-Forwarded-For|X-Real-IP)$"; "i"))
      then .value = "[REDACTED-BY-HTH]"
      else .
      end
    ) |

    # Redact sensitive response headers
    .log.entries[].response.headers |= map(
      if (.name | test("^(Set-Cookie|X-Okta-Request-Id)$"; "i"))
      then .value = "[REDACTED-BY-HTH]"
      else .
      end
    ) |

    # Redact all request cookie values
    .log.entries[].request.cookies |= map(.value = "[REDACTED-BY-HTH]") |

    # Redact all response cookie values
    .log.entries[].response.cookies |= map(.value = "[REDACTED-BY-HTH]") |

    # Redact query string parameters that may contain tokens
    .log.entries[].request.queryString |= map(
      if (.name | test("^(token|sessionToken|access_token|id_token|code|state|nonce|sid)$"; "i"))
      then .value = "[REDACTED-BY-HTH]"
      else .
      end
    ) |

    # Redact POST body params that may contain credentials
    (.log.entries[].request.postData.params // []) |= map(
      if (.name | test("^(password|token|secret|credential|sessionToken|access_token)$"; "i"))
      then .value = "[REDACTED-BY-HTH]"
      else .
      end
    )
JQFILTER
  )

  if [[ "$input" == "-" ]]; then
    jq "$jq_filter"
  else
    jq "$jq_filter" "$input"
  fi
}

verify_sanitized() {
  local file="$1"
  local found_sensitive=false

  info "Verifying sanitized file for residual sensitive data..."

  for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if grep -qi "$pattern" "$file" 2>/dev/null; then
      # Check if it's just our redaction marker
      local matches
      matches=$(grep -ci "$pattern" "$file" 2>/dev/null || true)
      local redacted_matches
      redacted_matches=$(grep -c "REDACTED-BY-HTH" "$file" 2>/dev/null || true)

      # Only warn if there are matches outside of redaction context
      if grep -v "REDACTED-BY-HTH" "$file" | grep -qi "$pattern" 2>/dev/null; then
        warn "Potential sensitive data found: pattern '${pattern}' (${matches} occurrences)"
        found_sensitive=true
      fi
    fi
  done

  if [[ "$found_sensitive" == "true" ]]; then
    warn "Review the output file manually — some sensitive data may remain in response bodies or non-standard headers"
    return 1
  else
    info "PASS: No sensitive token patterns detected in sanitized output"
    return 0
  fi
}

dry_run() {
  local input="$1"

  info "DRY RUN — Analyzing sensitive data in ${input}"
  echo ""

  echo "=== Sensitive Request Headers ==="
  jq -r '
    [.log.entries[].request.headers[] |
     select(.name | test("^(Cookie|Authorization|X-CSRF-Token|X-Okta-Session)$"; "i"))] |
    group_by(.name) |
    .[] | "\(.[0].name): \(length) occurrence(s)"
  ' "$input" 2>/dev/null || echo "  (none found)"

  echo ""
  echo "=== Sensitive Response Headers ==="
  jq -r '
    [.log.entries[].response.headers[] |
     select(.name | test("^(Set-Cookie)$"; "i"))] |
    group_by(.name) |
    .[] | "\(.[0].name): \(length) occurrence(s)"
  ' "$input" 2>/dev/null || echo "  (none found)"

  echo ""
  echo "=== Request Cookies ==="
  local cookie_count
  cookie_count=$(jq '[.log.entries[].request.cookies[]] | length' "$input" 2>/dev/null || echo "0")
  echo "  ${cookie_count} cookie(s) would be redacted"

  echo ""
  echo "=== Response Cookies ==="
  local resp_cookie_count
  resp_cookie_count=$(jq '[.log.entries[].response.cookies[]] | length' "$input" 2>/dev/null || echo "0")
  echo "  ${resp_cookie_count} cookie(s) would be redacted"

  echo ""
  echo "=== Sensitive Query Parameters ==="
  jq -r '
    [.log.entries[].request.queryString[] //empty |
     select(.name | test("^(token|sessionToken|access_token|id_token|code|sid)$"; "i"))] |
    group_by(.name) |
    .[] | "\(.[0].name): \(length) occurrence(s)"
  ' "$input" 2>/dev/null || echo "  (none found)"

  echo ""
  info "Run without --dry-run to sanitize"
}

# --- Main --------------------------------------------------------------------

main() {
  local input=""
  local output=""
  local use_stdout=false
  local verify=false
  local dry_run_mode=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)    usage ;;
      -v|--version) version ;;
      -o|--output)
        [[ $# -lt 2 ]] && error "--output requires a filename argument"
        output="$2"
        shift 2
        ;;
      --stdout)     use_stdout=true; shift ;;
      --verify)     verify=true; shift ;;
      --dry-run)    dry_run_mode=true; shift ;;
      -*)           error "Unknown option: $1. Use --help for usage." ;;
      *)
        [[ -n "$input" ]] && error "Multiple input files not supported"
        input="$1"
        shift
        ;;
    esac
  done

  # Validate input
  [[ -z "$input" ]] && error "No input file specified. Use --help for usage."

  check_dependencies
  validate_har "$input"

  # Dry run mode
  if [[ "$dry_run_mode" == "true" ]]; then
    [[ "$input" == "-" ]] && error "--dry-run requires a file path, not stdin"
    dry_run "$input"
    exit 0
  fi

  # Determine output destination
  if [[ "$use_stdout" == "true" ]]; then
    sanitize_har "$input"
  else
    if [[ -z "$output" ]]; then
      if [[ "$input" == "-" ]]; then
        # stdin mode without explicit output goes to stdout
        sanitize_har "$input"
        exit 0
      fi
      output="${input%.har}.sanitized.har"
    fi

    info "Sanitizing ${input} -> ${output}"
    sanitize_har "$input" > "$output"
    info "Sanitized HAR written to ${output}"

    local orig_size new_size
    if [[ "$input" != "-" ]]; then
      orig_size=$(wc -c < "$input" | tr -d '[:space:]')
      new_size=$(wc -c < "$output" | tr -d '[:space:]')
      info "Size: ${orig_size} bytes -> ${new_size} bytes"
    fi

    # Verification
    if [[ "$verify" == "true" ]]; then
      if verify_sanitized "$output"; then
        info "Verification PASSED — file is safe to share"
      else
        warn "Verification found potential issues — review output manually"
        exit 2
      fi
    fi
  fi
}

main "$@"
