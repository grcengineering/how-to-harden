#!/usr/bin/env bash
# HTH Box Control 4.1: Enable Box Shield
# Profile: L2 | NIST 800-53: SI-4, AC-3
# https://howtoharden.com/guides/box/#41-enable-box-shield
#
# Retrieves Box Shield threat-detection alerts from the enterprise event stream
# using the first-party Box CLI, for triage or SIEM forwarding.
#   CLI docs:       https://developer.box.com/guides/tooling/cli/
#   events command: https://github.com/box/boxcli/blob/main/docs/events.md
#   Events API:     https://developer.box.com/reference/get-events/ (stream_type=admin_logs)
#   Shield events:  https://developer.box.com/guides/events/event-triggers/shield-alert-events/
#                   (event_type=SHIELD_ALERT; payload in additional_details.shield_alert)
#
# Prerequisites: Box Shield licensed; Box CLI authenticated with admin privileges
# (admin_logs requires admin access and the "manage enterprise properties" scope);
# jq installed.
set -euo pipefail

command -v box >/dev/null 2>&1 || { echo "ERROR: box CLI not found" >&2; exit 1; }
command -v jq  >/dev/null 2>&1 || { echo "ERROR: jq not found" >&2; exit 1; }

# How far back to pull Shield alerts (Box CLI shorthand: 1w = one week)
LOOKBACK="${LOOKBACK:-1w}"

# HTH Guide Excerpt: begin cli-fetch-shield-alerts
# Pull SHIELD_ALERT events from the enterprise event stream. Shield produces
# these for suspicious locations, suspicious sessions, anomalous downloads,
# malicious content, and (Shield Pro) ransomware activity.
ALERTS_JSON=$(box events --enterprise --stream-type admin_logs \
  --event-types SHIELD_ALERT --created-after "${LOOKBACK}" --json)

echo "Shield alerts in the last ${LOOKBACK}: $(echo "${ALERTS_JSON}" | jq 'length')"

# Summarize each alert from the documented additional_details.shield_alert
# payload: rule category, risk score, priority, and alert summary.
echo "${ALERTS_JSON}" | jq -r \
  '.[] | .additional_details.shield_alert as $a
       | "  \(.created_at)\tcategory=\($a.rule_category)\trisk=\($a.risk_score)\tpriority=\($a.priority)\tid=\($a.alert_id)"'
# HTH Guide Excerpt: end cli-fetch-shield-alerts

# HTH Guide Excerpt: begin cli-shield-alert-triage
# Surface the highest-risk alerts first so triage starts where it matters.
RISK_THRESHOLD="${RISK_THRESHOLD:-50}"
echo "Alerts at or above risk score ${RISK_THRESHOLD}:"
echo "${ALERTS_JSON}" | jq -r --argjson t "${RISK_THRESHOLD}" \
  '.[] | .additional_details.shield_alert as $a
       | select(($a.risk_score // 0) >= $t)
       | "  HIGH-RISK: \(.created_at) category=\($a.rule_category) risk=\($a.risk_score) summary=\($a.alert_summary // "n/a")"'

# Emit the full alert objects as JSON Lines for SIEM ingestion.
OUT_FILE="${OUT_FILE:-shield-alerts.jsonl}"
echo "${ALERTS_JSON}" | jq -c '.[]' > "${OUT_FILE}"
echo "Wrote full alert payloads to ${OUT_FILE}"
# HTH Guide Excerpt: end cli-shield-alert-triage
