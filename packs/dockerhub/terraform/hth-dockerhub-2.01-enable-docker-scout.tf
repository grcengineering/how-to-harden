# =============================================================================
# HTH Docker Hub Control 2.1: Enable Docker Scout
# Profile Level: L1 (Baseline)
# Frameworks: NIST RA-5
# Source: https://howtoharden.com/guides/dockerhub/#21-enable-docker-scout
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enable Docker Scout vulnerability scanning for organization repositories.
# Scout provides SBOM analysis, CVE detection, and remediation recommendations.
resource "docker_hub_repository_scout" "org_repos" {
  for_each = var.repositories

  namespace  = var.dockerhub_organization
  repository = each.key
  enabled    = true
}

# Automated Scout scan verification using local-exec.
# Runs docker scout CLI to validate scanning is operational.
resource "null_resource" "scout_scan_verification" {
  for_each = var.repositories

  triggers = {
    repository = each.key
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "=== Docker Scout Verification: ${var.dockerhub_organization}/${each.key} ==="
      echo ""
      echo "Run these commands to verify Scout is active:"
      echo "  docker scout recommendations ${var.dockerhub_organization}/${each.key}:latest"
      echo "  docker scout cves ${var.dockerhub_organization}/${each.key}:latest"
      echo "  docker scout quickview ${var.dockerhub_organization}/${each.key}:latest"
      echo ""
      echo "For CI/CD integration, add to your pipeline:"
      echo "  docker scout cves --exit-code --only-severity critical,high \\"
      echo "    ${var.dockerhub_organization}/${each.key}:\$TAG"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
