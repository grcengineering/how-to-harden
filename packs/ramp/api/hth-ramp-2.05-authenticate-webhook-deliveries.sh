#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ramp-2.5
#   guide: https://howtoharden.com/guides/ramp/#25-authenticate-webhook-deliveries
#   profile: L2
#   mode: read-only
#   requires: bash, curl, python3; RAMP_ACCESS_TOKEN with OAuth bearer token (webhook listing declares no named scope)
# HTH Ramp 2.5: Authenticate Webhook Deliveries
# Profile: L2 | NIST: AC-6, AU-6 | CIS: 6.8, 8.2
# Available interfaces verified against https://docs.ramp.com/openapi/developer-api.json on 2026-11-08.
# Keep this file beside common.sh, response.py and response-shapes.json.
# HTH Guide Excerpt: begin authenticate-webhook-deliveries
source "$(dirname -- "$0")/common.sh"
# Metadata inventory only; this cannot prove receiver signature verification.
ramp_collect webhooks /developer/v1/webhooks "" no
ramp_report webhooks
# HTH Guide Excerpt: end authenticate-webhook-deliveries
