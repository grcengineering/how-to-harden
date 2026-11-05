// HTH Pack Contract: v1
//   control: openai-api-5.4
//   guide: https://howtoharden.com/guides/openai-api/#54-gate-cyber-access-by-project-and-explicit-request
//   profile: L2
//   mode: mutating
//   requires: pinned official SDK; approved project/model/program; pseudonymous user identifier
// Sources: https://developers.openai.com/api/docs/guides/daybreak
// https://developers.openai.com/api/docs/guides/safety-checks/cybersecurity
// NIST 800-53 AC-3, AC-6. Direct execution prints a request, never calls the API.

// HTH Guide Excerpt: begin explicit-cyber-program
export function buildCyberRequest({ model, input, cyber = "standard", safetyIdentifier }) {
  if ([model, input, safetyIdentifier].some((value) => typeof value !== "string" || !value.trim())) {
    throw new Error("Supply an approved model, bounded task and stable pseudonymous user identifier");
  }
  if (!["standard", "daybreak_blue", "daybreak_red"].includes(cyber)) {
    throw new Error("Select an explicit supported Cyber access program; null is invalid");
  }
  return { model, input, access_programs: { cyber }, safety_identifier: safetyIdentifier };
}

// Only the caller can establish project approval and model compatibility.
// Selecting a program does not grant access, and approval names do not always
// match the request value. No fallback or program-changing retry is performed.
export async function executeCyberRequest(client, options) {
  const response = await client.responses.create(buildCyberRequest(options));
  return { response_id: response.id, request_id: response._request_id, model: response.model, access_programs: response.access_programs };
}
// Returned model/program are evidence of the served request, not proof of
// current saved project policy, external storage health or authorized tool use.
// HTH Guide Excerpt: end explicit-cyber-program

if (import.meta.main) {
  console.log(JSON.stringify(buildCyberRequest({
    model: process.env.OPENAI_MODEL,
    input: process.env.OPENAI_TASK,
    cyber: process.env.OPENAI_CYBER_PROGRAM ?? "standard",
    safetyIdentifier: process.env.OPENAI_SAFETY_IDENTIFIER,
  }), null, 2));
}
