// HTH Pack Contract: v1
//   control: openai-api-5.1
//   guide: https://howtoharden.com/guides/openai-api/#51-authenticate-webhooks-and-deduplicate-durable-delivery
//   profile: L1
//   mode: read-only
//   requires: official openai SDK, endpoint webhookSecret, durable enqueueOnce adapter
// Source: https://developers.openai.com/api/docs/guides/webhooks
// NIST 800-53 SC-8, SI-10. Importable receiver; no listener or live API call starts.
import OpenAI from "openai";

// HTH Guide Excerpt: begin verify-webhooks
export function createWebhookReceiver({ client, enqueueOnce, eventTypes = ["response.completed"] }) {
  if (typeof enqueueOnce !== "function") throw new Error("Supply a durable atomic enqueueOnce adapter");
  const accepted = new Set(eventTypes);
  return async function receive(request) {
    if (request.method !== "POST") return new Response(null, { status: 405 });
    // The SDK reports missing headers as a generic Error; reject them before
    // verification rather than converting unrelated SDK/configuration errors.
    if (["webhook-id", "webhook-timestamp", "webhook-signature"].some((name) => !request.headers.get(name))) {
      return new Response(null, { status: 400 });
    }
    const raw = await request.text(); // Preserve original text; do not JSON-parse first.
    let event;
    try {
      event = await client.webhooks.unwrap(raw, request.headers);
    } catch (error) {
      // InvalidWebhookSignatureError includes stale and mismatched signatures.
      if (error instanceof OpenAI.InvalidWebhookSignatureError || error instanceof SyntaxError) {
        return new Response(null, { status: 400 });
      }
      throw error;
    }
    const deliveryId = request.headers.get("webhook-id");
    if (!deliveryId) return new Response(null, { status: 400 });
    if (!accepted.has(event.type)) return new Response(null, { status: 204 });
    try {
      // Transactionally enqueue and insert deliveryId under a unique key in
      // shared durable storage. A duplicate must be a successful no-op.
      await enqueueOnce(deliveryId, event);
    } catch {
      return new Response(null, { status: 503 }); // Let OpenAI retry; never acknowledge lost work.
    }
    return new Response(null, { status: 204 });
  };
}
// Construct the official client with webhookSecret. Do not disable its timestamp
// tolerance, log raw payloads, or replace durable deduplication with a process Set.
// HTH Guide Excerpt: end verify-webhooks
