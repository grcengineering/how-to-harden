# =============================================================================
# HTH Harness Control 4.1: Configure Pipeline Governance
# Profile Level: L2 (Hardened)
# Frameworks: CIS 16.1, NIST SA-15
# Source: https://howtoharden.com/guides/harness/#41-configure-pipeline-governance
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Default OPA policy requiring approval stages in production pipelines (L2+)
resource "harness_platform_policy" "require_approval" {
  count = var.profile_level >= 2 ? 1 : 0

  identifier = "hth_require_prod_approval"
  name       = "Require Production Approval Stage"

  rego = <<-REGO
    package pipeline

    deny[msg] {
      input.pipeline.stages[_].stage.type == "Deployment"
      input.pipeline.stages[_].stage.spec.environment.type == "Production"
      not has_approval_stage
      msg := "Production deployments must include an approval stage (HTH Control 4.1)"
    }

    has_approval_stage {
      input.pipeline.stages[_].stage.type == "Approval"
    }
  REGO
}

# Policy set enforcing governance on pipeline save events (L2+)
resource "harness_platform_policyset" "pipeline_governance" {
  count = var.profile_level >= 2 ? 1 : 0

  identifier = "hth_pipeline_governance"
  name       = "HTH Pipeline Governance"
  action     = "onsave"
  type       = "pipeline"
  enabled    = true

  policies {
    identifier = harness_platform_policy.require_approval[0].id
    severity   = "error"
  }
}

# Custom OPA governance policies from variable input (L2+)
resource "harness_platform_policy" "custom" {
  for_each = var.profile_level >= 2 ? var.governance_policies : {}

  identifier = each.key
  name       = each.value.name
  rego       = each.value.rego
}

# L3: Strict policy requiring signed artifacts in production pipelines
resource "harness_platform_policy" "require_artifact_verification" {
  count = var.profile_level >= 3 ? 1 : 0

  identifier = "hth_require_artifact_verification"
  name       = "Require Artifact Verification"

  rego = <<-REGO
    package pipeline

    deny[msg] {
      stage := input.pipeline.stages[_].stage
      stage.type == "Deployment"
      stage.spec.environment.type == "Production"
      artifact := stage.spec.serviceConfig.serviceDefinition.spec.artifacts.primary
      not artifact.spec.digest
      msg := "Production deployments must reference artifacts by digest, not tag (HTH Control 4.1 L3)"
    }
  REGO
}

# L3: Policy set with strict enforcement including artifact verification
resource "harness_platform_policyset" "strict_governance" {
  count = var.profile_level >= 3 ? 1 : 0

  identifier = "hth_strict_pipeline_governance"
  name       = "HTH Strict Pipeline Governance (L3)"
  action     = "onrun"
  type       = "pipeline"
  enabled    = true

  policies {
    identifier = harness_platform_policy.require_approval[0].id
    severity   = "error"
  }

  policies {
    identifier = harness_platform_policy.require_artifact_verification[0].id
    severity   = "error"
  }
}
# HTH Guide Excerpt: end terraform
