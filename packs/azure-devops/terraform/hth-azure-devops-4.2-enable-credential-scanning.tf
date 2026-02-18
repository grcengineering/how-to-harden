# =============================================================================
# HTH Azure DevOps Control 4.2: Enable Credential Scanning
# Profile Level: L1 (Baseline)
# Frameworks: NIST RA-5
# Source: https://howtoharden.com/guides/azure-devops/#42-enable-credential-scanning
# =============================================================================

# HTH Guide Excerpt: begin terraform

# ---------------------------------------------------------------------------
# Enable repository-level policies that block pushes containing secrets
# or credentials. The azuredevops_repository_policy_check_credentials
# resource prevents accidental secret commits at the Git layer.
#
# Microsoft Security DevOps pipeline scanning (MicrosoftSecurityDevOps@1)
# is configured via YAML pipelines, not Terraform.
# ---------------------------------------------------------------------------

# Block pushes that contain credentials or secrets
resource "azuredevops_repository_policy_check_credentials" "block_secrets" {
  count = var.repository_id != "" ? 1 : 0

  project_id = data.azuredevops_project.target.id
  enabled    = true
  blocking   = true

  settings {
    scope {
      repository_id = var.repository_id
    }
  }
}

# Enforce path length limits to prevent path traversal abuse (L2+)
resource "azuredevops_repository_policy_max_path_length" "path_length" {
  count = var.profile_level >= 2 && var.repository_id != "" ? 1 : 0

  project_id = data.azuredevops_project.target.id
  enabled    = true
  blocking   = true

  settings {
    max_path_length = 260

    scope {
      repository_id = var.repository_id
    }
  }
}

# Enforce maximum file size to prevent binary blob abuse (L2+)
resource "azuredevops_repository_policy_max_file_size" "file_size" {
  count = var.profile_level >= 2 && var.repository_id != "" ? 1 : 0

  project_id = data.azuredevops_project.target.id
  enabled    = true
  blocking   = true

  settings {
    max_file_size = 50

    scope {
      repository_id = var.repository_id
    }
  }
}

# Block reserved names in repository paths (L2+)
resource "azuredevops_repository_policy_reserved_names" "reserved_names" {
  count = var.profile_level >= 2 && var.repository_id != "" ? 1 : 0

  project_id = data.azuredevops_project.target.id
  enabled    = true
  blocking   = true

  settings {
    scope {
      repository_id = var.repository_id
    }
  }
}

# HTH Guide Excerpt: end terraform
