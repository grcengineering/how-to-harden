# =============================================================================
# HTH Azure DevOps Control 3.3: Secure Agent Pool Configuration
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-7
# Source: https://howtoharden.com/guides/azure-devops/#33-secure-agent-pool-configuration
# =============================================================================

# HTH Guide Excerpt: begin terraform

# ---------------------------------------------------------------------------
# Create tiered agent pools with appropriate access restrictions.
# Production and security agent pools are isolated from development
# workloads. Pipeline authorization restricts which pipelines can use
# each pool.
#
# Pool hierarchy:
#   Azure Pipelines (Microsoft-hosted, ephemeral) -- built-in, not managed
#   Production-Agents (self-hosted, restricted access)
#   Security-Agents (isolated, scanning tools only) -- L2+
# ---------------------------------------------------------------------------

# Production agent pool -- restricted to production pipelines
resource "azuredevops_agent_pool" "production" {
  name           = var.agent_pool_name
  auto_provision = false
  auto_update    = true
}

# Queue the production pool into the project
resource "azuredevops_agent_queue" "production" {
  project_id    = data.azuredevops_project.target.id
  agent_pool_id = azuredevops_agent_pool.production.id
}

# Restrict production pool access -- do not auto-authorize all pipelines
resource "azuredevops_pipeline_authorization" "production_pool" {
  project_id  = data.azuredevops_project.target.id
  resource_id = azuredevops_agent_queue.production.id
  type        = "queue"
}

# Security-isolated agent pool for scanning tools (L2+)
resource "azuredevops_agent_pool" "security" {
  count = var.profile_level >= 2 ? 1 : 0

  name           = var.security_agent_pool_name
  auto_provision = false
  auto_update    = true
}

resource "azuredevops_agent_queue" "security" {
  count = var.profile_level >= 2 ? 1 : 0

  project_id    = data.azuredevops_project.target.id
  agent_pool_id = azuredevops_agent_pool.security[0].id
}

resource "azuredevops_pipeline_authorization" "security_pool" {
  count = var.profile_level >= 2 ? 1 : 0

  project_id  = data.azuredevops_project.target.id
  resource_id = azuredevops_agent_queue.security[0].id
  type        = "queue"
}

# HTH Guide Excerpt: end terraform
