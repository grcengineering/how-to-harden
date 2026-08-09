// =============================================================================
// HTH Twilio Control 3.2: Configure Webhook Security
// Profile Level: L2 (Walk)
// Frameworks: CIS Controls 3.11 | NIST 800-53 SC-8
// Source: https://howtoharden.com/guides/twilio/#32-configure-webhook-security
// Interface: Twilio Node.js helper library (twilio) —
//   validateRequest / validateRequestWithBody, verified against
//   https://www.twilio.com/docs/usage/webhooks/webhooks-security
// Auth: primary Auth Token as the HMAC signing key (never a rotated copy)
// =============================================================================

'use strict';

// HTH Guide Excerpt: begin sdk-validate-form-webhook

const client = require('twilio');

// The primary Auth Token is the signing key for X-Twilio-Signature.
const authToken = process.env.TWILIO_AUTH_TOKEN;

// Validate a standard form-encoded Twilio webhook.
// url    — the full public URL Twilio was configured to call
// params — the POST parameters exactly as received
// twilioSignature — the X-Twilio-Signature request header value
function isValidTwilioWebhook(url, params, twilioSignature) {
  return client.validateRequest(authToken, twilioSignature, url, params);
}

// Reject anything that fails validation before touching application logic.
// Example wiring inside any Node HTTP handler:
//   if (!isValidTwilioWebhook(fullUrl, req.body, req.headers['x-twilio-signature'])) {
//     res.statusCode = 403;
//     return res.end();
//   }

// HTH Guide Excerpt: end sdk-validate-form-webhook

// HTH Guide Excerpt: begin sdk-validate-json-webhook

// JSON webhooks are NOT covered by parameter signing alone. Twilio appends a
// bodySHA256 query parameter to the request URL, and the raw JSON body must be
// validated against it with validateRequestWithBody.
// url  — full request URL INCLUDING the ?bodySHA256=... query parameter
// body — the raw, unparsed JSON request body string
function isValidTwilioJsonWebhook(url, body, twilioSignature) {
  return client.validateRequestWithBody(authToken, twilioSignature, url, body);
}

// Example (values from Twilio's webhook security documentation):
//   const url = 'https://example.com/myapp?bodySHA256=5ccde7145dfb8f56479710896586cb9d5911809d83afbe34627818790db0aec9';
//   const body = '{"CallSid":"CA1234567890ABCDE","Caller":"+12349013030"}';
//   isValidTwilioJsonWebhook(url, body, req.headers['x-twilio-signature']);

// HTH Guide Excerpt: end sdk-validate-json-webhook

module.exports = { isValidTwilioWebhook, isValidTwilioJsonWebhook };
