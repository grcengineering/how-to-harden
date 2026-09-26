#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: slack-4.1
#   guide:   https://howtoharden.com/guides/slack/#41-enable-data-loss-prevention-dlp
#   profile: L2
#   mode:    read-only
#   requires: none (issues no API call)
# =============================================================================
# HTH Slack Control 4.1: DLP Regex Patterns Reference
# Profile: L2 | NIST: SC-8, SC-28
# Source: https://slack.com/help/articles/12914005852819-Slack-data-loss-prevention
#
# Slack DLP rules are created in the Enterprise admin UI (organization name →
# Tools & settings → Organization settings → Security → Data loss prevention).
# Slack publishes no DLP rule API and its first-party CLI (slack-cli) is for app
# development, so this script prints custom patterns ready to paste into
# "Use custom regular expression" (PCRE syntax). They supplement — not replace —
# Slack's preconfigured credit card, national identifier, and secrets rules.
#
# The patterns are a single-quoted literal (no here-document), so printing
# them needs no temp file.
#
# Every pattern is prefix- or structure-anchored on purpose: a bare
# "32+ alphanumeric" rule matches git commit SHAs and dashless UUIDs, and with
# the Hide action it would tombstone ordinary commit links.
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin config-dlp-regex-patterns
patterns='# Credit Card Numbers (Visa, Mastercard 51-55 and 2221-2720, Amex, Discover)
\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|2(?:22[1-9]|2[3-9][0-9]|[3-6][0-9]{2}|7[01][0-9]|720)[0-9]{12}|3[47][0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12})\b

# US Social Security Numbers
\b\d{3}-\d{2}-\d{4}\b

# AWS Access Key ID (long-term AKIA, temporary ASIA)
\b(?:AKIA|ASIA)[A-Z0-9]{16}\b

# Slack tokens (xoxb, xoxp, xoxa, xoxo, xoxs, xoxr prefixes)
\bxox[abposr]-[0-9A-Za-z-]{10,}\b

# GitHub tokens (ghp_, gho_, ghu_, ghs_, ghr_)
\bgh[pousr]_[A-Za-z0-9]{36}\b'
printf '%s\n' "${patterns}"
# HTH Guide Excerpt: end config-dlp-regex-patterns

echo ""
echo "Apply these in Slack: organization name → Tools & settings → Organization settings → Security → Data loss prevention → Create Rule → Use custom regular expression (PCRE)"
