#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: n8n-3.3
#   guide: https://howtoharden.com/guides/n8n/#33-audit-the-estate-monitor-changes-and-maintain-versions
#   profile: L1
#   mode: read-only
#   requires: installed n8n CLI and existing instance database configuration
# HTH 3.3: Read-only first-party n8n security audit
# Profile: L1 (Crawl); NIST 800-53 CM-8, SI-2
# Source: https://docs.n8n.io/deploy/host-n8n/configure-n8n/security/run-security-audits.md
# Run inside the configured n8n instance environment, never against a new empty database.
# Output can reveal sensitive configuration; store only in restricted audit storage.
# HTH Guide Excerpt: begin security-audit
set -euo pipefail
case "${HTH_PROFILE_LEVEL:-1}" in 1|2|3|4) ;; *) echo 'HTH_PROFILE_LEVEL must be 1, 2, 3, or 4' >&2; exit 2;; esac
umask 077
command -v n8n >/dev/null || { echo 'Installed n8n CLI required' >&2; exit 1; }
exec n8n audit
# HTH Guide Excerpt: end security-audit
