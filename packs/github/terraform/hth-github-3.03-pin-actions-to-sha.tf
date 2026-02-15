# =============================================================================
# HTH GitHub Control 3.03: Pin Actions to Full-Length SHA
# Profile Level: L2 (Hardened)
# Frameworks: NIST SA-12, SI-7
# Source: https://howtoharden.com/guides/github/#33-pin-actions-to-sha
# =============================================================================

# HTH Guide Excerpt: begin terraform
# NOTE: SHA pinning is enforced at the workflow file level, not via a dedicated
# Terraform resource. This control restricts allowed actions to "selected" so
# that only explicitly approved actions (pinned to SHA in workflow YAML) can run.
resource "github_actions_repository_permissions" "how_to_harden_sha_pinning" {
  repository      = var.repository_name
  enabled         = true
  allowed_actions = "selected"
}
# HTH Guide Excerpt: end terraform
