#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: snyk-3.2
#   guide:   https://howtoharden.com/guides/snyk/#32-ignore-policy
#   profile: L2
#   mode:    mutating
#   requires: --audit-only needs nothing; the ignore path needs an authenticated snyk CLI (snyk auth) and SNYK_IGNORE_APPROVER
# =============================================================================
# HTH Snyk Control 3.2: Ignore Policy
# Profile: L2 | NIST 800-53: CM-7
# https://howtoharden.com/guides/snyk/#32-ignore-policy
#
# Governs vulnerability suppression with the first-party Snyk CLI: every
# ignore carries a human-readable reason, a named approver and an explicit
# expiry, and the resulting .snyk policy file is audited like code.
#
#   hth-snyk-3.02-governed-ignore.sh --audit-only
#       read-only: audit the .snyk policy file (no CLI, no network)
#   hth-snyk-3.02-governed-ignore.sh <snyk-issue-id> <expiry YYYY-MM-DD> <reason...>
#       write: `snyk ignore` modifies .snyk, then the same audit runs
#
# Exit codes: 0 clean | 1 finding (malformed or missing expiry, missing reason)
#             2 precondition or bad input
# Verified against:
#   https://docs.snyk.io/developer-tools/snyk-cli/commands/ignore
#   https://docs.snyk.io/scan-fix-and-prevent/fix/prioritize-issues-for-fixing/ignore-issues
set -euo pipefail

# HTH Guide Excerpt: begin cli-audit-snyk-policy-file
# Every ignore lands in the repo's .snyk policy file as:
#   ignore:
#     '<ISSUE_ID>':
#       - '*':
#           reason: <REASON>
#           expires: <EXPIRY>
# Snyk enforces an expiry only when it is a JavaScript Date Time String
# (YYYY-MM-DDThh:mm:ss.fffZ). Any other value makes the ignore persist
# indefinitely, so a malformed expiry is a finding, not a formatting nit.
POLICY_FILE="${SNYK_POLICY_FILE:-.snyk}"
EXPIRES_RE='^[0-9]+: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]{3})?Z$'

# Count lines of one kind inside the top-level `ignore:` block only.
count_in_ignore_block() {
  awk -v pat="$1" '/^ignore:/ { inb = 1; next }
    /^[^[:space:]#]/ { inb = 0 }
    inb && $0 ~ pat { n++ }
    END { print n + 0 }' "${POLICY_FILE}"
}

audit_policy_file() {
  if [ ! -f "${POLICY_FILE}" ]; then
    echo "PRECONDITION: no policy file at ${POLICY_FILE} - nothing was audited." >&2
    echo "  A repo with no CLI ignores has none; set SNYK_POLICY_FILE to audit another path." >&2
    return 2
  fi
  local entries reasons expiries bad rc=0
  entries=$(count_in_ignore_block '^[[:space:]]*- ')
  reasons=$(count_in_ignore_block '^[[:space:]]*reason:')
  expiries=$(count_in_ignore_block '^[[:space:]]*expires:')

  echo "== Suppression entries in ${POLICY_FILE} =="
  grep -nE '^[[:space:]]+(reason|expires):' "${POLICY_FILE}" || echo "No reason/expires lines recorded"
  echo "ignore entries: ${entries} | reasons: ${reasons} | expiries: ${expiries}"

  # Every expires: value inside the ignore block, quotes stripped, prefixed
  # with its line number; anything not in Date Time String form is a finding.
  bad=$(awk '/^ignore:/ { inb = 1; next }
      /^[^[:space:]#]/ { inb = 0 }
      inb && /^[[:space:]]*expires:/ {
        v = $0
        sub(/^[[:space:]]*expires:[[:space:]]*/, "", v)
        gsub(/["\047]/, "", v)
        sub(/[[:space:]]+$/, "", v)
        print NR ": " v
      }' "${POLICY_FILE}" | grep -vE "${EXPIRES_RE}" || true)
  if [ -n "${bad}" ]; then
    echo "FAIL: malformed expiry - Snyk treats these ignores as never-expiring:"
    printf '%s\n' "${bad}"
    rc=1
  fi
  if [ "${expiries}" -ne "${entries}" ]; then
    echo "FAIL: ${entries} ignore entries but ${expiries} expiries - an entry without expires: never expires"
    rc=1
  fi
  if [ "${reasons}" -ne "${entries}" ]; then
    echo "FAIL: ${entries} ignore entries but ${reasons} reasons - every ignore needs a recorded reason"
    rc=1
  fi
  [ "${rc}" -ne 0 ] || echo "OK: every ignore entry has a reason and an enforceable expiry"
  return "${rc}"
}
# HTH Guide Excerpt: end cli-audit-snyk-policy-file

# HTH Guide Excerpt: begin cli-governed-ignore
# Never ignore without a reason, an accountable approver and a bounded expiry.
# Left alone, the CLI default expiry is 30 days - set it explicitly so the
# review date is a decision, not an accident. Expiry format: YYYY-MM-DD.
DATE_RE='^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
governed_ignore() {
  local issue_id="$1" expiry="$2" reason
  shift 2
  reason="$*"
  command -v snyk >/dev/null || { echo "PRECONDITION: snyk CLI not found (npm i -g snyk)" >&2; return 2; }
  if [ -z "${SNYK_IGNORE_APPROVER:-}" ]; then
    echo "PRECONDITION: set SNYK_IGNORE_APPROVER to the person accountable for this risk acceptance" >&2
    return 2
  fi
  [[ "${expiry}" =~ ${DATE_RE} ]] || { echo "ERROR: expiry must be YYYY-MM-DD" >&2; return 2; }
  [ -n "${reason}" ] || { echo "ERROR: a human-readable reason is required" >&2; return 2; }
  snyk ignore \
    --id="${issue_id}" \
    --expiry="${expiry}" \
    --reason="${reason} (approved-by: ${SNYK_IGNORE_APPROVER})"
}
# HTH Guide Excerpt: end cli-governed-ignore

# HTH Guide Excerpt: begin cli-governed-ignore-run
usage() {
  echo "Usage: $0 --audit-only" >&2
  echo "       $0 <snyk-issue-id> <expiry YYYY-MM-DD> <reason...>" >&2
}
case "${1:-}" in
  --audit-only)
    audit_policy_file ;;
  "" | -h | --help)
    usage; exit 2 ;;
  *)
    if [ "$#" -lt 3 ]; then usage; exit 2; fi
    governed_ignore "$@"
    audit_policy_file ;;
esac
# HTH Guide Excerpt: end cli-governed-ignore-run
