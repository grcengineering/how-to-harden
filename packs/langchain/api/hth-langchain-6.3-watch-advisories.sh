#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: langchain-6.3
#   guide:   https://howtoharden.com/guides/langchain/#63-monitor-for-cve-disclosures
#   profile: L1
#   mode:    read-only
#   requires: HTH_ADVISORY_WATERMARK(YYYY-MM-DD of your last advisory review), GH_TOKEN(optional; only raises the GitHub rate limit, no scopes needed)
# =============================================================================
# HTH LangChain Control 6.3: Monitor for CVE Disclosures
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 SI-5 | SOC 2 CC7.1
# Dependencies: curl, jq
#
# Read-only GitHub REST call against the repository security-advisories endpoint:
#   GET https://api.github.com/repos/{owner}/{repo}/security-advisories
#   https://docs.github.com/en/rest/security-advisories/repository-advisories
# Exits 1 when an advisory published after the watermark exists, so a scheduled CI job
# turns a new LangChain disclosure into a red build instead of an unread email.
#
# Why the API and not the web page: a plain fetch of GitHub's HTML advisories list
# returns only the first few rows, so a scrape of it can miss advisories. The API
# returns them all (up to per_page; this pack fails rather than read a full page).

set -euo pipefail

: "${HTH_ADVISORY_WATERMARK:?Set HTH_ADVISORY_WATERMARK (YYYY-MM-DD of your last advisory review)}"

# HTH Guide Excerpt: begin api-watch-langchain-advisories
new=0
for repo in langchain langgraph langsmith-sdk; do
  body=$(curl -sf "https://api.github.com/repos/langchain-ai/${repo}/security-advisories?per_page=100" \
    -H "Accept: application/vnd.github+json" ${GH_TOKEN:+-H "Authorization: Bearer ${GH_TOKEN}"})
  total=$(printf '%s' "${body}" | jq 'if type == "array" then length else error("expected an array") end')
  # A full page means there may be more: fail rather than silently watch page one only
  [ "${total}" -lt 100 ] || { echo "langchain-ai/${repo}: 100+ advisories - add pagination" >&2; exit 2; }
  fresh=$(printf '%s' "${body}" | jq -r --arg since "${HTH_ADVISORY_WATERMARK}" \
    '.[] | select(.published_at != null and .published_at[0:10] > $since)
     | "\(.published_at[0:10]) \(.severity) \(.ghsa_id) \(.cve_id // "no-CVE") \(.summary)"')
  echo "langchain-ai/${repo}: ${total} published advisories"
  if [ -n "${fresh}" ]; then
    printf '%s\n' "${fresh}" | sed "s/^/  NEW since ${HTH_ADVISORY_WATERMARK}: /"
    new=1
  fi
done
exit "${new}"
# HTH Guide Excerpt: end api-watch-langchain-advisories
