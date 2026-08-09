#!/usr/bin/env bash
# =============================================================================
# HTH Twilio Control 3.1: Configure API Key Security
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 3.11 | NIST 800-53 SC-12
# Source: https://howtoharden.com/guides/twilio/#31-configure-api-key-security
# Interface: Twilio CLI (first-party, GA) — https://www.twilio.com/docs/twilio-cli
#   Commands verified against the Keys v1 resource reference:
#   https://www.twilio.com/docs/iam/api-keys/key-resource-v1
# Auth: Twilio CLI profile (twilio login) or TWILIO_ACCOUNT_SID/TWILIO_AUTH_TOKEN
# Notes:
#   - Restricted API Keys are currently available in the US region only.
#   - Main keys cannot be created via the API/CLI — Console only. That is
#     deliberate: never mint Main keys for integrations.
#   - The key Secret is returned once at creation and cannot be retrieved again.
# =============================================================================

set -euo pipefail

: "${TWILIO_ACCOUNT_SID:?Set TWILIO_ACCOUNT_SID to the account under audit}"

# HTH Guide Excerpt: begin cli-audit-keys

# --- Inventory every API key on the account ---
# Review the list for keys with no known owning integration: each one is a
# standing credential that should be deleted (see rotation region below).
twilio api:iam:v1:keys:list \
   --account-sid "${TWILIO_ACCOUNT_SID}"

# HTH Guide Excerpt: end cli-audit-keys

# HTH Guide Excerpt: begin cli-create-restricted-key

# --- Create a least-privilege Restricted API key (US region only) ---
# The --policy document enumerates exactly what the key may do. This example
# grants read-only access to Messaging messages; scope it to what the owning
# integration actually touches.
twilio api:iam:v1:keys:create \
   --friendly-name "reporting-service-restricted" \
   --account-sid "${TWILIO_ACCOUNT_SID}" \
   --key-type restricted \
   --policy "{\"allow\":[\"/twilio/messaging/messages/read\"]}"

# Where Restricted keys are not available for your region, fall back to a
# Standard key (no --key-type flag) and compensate with tighter rotation,
# dedicated subaccounts, and monitoring — and record the exception:
twilio api:iam:v1:keys:create \
   --friendly-name "legacy-region-standard-key" \
   --account-sid "${TWILIO_ACCOUNT_SID}"

# HTH Guide Excerpt: end cli-create-restricted-key

# HTH Guide Excerpt: begin cli-rotate-and-retire

# --- Rotate: tighten an existing Restricted key's policy in place ---
twilio api:iam:v1:keys:update \
   --sid "${TWILIO_KEY_SID:?Set TWILIO_KEY_SID to the key being rotated}" \
   --friendly-name "reporting-service-restricted" \
   --policy "{\"allow\":[\"/twilio/messaging/messages/read\"]}"

# --- Retire: delete a key whose owning integration is gone ---
# Create the replacement key and cut integrations over BEFORE removing the
# old one, so rotation never causes an outage.
twilio api:iam:v1:keys:remove \
   --sid "${TWILIO_OLD_KEY_SID:?Set TWILIO_OLD_KEY_SID to the key being retired}"

# HTH Guide Excerpt: end cli-rotate-and-retire
