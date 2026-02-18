# =============================================================================
# HTH Buildkite Control 3.1: Configure Agent Tokens
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.11 | NIST SC-12
# Source: https://howtoharden.com/guides/buildkite/#31-configure-agent-tokens
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create scoped agent tokens per environment
resource "buildkite_agent_token" "tokens" {
  for_each = var.agent_tokens

  description = each.value.description
}
# HTH Guide Excerpt: end terraform
