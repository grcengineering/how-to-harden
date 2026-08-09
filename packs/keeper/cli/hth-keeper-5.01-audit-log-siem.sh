#!/usr/bin/env bash
# HTH Keeper Control 5.1: Configure Audit Logging
# Profile: L1 | CIS Controls: 8.2 | NIST 800-53: AU-2
# https://howtoharden.com/guides/keeper/#51-configure-audit-logging
#
# Interface: Keeper Commander CLI (first-party).
#   audit-log / audit-report: https://docs.keeper.io/en/keeperpam/commander-cli/command-reference/reporting-commands
# Prerequisite: an authenticated Commander session; the Advanced Reporting &
# Alerts Module (ARAM) supplies the event data these commands consume.

set -euo pipefail

# HTH Guide Excerpt: begin cli-audit-log-siem-export
# Push Keeper event data to a SIEM. Supported targets:
# splunk, sumo, syslog, syslog-port, azure-la, json.
# The --record argument names a Keeper record that stores the export
# state and the SIEM credentials, so the connection details never
# leave the vault. --anonymize replaces emails with enterprise user IDs.
keeper --batch-mode - <<'EOF'
audit-log --target=splunk
EOF

# Local JSON export of the last 30 days (no SIEM required):
keeper --batch-mode - <<'EOF'
audit-log --record=audit-log-json --target=json --days=30
EOF
# HTH Guide Excerpt: end cli-audit-log-siem-export

# HTH Guide Excerpt: begin cli-audit-report-review
# Ad-hoc audit review with audit-report. Daily rollup of who generated
# which event types, then a raw dump of the last 30 days for triage.
keeper --batch-mode - <<'EOF'
audit-report --report-type day --columns username --columns audit_event_type
audit-report --report-type raw --report-format fields --created last_30_days --limit -1
EOF
# HTH Guide Excerpt: end cli-audit-report-review
