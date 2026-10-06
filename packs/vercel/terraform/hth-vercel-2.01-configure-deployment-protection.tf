# =============================================================================
# HTH Vercel Control 2.1: Configure Deployment Protection
# Profile Level: L1 (Crawl) + L2/L3 enhancements
# Frameworks: NIST CM-3, AC-3
# Source: https://howtoharden.com/guides/vercel/#21-configure-deployment-protection
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- Adopt the EXISTING project. vercel_project CREATES a project when it is
#     not imported, so every project-level control (2.1, 2.2, 2.4, 2.5) feeds
#     this ONE resource instead of declaring its own vercel_project. ---
import {
  to = vercel_project.hardened
  id = "${var.vercel_team_id}/${var.project_id}"
}

# --- The project as it is now. Adopting it must never weaken a protection it
#     already has; the preconditions and fallbacks below read this. ---
data "vercel_project" "current" {
  name    = var.project_name
  team_id = var.vercel_team_id
}

locals {
  # null when the project has no such protection today
  current_password_scope    = try(data.vercel_project.current.password_protection.deployment_type, null)
  current_trusted_ips_scope = try(data.vercel_project.current.trusted_ips.deployment_type, null)
  current_vercel_auth_scope = try(data.vercel_project.current.vercel_authentication.deployment_type, null)
}

resource "vercel_project" "hardened" {
  name    = var.project_name
  team_id = var.vercel_team_id

  # L1: Standard Protection + Vercel Authentication (all plans).
  # "standard_protection_new" is the current Standard Protection (API:
  # all_except_custom_domains), which leaves every production domain public,
  # including the auto-assigned <project>.vercel.app; "standard_protection" is
  # the (Legacy) scope, which leaves production deployment URLs public.
  # "all_deployments" is the 2.4 scope (included on every plan).
  vercel_authentication = {
    deployment_type = local.vercel_authentication_scope
  }

  # L2: Password Protection (Enterprise, or Pro at $20/mo per project) -- previews, or all
  # deployments when 2.4 is enabled
  password_protection = var.profile_level >= 2 && var.preview_password != "" ? {
    deployment_type = local.password_protection_scope
    password        = var.preview_password
  } : null

  # L3: Trusted IPs restrict access to known networks (Enterprise)
  trusted_ips = var.profile_level >= 3 && length(var.trusted_ip_addresses) > 0 ? {
    addresses       = var.trusted_ip_addresses
    deployment_type = local.trusted_ips_scope
    protection_mode = "trusted_ip_required"
  } : null

  # L2: no preview deployments (2.2); skew protection on. Below L2 the
  # project's current values are kept, never planned back to "off".
  preview_deployments_disabled = local.preview_deployments_disabled
  skew_protection              = var.profile_level >= 2 ? "12 hours" : data.vercel_project.current.skew_protection
  prioritise_production_builds = true

  # 2.2 Harden Git Integration
  git_fork_protection  = local.git_fork_protection
  git_provider_options = local.git_provider_options

  # 2.5 Protected Source Maps
  protected_sourcemaps = local.protected_sourcemaps

  lifecycle {
    # Settings this pack does not own keep the values the project already has.
    # Without this list, adopting the project plans each of them to null, and
    # the provider sends those nulls on update: a null git_repository unlinks
    # the Git repository, and the framework, root directory and build commands
    # reset to their defaults.
    ignore_changes = [
      git_repository, framework, root_directory, build_command, dev_command,
      install_command, ignore_command, output_directory, preview_deployment_suffix,
      public_source, environment, trusted_sources, options_allowlist,
      oidc_token_config, git_comments, serverless_function_region, node_version,
      resource_config, on_demand_concurrent_builds, build_machine_type,
      automatically_expose_system_environment_variables, auto_assign_custom_domains,
      enable_affected_projects_deployments, enable_preview_feedback,
      enable_production_feedback, preview_comments, git_lfs, function_failover,
      customer_success_code_visibility, directory_listing,
    ]

    precondition {
      condition     = data.vercel_project.current.id == var.project_id
      error_message = "project_name is not the current name of project_id; the apply would rename project_id. Set project_name to that project's name."
    }
    precondition {
      condition     = local.current_password_scope == null || (var.profile_level >= 2 && var.preview_password != "")
      error_message = "The project already has Password Protection. Set profile_level >= 2 and preview_password, or this apply removes it."
    }
    precondition {
      condition     = local.current_trusted_ips_scope == null || (var.profile_level >= 3 && length(var.trusted_ip_addresses) > 0)
      error_message = "The project already has Trusted IPs. Set profile_level = 3 and trusted_ip_addresses to the ranges to keep, or this apply removes them."
    }
    precondition {
      condition     = local.current_vercel_auth_scope != "all_deployments" || local.vercel_authentication_scope == "all_deployments"
      error_message = "Vercel Authentication already covers All Deployments. Set profile_level >= 2 and private_production_deployments_enabled = true, or this apply narrows it to Standard Protection."
    }
  }
}

# --- L3: Protection Bypass for Automation stays disabled: a bypass secret
#     exists only if a vercel_project_protection_bypass resource creates one,
#     and this pack declares none. ---

# HTH Guide Excerpt: end terraform
