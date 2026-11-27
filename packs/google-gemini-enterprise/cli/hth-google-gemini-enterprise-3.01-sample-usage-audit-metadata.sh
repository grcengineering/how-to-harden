#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: google-gemini-enterprise-3.1
#   guide: https://howtoharden.com/guides/google-gemini-enterprise/#31-collect-usage-metadata-without-prompt-payloads-by-default
#   profile: L2
#   mode: read-only
#   requires: Bash, gcloud, jq, and authorized read access
# HTH google-gemini-enterprise 3.1: Collect usage metadata without prompt payloads by default
# Profile: L2 (Walk)
# Guide: https://howtoharden.com/guides/google-gemini-enterprise/
# Reference: https://docs.cloud.google.com/sdk/gcloud/reference/logging/read
# HTH Guide Excerpt: begin sample-usage-audit-metadata
set +x
set -euo pipefail
: "${GEMINI_PROJECT_ID:?Set the explicitly approved Google Cloud project ID}"
if ! [[ "$GEMINI_PROJECT_ID" =~ ^[a-z][a-z0-9-]{4,28}[a-z0-9]$ ]]; then
  printf '%s\n' 'Use an ordinary Google Cloud project ID (6–30 characters)' >&2
  exit 2
fi
filter="logName=\"projects/$GEMINI_PROJECT_ID/logs/discoveryengine.googleapis.com%2Fgemini_enterprise_user_activity\""
filter+=" OR logName=~\"^projects/$GEMINI_PROJECT_ID/logs/discoveryengine[.]googleapis[.]com%2Fgen_ai.*$\""
gcloud logging read "$filter" --project="$GEMINI_PROJECT_ID" \
  --freshness=24h --limit=20 --order=desc --format='json(logName,timestamp)' --quiet |
  jq -ces '
    if length == 1 and (.[0] | type == "array" and length <= 20 and
      all(.[]; type == "object" and (.logName | type == "string") and
        (.timestamp | type == "string")))
    then .[0] | {sampled: length, newest_timestamp: (.[0].timestamp // null)}
    else error("Unexpected usage audit sample") end'
# HTH Guide Excerpt: end sample-usage-audit-metadata
