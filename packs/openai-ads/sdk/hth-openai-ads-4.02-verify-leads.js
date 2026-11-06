// HTH Pack Contract: v1
//   control: openai-ads-4.2
//   guide: https://howtoharden.com/guides/openai-ads/#42-bind-signed-lead-delivery-to-its-subscription
//   profile: L2
//   mode: read-only
//   requires: official openai SDK; preprovisioned subscription registry; schema validator; durable enqueueOnce
// Sources: https://developers.openai.com/ads/openapi.json (webhooks lead_form.response.created)
// https://developers.openai.com/api/docs/guides/webhooks
// NIST 800-53 AC-4, SC-8, SI-10. Import starts no listener or product request.
import OpenAI from "openai";

// HTH Guide Excerpt: begin verify-leads
export function createLeadReceiver({ findSubscription, validateLeadEvent, enqueueOnce }) {
  if ([findSubscription, validateLeadEvent, enqueueOnce].some((fn) => typeof fn !== "function")) {
    throw new Error("Supply subscription lookup, full published-schema validation and durable enqueue adapters");
  }
  return async function receive(request) {
    if (request.method !== "POST") return new Response(null, { status: 405 });
    const candidateId = request.headers.get("OpenAI-Subscription-Id");
    if (!candidateId || !/^leadsync_[^~]+_g[1-9][0-9]*$/.test(candidateId) ||
        ["webhook-id", "webhook-timestamp", "webhook-signature"].some((name) => !request.headers.get(name))) {
      return new Response(null, { status: 400 });
    }
    // Header is untrusted: use it only to look up a preprovisioned candidate.
    // Never construct a URL or fetch a secret based on an arbitrary header.
    const subscription = await findSubscription(candidateId);
    if (!subscription) return new Response(null, { status: 400 });
    let event;
    try {
      event = await subscription.client.webhooks.unwrap(await request.text(), request.headers);
    } catch (error) {
      if (error instanceof OpenAI.InvalidWebhookSignatureError || error instanceof SyntaxError) {
        return new Response(null, { status: 400 });
      }
      throw error;
    }
    if (!validateLeadEvent(event) || event.type !== "lead_form.response.created" ||
        event.subscription_id !== candidateId) return new Response(null, { status: 400 });
    // Signed synthetic probes must never become CRM contacts.
    if (event.synthetic === true) return new Response(null, { status: 204 });
    if (event.data.ad_account_id !== subscription.adAccountId) return new Response(null, { status: 400 });
    try {
      // Store a minimized, validated event and delivery id in ONE durable
      // transaction. Scope the unique key to the subscription generation.
      await enqueueOnce(`${candidateId}:${request.headers.get("webhook-id")}`, event);
    } catch {
      return new Response(null, { status: 503 });
    }
    return new Response(null, { status: 204 });
  };
}
// validateLeadEvent must enforce LeadSyncWebhookEvent and referenced data/response
// schemas from the current published Ads OpenAPI contract. Bind each registry
// entry to an official OpenAI client configured with that signing secret.
// Never log raw lead responses or treat a valid signature as consent for any use.
// HTH Guide Excerpt: end verify-leads
