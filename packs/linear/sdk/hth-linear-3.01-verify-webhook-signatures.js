#!/usr/bin/env node
// HTH Pack Contract: v1
//   control: linear-3.1
//   guide:   https://howtoharden.com/guides/linear/#31-configure-integration-access
//   profile: L2
//   mode:    read-only
//   requires: LINEAR_WEBHOOK_SECRET(the webhook's signing secret, from its detail page under Settings > Administration > API), PORT(optional; default 8080)
// =============================================================================
// HTH Linear Control 3.1: Configure Integration Access (webhook receivers)
// Profile Level: L2 (Walk)
// Frameworks: CIS Controls 3.11 | NIST 800-53 SC-12
// Source: https://howtoharden.com/guides/linear/#31-configure-integration-access
// Dependencies: Node.js 18+ (or Bun) and @linear/sdk (exercised against 96.0.0)
//
// A webhook receiver that accepts only requests Linear signed. It uses the
// official SDK helper documented at https://linear.app/developers/sdk-webhooks,
// which implements https://linear.app/developers/webhooks#securing-webhooks:
//   - Linear-Signature is a hex HMAC-SHA256 of the RAW request body, keyed with
//     the webhook's signing secret, and it is compared in constant time;
//   - the signed body's webhookTimestamp must be within 60 seconds of now, which
//     rejects replays.
// A request that fails either check gets HTTP 400 before any event handler runs.
//
// "Read-only" here means the pack never writes to Linear. It receives events.
//
// TRAP 1: NOTHING MAY PARSE THE BODY FIRST. Linear signs the exact bytes. A JSON
// body parser mounted ahead of the handler re-serialises the body and every
// signature check fails. This server hands the raw request to the SDK.
//
// TRAP 2: NO SECRET, NO SERVER. Without LINEAR_WEBHOOK_SECRET the SDK cannot
// verify anything, so the process exits 2 instead of starting an endpoint that
// accepts unsigned events.
//
// TRAP 3: THE AUDIT-LOG STREAM IS A WEBHOOK TOO. Control 4.1's "Stream logs"
// target is signed with its own secret. Run a receiver like this in front of the
// SIEM collector, or use the collector's own HMAC check.
// =============================================================================
"use strict";

const http = require("node:http");
const { LinearWebhookClient } = require("@linear/sdk/webhooks");

// HTH Guide Excerpt: begin verify-webhook-signatures
const secret = process.env.LINEAR_WEBHOOK_SECRET;
if (!secret) {
  // TRAP 2
  console.error("PRECONDITION: set LINEAR_WEBHOOK_SECRET to the webhook's signing secret");
  process.exit(2);
}
const port = Number(process.env.PORT || 8080);

// createHandler() checks the Linear-Signature HMAC over the raw body and the
// signed webhookTimestamp (±60 s), answering 400 on either failure and 405 to
// anything but POST. Only verified events reach the handlers registered below.
const handler = new LinearWebhookClient(secret).createHandler();

handler.on("*", async (payload) => {
  // Replace with your processing. `payload` is already verified.
  console.log(`verified ${payload.type} ${payload.action} webhook=${payload.webhookId}`);
});

http
  .createServer((req, res) => {
    if (req.url !== "/hooks/linear") {
      res.statusCode = 404;
      res.end();
      return;
    }
    // TRAP 1: the raw IncomingMessage goes straight to the SDK, unparsed.
    handler(req, res);
  })
  .listen(port, () => console.log(`listening on :${port}/hooks/linear`));
// HTH Guide Excerpt: end verify-webhook-signatures
