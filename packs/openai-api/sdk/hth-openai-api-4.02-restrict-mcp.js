// HTH Pack Contract: v1
//   control: openai-api-4.2
//   guide: https://howtoharden.com/guides/openai-api/#42-constrain-mcp-tools-and-broker-third-party-secrets
//   profile: L2
//   mode: read-only
//   requires: reviewed HTTPS MCP endpoint and exact allowed tool names
// Source: https://developers.openai.com/api/docs/guides/agents-api/tools/mcp
// NIST 800-53 AC-6, SC-7. Pure native-request builder; no product call.
// HTH Guide Excerpt: begin restrict-mcp
export function buildRestrictedMcp({ serverLabel, serverUrl, allowedTools }) {
  const url = new URL(serverUrl);
  if (url.protocol !== "https:" || url.username || url.password || url.hash || url.search) {
    throw new Error("Use a reviewed HTTPS endpoint without embedded credentials, query, or fragment");
  }
  if (!serverLabel || !Array.isArray(allowedTools) || !allowedTools.length ||
      allowedTools.some((name) => typeof name !== "string" || !name || name.includes("*"))) {
    throw new Error("Provide a label and nonempty exact tool allowlist");
  }
  return {
    type: "mcp",
    server_label: serverLabel,
    transport: { type: "http", server_url: url.href },
    connection_origin: "service",
    allowed_tools: [...new Set(allowedTools)],
    required: true,
  };
}
// Add the returned tool to a reviewed session's agent.tools. Attach approved
// vault_ids separately; a vault's credentials match the server URL. Hosted
// sandbox network restrictions do not constrain this service-origin MCP path.
// HTH Guide Excerpt: end restrict-mcp
