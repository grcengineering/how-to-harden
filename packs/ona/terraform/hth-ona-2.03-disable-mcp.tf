# =============================================================================
# HTH Pack Contract: v1
#   control: ona-2.3
#   guide:   https://howtoharden.com/guides/ona/#23-restrict-mcp-server-access
#   profile: L2
#   mode:    mutating
#   requires: ONA_TOKEN(read-write PAT)
#
# HTH Ona Control 2.3: Restrict MCP Server Access
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 2.5 | NIST 800-53 CM-7, AC-3
# Source: https://howtoharden.com/guides/ona/#23-restrict-mcp-server-access
#
# PROVIDER BLOCK LIVES IN hth-ona-1.01-configure-sso.tf.
#
# Transcribed from https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/organization_policies
# (registry v2 provider-doc 13236800, provider-version 105656 = 0.4.0-beta.1).
#
# SINGLETON — merge these attributes into ONE ona_organization_policies resource
# if you adopt more than one pack; two resources managing the same object drift
# forever.
#
# WHY TERRAFORM FOR THIS CONTROL: mcp_disabled is a single organization-wide
# boolean with no per-server allow list. There is nothing to tune, which makes it
# exactly the kind of setting that gets flipped in a console during a demo and
# never flipped back. Declared here, that flip is drift.
#
# TRAPS
#  1. IT IS ALL OR NOTHING. The provider exposes mcp_disabled and no MCP server
#     allow list. You cannot permit an approved MCP server and deny the rest
#     through this surface. If agents genuinely need one MCP server, this control
#     cannot be partially applied — say so in your risk acceptance rather than
#     leaving the boolean false and calling it scoped.
#  2. agent_policy IS AN ATTRIBUTE, NOT A BLOCK. Write `agent_policy = { ... }`.
#  3. OMITTING mcp_disabled LEAVES IT UNMANAGED, not false and not true. Declare
#     it explicitly or a console change never surfaces as drift.
#  4. PROTO3 OMITS DEFAULTS. Absent mcp_disabled on the API read path means FALSE
#     — MCP is ENABLED. An evidence script that treats a missing key as "not
#     applicable" reports an open org as compliant.
#  5. THIS DOES NOT CONSTRAIN THE MCP SERVERS ONA ITSELF SHIPS to other clients.
#     It governs whether agents in Ona environments may use MCP; Ona's own MCP
#     endpoint for external clients is a separate surface.
#  6. DESTROY IS NOT DELETE for ona_organization_policies — destroying restores
#     the pre-Terraform server-defined policy, which may re-enable MCP.
# =============================================================================

variable "mcp_disabled" {
  description = "Disable MCP for agents organization-wide. There is no per-server allow list; this is all or nothing."
  type        = bool
  default     = true
}

# HTH Guide Excerpt: begin terraform
# SINGLETON: at most one ona_organization_policies per organization (import id "current") —
# merge these attributes with any other ona pack you adopt; two resources drift forever.
resource "ona_organization_policies" "agent_mcp" {
  agent_policy = {
    # true removes the whole MCP tool surface from agents in this organization.
    mcp_disabled = var.mcp_disabled
  }
}
# HTH Guide Excerpt: end terraform

output "ona_agent_mcp_disabled" {
  description = "Effective MCP posture. false means agents can reach MCP servers."
  value       = ona_organization_policies.agent_mcp.agent_policy.mcp_disabled
}
