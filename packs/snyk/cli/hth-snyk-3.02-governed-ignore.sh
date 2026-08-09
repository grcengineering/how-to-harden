#!/usr/bin/env bash
# HTH Snyk Control 3.2: Ignore Policy
# Profile: L2 | NIST 800-53: CM-7
# https://howtoharden.com/guides/snyk/#32-ignore-policy
#
# Governs vulnerability suppression with the first-party Snyk CLI: every
# ignore must carry a human-readable reason and an explicit expiry, and the
# resulting .snyk policy file is reviewed like code.
# Requires: snyk CLI authenticated (snyk auth).
# Verified against: https://docs.snyk.io/developer-tools/snyk-cli/snyk-cli/commands/ignore
set -euo pipefail

command -v snyk >/dev/null || { echo "ERROR: snyk CLI not found (npm i -g snyk)" >&2; exit 1; }

# HTH Guide Excerpt: begin cli-governed-ignore
# Never ignore without a reason and a bounded expiry. Left alone, the CLI
# default expiry is 30 days — set it explicitly so the review date is a
# decision, not an accident. Expiry format: YYYY-MM-DD.
ISSUE_ID="${1:?Usage: $0 <snyk-issue-id> <expiry YYYY-MM-DD> <reason...>}"
EXPIRY="${2:?Usage: $0 <snyk-issue-id> <expiry YYYY-MM-DD> <reason...>}"
shift 2
REASON="${*:?A human-readable reason is required}"

snyk ignore \
  --id="${ISSUE_ID}" \
  --expiry="${EXPIRY}" \
  --reason="${REASON} (approved-by: ${SNYK_IGNORE_APPROVER:-unset})"
# HTH Guide Excerpt: end cli-governed-ignore

# HTH Guide Excerpt: begin cli-audit-snyk-policy-file
# The ignore lands in the repo's .snyk policy file as:
#   ignore:
#     '<ISSUE_ID>':
#       - '*':
#           reason: <REASON>
#           expires: <EXPIRY>
# Audit pass for review/CI: surface every suppression with its reason and
# expiry so unbounded or unjustified ignores are visible in code review.
POLICY_FILE="${SNYK_POLICY_FILE:-.snyk}"
if [ -f "${POLICY_FILE}" ]; then
  echo "== Suppression entries in ${POLICY_FILE} =="
  grep -nE "reason:|expires:" "${POLICY_FILE}" || echo "No ignores recorded"

  IGNORES=$(grep -cE "^ignore:" "${POLICY_FILE}" || true)
  REASONS=$(grep -cE "reason:" "${POLICY_FILE}" || true)
  EXPIRIES=$(grep -cE "expires:" "${POLICY_FILE}" || true)
  echo "ignore blocks: ${IGNORES} | reasons recorded: ${REASONS} | expiries recorded: ${EXPIRIES}"
  if [ "${REASONS}" -ne "${EXPIRIES}" ]; then
    echo "WARN: reason/expiry counts differ - review ${POLICY_FILE} for unbounded ignores"
  fi
fi
# HTH Guide Excerpt: end cli-audit-snyk-policy-file
