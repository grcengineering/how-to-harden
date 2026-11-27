#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: hugging-face-3.1
#   guide: https://howtoharden.com/guides/hugging-face/#31-export-organization-security-audit-events
#   profile: L2
#   mode: read-only
#   requires: hf CLI, huggingface_hub or curl with Python 3, scoped Hub credentials
# HTH hugging-face 3.1: Export organization security audit events
# Profile: L2 (Walk)
# Guide: https://howtoharden.com/guides/hugging-face/
# Reference: https://huggingface.co/docs/hub/en/audit-logs
# HTH Guide Excerpt: begin export-organization-audit-log
set -euo pipefail
set +x
umask 077
: "${HF_ORG:?Set the exact organization slug}"
: "${HF_TOKEN:?Provide an approved audit-export token}"
[[ "$HF_ORG" =~ ^[A-Za-z0-9][A-Za-z0-9-]*$ && "$HF_TOKEN" =~ ^[A-Za-z0-9_-]+$ ]]
tmp=$(mktemp ./hth-hf-audit.XXXXXXXX)
trap 'rm -f "$tmp"' EXIT
printf 'header = "Authorization: Bearer %s"\n' "$HF_TOKEN" |
  curl --disable --config - --proto '=https' --fail --silent --show-error \
    --connect-timeout 10 --max-time 120 --output "$tmp" \
    "https://huggingface.co/api/organizations/$HF_ORG/audit-log/export"
python3 -c 'import json, sys; x=json.load(open(sys.argv[1])); sys.exit(0 if isinstance(x, list) else 1)' "$tmp"
trap - EXIT
printf 'Audit evidence saved to %s\n' "$tmp"
# HTH Guide Excerpt: end export-organization-audit-log
