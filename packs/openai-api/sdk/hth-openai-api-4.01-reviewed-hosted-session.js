// HTH Pack Contract: v1
//   control: openai-api-4.1
//   guide: https://howtoharden.com/guides/openai-api/#41-isolate-hosted-agents-and-enable-action-review
//   profile: L2
//   mode: mutating
//   requires: official openai SDK with beta Agents API; application key only when explicitly executing
// Sources: https://developers.openai.com/api/docs/guides/agents-api/sessions/approvals
// https://developers.openai.com/api/docs/guides/agents-api/environments/openai-hosted
// NIST 800-53 AC-6, SC-7. Direct execution prints native request JSON; never calls the API.

// HTH Guide Excerpt: begin reviewed-hosted-session
export function buildReviewedSession({ model, input, allowedDomains = [] }) {
  if (!model || !input) throw new Error("Choose an approved model and explicit task input");
  if (allowedDomains.length > 100 || allowedDomains.some((host) =>
    typeof host !== "string" || !/^(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9-]+$/i.test(host)
  )) throw new Error("Use at most 100 exact DNS hosts, with no wildcard, URL, path, or port");
  return {
    agent: { model },
    environment: {
      type: "openai_hosted",
      network: allowedDomains.length
        ? { access: "restricted", allowed_domains: [...new Set(allowedDomains)] }
        : { access: "disabled" },
    },
    review: "auto_review",
    input,
  };
}
// Explicit integration entry point: caller supplies the official OpenAI client.
// Creating a real session starts work and may incur charges; review the payload first.
export async function executeReviewedSession(client, options) {
  return client.beta.agents.sessions.create(buildReviewedSession(options));
}
// HTH Guide Excerpt: end reviewed-hosted-session

if (import.meta.main) {
  console.log(JSON.stringify(buildReviewedSession({
    model: process.env.OPENAI_MODEL,
    input: process.env.OPENAI_TASK,
  }), null, 2));
}
