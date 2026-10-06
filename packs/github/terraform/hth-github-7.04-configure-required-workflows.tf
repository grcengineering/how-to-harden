# =============================================================================
# HTH GitHub Control 7.04: Configure Required Workflows via Organization Rulesets
# Profile Level: L2 (Walk)
# Frameworks: NIST SA-11, CM-3
# Source: https://howtoharden.com/guides/github/#73-enforce-required-workflows-via-organization-rulesets
#
# required_workflows_repository_id is the numeric ID of the repository that
# holds the workflow files (usually the organization's .github repository),
# which is excluded from the ruleset's own targets.
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_organization_ruleset" "required_security_workflows" {
  name        = "Required Security Workflows"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/main", "refs/heads/master"]
      exclude = []
    }

    repository_name {
      include = ["~ALL"]
      exclude = [".github"]
    }
  }

  rules {
    required_workflows {
      required_workflow {
        repository_id = var.required_workflows_repository_id
        path          = ".github/workflows/security-scan.yml"
        ref           = "refs/heads/main"
      }

      required_workflow {
        repository_id = var.required_workflows_repository_id
        path          = ".github/workflows/dependency-review.yml"
        ref           = "refs/heads/main"
      }
    }
  }
}
# HTH Guide Excerpt: end terraform
