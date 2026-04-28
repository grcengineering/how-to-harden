#!/bin/bash
# HTH Guide Excerpt: begin cli-har-sanitize-script
# har-sanitize.sh - Strip sensitive headers from HAR files
# Usage: ./har-sanitize.sh input.har > sanitized.har

INPUT_FILE="$1"
if [ -z "$INPUT_FILE" ]; then
  echo "Usage: $0 <input.har>"
  exit 1
fi

jq '
  .log.entries[].request.headers |= map(
    if (.name | test("^(Cookie|Authorization|X-CSRF-Token|X-Okta-Session)$"; "i"))
    then .value = "[REDACTED]"
    else .
    end
  ) |
  .log.entries[].response.headers |= map(
    if (.name | test("^(Set-Cookie)$"; "i"))
    then .value = "[REDACTED]"
    else .
    end
  ) |
  .log.entries[].request.cookies |= map(.value = "[REDACTED]") |
  .log.entries[].response.cookies |= map(.value = "[REDACTED]")
' "$INPUT_FILE"
# HTH Guide Excerpt: end cli-har-sanitize-script
