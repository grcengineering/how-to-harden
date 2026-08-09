#!/usr/bin/env bash
# HTH Keeper Control 5.2: Monitor Security Audit
# Profile: L1 | CIS Controls: 4.1 | NIST 800-53: CA-7
# https://howtoharden.com/guides/keeper/#52-monitor-security-audit
#
# Interface: Keeper Commander CLI (first-party).
#   security-audit-report / user-report: https://docs.keeper.io/en/keeperpam/commander-cli/command-reference/reporting-commands
# Prerequisite: an authenticated Commander session with admin privileges.

set -euo pipefail

# HTH Guide Excerpt: begin cli-security-audit-report
# Per-user password security strength report. -su previews recalculated
# scores; -s calculates and pushes updated scores; -b adds BreachWatch
# scores to the output. Export to CSV for tracking over time.
keeper --batch-mode - <<'EOF'
security-audit-report -s
security-audit-report -b --format csv
security-audit-report --score-type=strong_passwords --save
EOF
# HTH Guide Excerpt: end cli-security-audit-report

# HTH Guide Excerpt: begin cli-user-login-report
# User status and last-login report — surfaces accounts that have not
# signed in recently and feeds the remediation follow-up in this control.
keeper --batch-mode - <<'EOF'
user-report --format csv --output logins.csv --days 30
EOF
# HTH Guide Excerpt: end cli-user-login-report
