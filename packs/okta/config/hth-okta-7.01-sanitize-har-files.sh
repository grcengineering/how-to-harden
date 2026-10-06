#!/usr/bin/env bash
# HTH Guide Excerpt: begin cli-har-sanitize-script
# har-sanitize.sh - Redact credentials and session material from a HAR file
# Usage: ./har-sanitize.sh input.har > sanitized.har
# Redacts: Cookie, Authorization, Proxy-Authorization, X-Okta-XsrfToken,
# X-CSRF-Token and X-Okta-Session request headers; Set-Cookie; all cookie
# values; token-bearing query parameters (URL, queryString, Location header);
# and token/password fields inside request and response bodies (JSON and
# form-encoded). Fails closed: if a known secret pattern survives, it prints
# nothing and exits 1.
set -euo pipefail

INPUT_FILE="${1:-}"
if [ -z "${INPUT_FILE}" ]; then
  echo "Usage: $0 <input.har>" >&2
  exit 1
fi

SANITIZED=$(jq '
  def keys_re: "sessionToken|stateToken|token|code|access_token|id_token|refresh_token|client_secret|password|passcode|answer|state|nonce";
  # key=value pairs in URLs and form bodies
  def redact_pairs: gsub("(?<k>(^|[?&;])(" + keys_re + ")=)[^&#;]*"; "\(.k)[REDACTED]");
  # "key": "value" pairs in JSON bodies
  def redact_json: gsub("(?<k>\"(" + keys_re + ")\"\\s*:\\s*)\"[^\"]*\""; "\(.k)\"[REDACTED]\"");
  def redact_text: if type == "string" then (redact_json | redact_pairs) else . end;
  .log.entries |= map(
    .request.url |= redact_text
    | .request.headers |= map(
        if (.name | test("^(cookie|authorization|proxy-authorization|x-okta-xsrftoken|x-csrf-token|x-okta-session)$"; "i"))
        then .value = "[REDACTED]" else . end)
    | .request.cookies |= map(.value = "[REDACTED]")
    | .request.queryString |= map(
        if (.name | test("^(" + keys_re + ")$"; "i")) then .value = "[REDACTED]" else . end)
    | if .request.postData then
        .request.postData.text |= redact_text
        | .request.postData.params |= (if . then map(.value = "[REDACTED]") else . end)
      else . end
    | .response.headers |= map(
        if (.name | test("^set-cookie$"; "i")) then .value = "[REDACTED]"
        elif (.name | test("^location$"; "i")) then .value |= redact_text
        else . end)
    | .response.cookies |= map(.value = "[REDACTED]")
    | .response.content.text |= redact_text
  )' "${INPUT_FILE}")

# Fail closed: never emit a file that still carries a known secret marker
if printf '%s' "${SANITIZED}" | grep -Eq 'sid=[A-Za-z0-9]|"(sessionToken|stateToken|access_token|id_token|refresh_token|password)" *: *"[^[]|Bearer [A-Za-z0-9._~+/-]{16,}|SSWS [A-Za-z0-9._-]{16,}'; then
  echo "ERROR: secret material survived sanitization -- nothing written" >&2
  exit 1
fi

printf '%s\n' "${SANITIZED}"
# HTH Guide Excerpt: end cli-har-sanitize-script
