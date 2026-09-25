// HTH Pack Contract: v1
//   control: square-3.3
//   guide:   https://howtoharden.com/guides/square/#33-verify-webhook-signatures
//   profile: L1
//   mode:    read-only
//   requires: SQUARE_WEBHOOK_SIGNATURE_KEY(the subscription's signature key, from a secrets manager), SQUARE_WEBHOOK_NOTIFICATION_URL(the notification URL exactly as registered), square(npm, v40.0.0 or later)
// =============================================================================
// HTH Square Control 3.3: Verify Webhook Signatures — receiver
// Profile Level: L1 (Crawl)
// Frameworks: CIS Controls 3.10; NIST 800-53 SC-8, SI-7
// Source: https://howtoharden.com/guides/square/#33-verify-webhook-signatures
//
// VERIFICATION STATUS (validate-hth-guide, 2026-09-24): transcribed from Square's
// "Validate a webhook event notification" page (Node.js SDK, version 40.0.0 and
// later) and parse-checked. It has NOT yet been executed against a live Square
// webhook subscription.
//
// TRAP 1: the HMAC input is notification URL + RAW body. Parsing and
//   re-serializing the JSON changes the bytes and every check fails, so the raw
//   buffer is what gets verified.
// TRAP 2: the URL must be configuration, not rebuilt from Host/X-Forwarded-*
//   headers — a proxy that rewrites either one breaks verification.
// TRAP 3: fail closed. A missing header, a thrown error, or a false result all
//   return 403 before any processing.

// HTH Guide Excerpt: begin sdk-verify-webhook-signature
import * as http from 'node:http';
import { WebhooksHelper } from 'square';

const SIGNATURE_KEY = process.env.SQUARE_WEBHOOK_SIGNATURE_KEY;
const NOTIFICATION_URL = process.env.SQUARE_WEBHOOK_NOTIFICATION_URL;
if (!SIGNATURE_KEY || !NOTIFICATION_URL) {
  console.error('PRECONDITION: set SQUARE_WEBHOOK_SIGNATURE_KEY and SQUARE_WEBHOOK_NOTIFICATION_URL');
  process.exit(2);
}

async function isFromSquare(signatureHeader, rawBody) {
  if (!signatureHeader) return false;
  return await WebhooksHelper.verifySignature({
    requestBody: rawBody,
    signatureHeader,
    signatureKey: SIGNATURE_KEY,
    notificationUrl: NOTIFICATION_URL,
  });
}

http.createServer((req, res) => {
  const chunks = [];
  req.on('data', (chunk) => chunks.push(chunk));
  req.on('end', async () => {
    const rawBody = Buffer.concat(chunks).toString('utf8');
    let verified = false;
    try {
      verified = await isFromSquare(req.headers['x-square-hmacsha256-signature'], rawBody);
    } catch {
      verified = false;
    }
    if (!verified) {
      res.writeHead(403);
      res.end();
      return;
    }
    // Only now is rawBody trusted: hand it to your event processor here.
    res.writeHead(200);
    res.end();
  });
}).listen(Number(process.env.PORT || 8000));
// HTH Guide Excerpt: end sdk-verify-webhook-signature
