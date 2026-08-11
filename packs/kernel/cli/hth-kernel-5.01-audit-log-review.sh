#!/usr/bin/env bash
# Control: 5.1 Review Organization Audit Logs on a Cadence
# Profile Level: L1 (Baseline)
# Frameworks: NIST 800-53 AU-2/AU-6, CIS Controls v8 8, SOC 2 CC7.2
# Guide: https://howtoharden.com/guides/kernel/
# Interface: Kernel CLI (first-party) — https://www.kernel.sh/docs/reference/cli/audit-logs
# Plan: audit logs require Start-Up or Enterprise.
set -euo pipefail

# HTH Guide Excerpt: begin weekly-write-path-review
# Search windows are capped at 30 days. GET requests are excluded by
# default (add --include-get to reverse). Anchor the weekly review on
# write-path surfaces: keys, projects, proxies, profiles, credentials.
for surface in /org/api_keys /org/projects /proxies /profiles /auth/connections; do
  kernel audit-logs search \
    --start "$(date -v-7d +%F 2>/dev/null || date -d '7 days ago' +%F)" \
    --end   "$(date +%F)" \
    --search "${surface}" \
    --limit 500 \
    --output json
done

# --search also matches user IDs, emails, IPs, and status codes:
kernel audit-logs search \
  --start "$(date -v-7d +%F 2>/dev/null || date -d '7 days ago' +%F)" \
  --end "$(date +%F)" \
  --search 403 --output json
# HTH Guide Excerpt: end weekly-write-path-review

# HTH Guide Excerpt: begin archival-download
# Bulk export for archival/forensics: compressed JSONL, downloaded in
# batches of up to 50,000 records with per-batch SHA-256 verification.
kernel audit-logs download \
  --start "$(date -v-30d +%F 2>/dev/null || date -d '30 days ago' +%F)" \
  --end   "$(date +%F)" \
  --to "audit-$(date +%F).jsonl.gz"
# HTH Guide Excerpt: end archival-download
