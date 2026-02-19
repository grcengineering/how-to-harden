#!/usr/bin/env python3
# HTH Atlassian Control 3.2: Webhook Signature Validation
# Profile: L2 | NIST: SC-8

# HTH Guide Excerpt: begin sdk-webhook-validation
import hmac
import hashlib

def validate_webhook(request, secret):
    signature = request.headers.get('X-Hub-Signature')
    payload = request.body

    expected = 'sha256=' + hmac.new(
        secret.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(signature, expected)
# HTH Guide Excerpt: end sdk-webhook-validation
