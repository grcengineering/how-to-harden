#!/usr/bin/env python3
# HTH Pack Contract: v1
#   control: atlassian-3.2
#   guide:   https://howtoharden.com/guides/atlassian/#32-configure-webhook-security
#   profile: L2
#   mode:    read-only
#   requires: none (a local function; the webhook secret is a caller argument)
# =============================================================================
# HTH Atlassian Control 3.2: Webhook Signature Validation
# Profile: L2 | NIST: SC-8
# Source: https://developer.atlassian.com/cloud/jira/platform/webhooks/
#         ("Validating webhook deliveries": X-Hub-Signature = method=HMAC(secret, body))
# Checked against Atlassian's published test vector (secret "It's a Secret to
# Everybody", payload "Hello World!", sha256=a4771c39...63c9).
# A missing or non-ASCII X-Hub-Signature returns False instead of raising, so an
# unsigned delivery can never reach a caller's exception path as anything but a rejection.
# =============================================================================

# HTH Guide Excerpt: begin sdk-webhook-validation
import hmac
import hashlib

def validate_webhook(request, secret):
    signature = request.headers.get('X-Hub-Signature')
    if not isinstance(signature, str) or not signature.isascii():
        return False  # unsigned or malformed delivery: reject, never raise
    payload = request.body

    expected = 'sha256=' + hmac.new(
        secret.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(signature, expected)
# HTH Guide Excerpt: end sdk-webhook-validation
