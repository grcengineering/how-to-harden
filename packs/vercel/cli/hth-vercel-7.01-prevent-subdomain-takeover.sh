#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 7.1: Prevent Subdomain Takeover
# Profile Level: L1 (Crawl)
# Frameworks: NIST CM-8, SC-20
# Source: https://howtoharden.com/guides/vercel/#71-prevent-subdomain-takeover
# CLI: vercel domains ls. Its human table is written to STDERR; only
#      --format json writes to stdout, so the audit parses JSON and pages with
#      --next (20 domains per page). --scope takes the team id or slug, so the
#      audit reads the team's domains, never the personal scope. Read-only.
# DNS: dig. Every lookup must succeed. A missing dig or a failed lookup ends
#      the audit with exit 2 instead of reporting "no findings" over names it
#      never checked.
# Usage: hth-vercel-7.01-prevent-subdomain-takeover.sh [dns-name ...]
#      Extra names are hostnames from YOUR DNS zone that CNAME to Vercel. A
#      record that was removed from Vercel but left in DNS -- the dangling
#      case -- is no longer in `vercel domains ls`, so pass those names here.
# Exit: 0 no finding, 1 finding, 2 the audit could not check every name.
# =============================================================================

set -euo pipefail

: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"

# HTH Guide Excerpt: begin cli

if ! command -v dig >/dev/null 2>&1; then
  echo "ERROR: dig is not installed -- no DNS record can be checked (exit 2)." >&2
  exit 2
fi

VC=(vercel --scope "${VERCEL_TEAM_ID}")

# --- Collect every domain in the team (all pages) ---
echo "=== Vercel Domain Inventory ==="
DOMAINS=""
NEXT=""
COMPLETE=0
for _page in $(seq 1 50); do
  if [ -n "${NEXT}" ]; then
    PAGE_JSON="$("${VC[@]}" domains ls --format json --next "${NEXT}")"
  else
    PAGE_JSON="$("${VC[@]}" domains ls --format json)"
  fi
  # An empty stdout (the table went to stderr) must not read as "no domains".
  if ! printf '%s' "${PAGE_JSON}" | jq -e '.domains | type == "array"' >/dev/null; then
    echo "ERROR: vercel domains ls returned no JSON domain list (exit 2)." >&2
    exit 2
  fi
  DOMAINS+="$(printf '%s' "${PAGE_JSON}" | jq -r '.domains[].name')"$'\n'
  NEXT="$(printf '%s' "${PAGE_JSON}" | jq -r '.pagination.next // empty')"
  if [ -z "${NEXT}" ] || [ "$(printf '%s' "${PAGE_JSON}" | jq '.domains | length')" -lt 20 ]; then
    COMPLETE=1
    break
  fi
done
if [ "${COMPLETE}" -ne 1 ]; then
  echo "ERROR: more than 50 pages of domains -- the inventory is incomplete (exit 2)." >&2
  exit 2
fi

# --- Add DNS names from the command line (the dangling-record case) ---
for name in "$@"; do
  if ! [[ "${name}" =~ ^[A-Za-z0-9*][A-Za-z0-9.-]*$ ]]; then
    echo "ERROR: '${name}' is not a DNS name (exit 2)." >&2
    exit 2
  fi
  DOMAINS+="${name}"$'\n'
done
DOMAINS="$(printf '%s' "${DOMAINS}" | awk 'NF && !seen[$0]++')"
TOTAL="$(printf '%s' "${DOMAINS}" | awk 'NF' | wc -l | tr -d ' ')"
printf '%s\n' "${DOMAINS}"
echo "Total: ${TOTAL} name(s)"

# --- One verdict line per name: no CNAME, not Vercel, OK, WARNING, or UNCHECKED ---
echo ""
echo "=== Checking for Dangling DNS Records ==="
FINDINGS=0
CHECKED=0
UNCHECKED=0
while IFS= read -r domain; do
  [ -n "${domain}" ] || continue
  dig_rc=0
  cname="$(dig +short +time=5 +tries=2 CNAME "${domain}" 2>/dev/null)" || dig_rc=$?
  # dig reports "no servers could be reached" on stdout with exit 9.
  if [ "${dig_rc}" -ne 0 ] || [[ "${cname}" == *";;"* ]]; then
    echo "  UNCHECKED: ${domain} -- dig failed (exit ${dig_rc})"
    UNCHECKED=$((UNCHECKED + 1))
    continue
  fi
  CHECKED=$((CHECKED + 1))
  cname_lc="$(printf '%s' "${cname}" | tr '[:upper:]' '[:lower:]')"
  case "${cname_lc}" in
    "")
      echo "  no CNAME: ${domain}" ;;
    *vercel*|*now.sh*)
      # curl prints 000 itself when it cannot connect, so its exit status is
      # ignored here rather than appending a second code to the first.
      http_code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "https://${domain}" 2>/dev/null)" || true
      [ -n "${http_code}" ] || http_code="000"
      if [ "${http_code}" = "000" ] || [ "${http_code}" = "404" ]; then
        echo "  WARNING: ${domain} has CNAME to Vercel but returns ${http_code} -- possible takeover risk!"
        FINDINGS=1
      else
        echo "  OK: ${domain} -> ${cname} (HTTP ${http_code})"
      fi ;;
    *)
      echo "  not Vercel: ${domain} -> ${cname}" ;;
  esac
done < <(printf '%s\n' "${DOMAINS}")

echo ""
echo "Checked ${CHECKED} of ${TOTAL} name(s); ${UNCHECKED} could not be checked."
if [ "${UNCHECKED}" -ne 0 ] || [ "${CHECKED}" -ne "${TOTAL}" ]; then
  echo "ERROR: the audit did not check every name (exit 2)." >&2
  exit 2
fi

# --- Remove a domain no longer in use (run deliberately, one at a time) ---
# vercel domains rm "unused-subdomain.example.com" --scope "${VERCEL_TEAM_ID}"

exit "${FINDINGS}"

# HTH Guide Excerpt: end cli
