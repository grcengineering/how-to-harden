# =============================================================================
# HTH GitHub Control 6.06: Enforce Dependency Review Across the Organization
# Profile Level: L2 (Walk)
# Frameworks: NIST SA-12, SA-11
# Source: https://howtoharden.com/guides/github/#65-enforce-dependency-review-across-the-organization
#
# required_workflows_repository_id is the numeric ID of the repository that
# holds dependency-review.yml (usually the organization's .github repository).
# That workflow's visibility must match the repositories it targets.
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_organization_ruleset" "require_dependency_review" {
  name        = "Require Dependency Review"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/main", "refs/heads/master"]
      exclude = []
    }

    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    required_workflows {
      required_workflow {
        repository_id = var.required_workflows_repository_id
        path          = ".github/workflows/dependency-review.yml"
        ref           = "refs/heads/main"
      }
    }
  }
}
# HTH Guide Excerpt: end terraform
