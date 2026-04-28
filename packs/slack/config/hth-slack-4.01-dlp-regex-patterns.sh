#!/usr/bin/env bash
# HTH Slack Control 4.1: DLP Regex Patterns Reference
# Profile: L1 | NIST: SI-4
# https://howtoharden.com/guides/slack/#41-configure-dlp
#
# Slack DLP patterns must be applied via the Slack Enterprise Grid admin UI
# (Security → Information Barriers / DLP rules). Slack does NOT publish a
# first-party CLI for DLP rule management; the slack-cli is for app-dev only.
#
# This script prints reference patterns ready to paste into Slack's DLP
# custom-pattern editor.

set -euo pipefail

# HTH Guide Excerpt: begin config-dlp-regex-patterns
cat <<'PATTERNS'
# Credit Card Numbers (Visa, MC, Amex, Discover)
\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12})\b

# US Social Security Numbers
\b\d{3}-\d{2}-\d{4}\b

# AWS Access Key ID
\bAKIA[A-Z0-9]{16}\b

# Generic API Key (32+ alphanumeric)
\b[A-Za-z0-9]{32,}\b
PATTERNS
# HTH Guide Excerpt: end config-dlp-regex-patterns

echo ""
echo "Apply these in Slack: Admin → Settings & permissions → DLP → Add custom pattern"
