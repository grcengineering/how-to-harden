#!/usr/bin/env bash
# HTH Vercel Control 8.5: Review Security Review Vulnerabilities
# Profile Level: L2 (Walk)
# Frameworks: NIST RA-5, SI-2
# Source: https://howtoharden.com/guides/vercel/#85-configure-security-review-and-finding-triage
# Reference: https://vercel.com/docs/cli/security
# Security Review is beta. Read-only: does not enable reviews, incur scan
# charges, dismiss vulnerabilities, or change policy. Requires existing access.
# The CLI docs specify pagination.next but not the finding-array schema.
# Store raw pages without assuming an array key or interpreting finding counts.
set -euo pipefail
: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"
# HTH Guide Excerpt: begin cli
umask 077
REPORT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/hth-security-review.XXXXXX")"
CURSOR=""
COMPLETE=0
for page in $(seq 1 100); do
  ARGS=()
  [ -z "${CURSOR}" ] || ARGS=(--next "${CURSOR}")
  vercel --scope "${VERCEL_TEAM_ID}" security vulnerabilities list \
    --status open --limit 100 --json ${ARGS[@]+"${ARGS[@]}"} > "${REPORT_DIR}/page-${page}.json"
  jq -e 'type == "object" and (has("error") | not)
    and (.pagination | type == "object" and has("next"))
    and (.pagination.next == null or (.pagination.next | type == "string" and length > 0))' \
    "${REPORT_DIR}/page-${page}.json" >/dev/null
  NEXT="$(jq -r '.pagination.next // empty' "${REPORT_DIR}/page-${page}.json")"
  if [ -z "${NEXT}" ]; then COMPLETE=1; break; fi
  if [ "${NEXT}" = "${CURSOR}" ]; then break; fi
  CURSOR="${NEXT}"
done
if [ "${COMPLETE}" != 1 ]; then
  echo "ERROR: pagination incomplete; private partial report at ${REPORT_DIR}." >&2
  exit 2
fi
echo "Raw CLI snapshot saved privately to ${REPORT_DIR} (${page} page(s))."
echo "Review the raw pages against the dashboard; finding completeness/schema are not validated."
echo "Successful retrieval does not mean no vulnerabilities."
# HTH Guide Excerpt: end cli
