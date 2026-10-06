#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: okta-7.2
#   guide:   https://howtoharden.com/guides/okta/#72-monitor-okta-security-advisories
#   profile: L1
#   mode:    read-only
#   requires: none (reads Okta's public advisory feed; no Okta credential)
# =============================================================================
# HTH Okta Control 7.2: Monitor Okta Security Advisories
# Profile: L1 | NIST: SI-5, RA-5
# https://howtoharden.com/guides/okta/#72-monitor-okta-security-advisories
#
# Reads Okta's public security-advisory RSS feed -- the "Subscribe to RSS Feed"
# link on https://trust.okta.com/security-advisories/ -- and lists advisories
# published in the last N days (default 30). No Okta credentials are needed.
# Exits 1 when the feed cannot be fetched or parsed, parses to zero items, or
# holds an item whose pubDate cannot be read: an unread feed is never reported
# as "no new advisories".
#
# Dependencies: curl, xmllint (libxml2), jq
# Usage: bash hth-okta-7.02-monitor-okta-security-advisories.sh [days]
set -euo pipefail

FEED="https://trust.okta.com/security-advisories.xml"
DAYS="${1:-30}"

die() { echo "[FAIL] 7.2 $1" >&2; exit 1; }

[[ "${DAYS}" =~ ^[0-9]+$ ]] || die "days must be a whole number, got '${DAYS}'"
for tool in curl xmllint jq; do
  command -v "${tool}" > /dev/null || die "${tool} is required"
done

# HTH Guide Excerpt: begin api-list-recent-advisories
# --fail turns an HTTP error (404, 5xx) into a non-zero exit instead of a body
FEED_XML=$(curl -sS --fail --max-time 30 -A "hth-okta-advisory-monitor" "${FEED}") \
  || die "could not fetch ${FEED}"

COUNT=$(printf '%s' "${FEED_XML}" | xmllint --xpath 'count(/rss/channel/item)' - 2> /dev/null) \
  || die "${FEED} is not well-formed XML"
[[ "${COUNT}" =~ ^[0-9]+$ ]] && [ "${COUNT}" -gt 0 ] \
  || die "feed parsed but held no advisories -- not reporting 'nothing new'"

# One tab-separated line per advisory: pubDate, title, link
# (normalize-space folds any tab or newline inside a field into a space)
TAB=$'\t'
ROWS=$(for i in $(seq 1 "${COUNT}"); do
  printf '%s' "${FEED_XML}" | xmllint --xpath "concat(
    normalize-space(/rss/channel/item[${i}]/pubDate), '${TAB}',
    normalize-space(/rss/channel/item[${i}]/title), '${TAB}',
    normalize-space(/rss/channel/item[${i}]/link))" - || exit 1
  printf '\n'
done) || die "could not read the items in ${FEED}"

# jq stops with an error (and this script with exit 1) on a pubDate it cannot parse
REPORT=$(printf '%s\n' "${ROWS}" | jq -R -s -r --argjson days "${DAYS}" '
  [split("\n")[] | select(length > 0) | split("\t")
   | {date: .[0], title: .[1], link: .[2],
      epoch: (.[0] | sub(" (GMT|UTC|[+]0000)$"; "")
                   | strptime("%a, %d %b %Y %H:%M:%S") | mktime)}] as $items
  | (now - $days * 86400) as $cutoff
  | [$items[] | select(.epoch >= $cutoff)] | sort_by(-.epoch) as $recent
  | "[INFO] 7.2 \($items | length) advisories in the feed; \($recent | length) published in the last \($days) days",
    ($recent[] | "  - \(.epoch | strftime("%Y-%m-%d")) \(.title)\n    \(.link)")') \
  || die "an advisory in ${FEED} has a pubDate that could not be read"

printf '%s\n' "${REPORT}"
# HTH Guide Excerpt: end api-list-recent-advisories
