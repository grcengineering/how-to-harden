# =============================================================================
# HTH Docker Hub Control 3.1: Private Repository Configuration
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, AC-6
# Source: https://howtoharden.com/guides/dockerhub/#31-private-repository-configuration
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create repositories with private visibility by default.
# Private repositories prevent unauthorized access to container images.
resource "docker_hub_repository" "managed" {
  for_each = var.repositories

  namespace   = var.dockerhub_organization
  name        = each.key
  description = each.value.description
  private     = each.value.visibility == "private" ? true : false
}

# Configure team-based access to repositories.
# Individual user permissions are avoided in favor of team-based RBAC.
resource "docker_hub_repository_team_permission" "team_access" {
  for_each = var.team_repository_permissions

  org_name   = var.dockerhub_organization
  team_name  = each.key
  permission = each.value.permission
}

# Quarterly permission audit reminder.
# Repository permissions should be reviewed quarterly per the hardening guide.
resource "null_resource" "repository_audit_reminder" {
  triggers = {
    quarterly_check = formatdate("YYYY-QQ", timestamp())
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "=== Docker Hub Repository Permission Audit ==="
      echo ""
      echo "Quarterly audit checklist:"
      echo "  1. Review all repository visibility settings"
      echo "  2. Verify team-based access (no individual permissions)"
      echo "  3. Remove unused or stale repositories"
      echo "  4. Check for repositories that should be private"
      echo ""
      echo "API audit command:"
      echo "  curl -s -H 'Authorization: Bearer <token>' \\"
      echo "    'https://hub.docker.com/v2/repositories/${var.dockerhub_organization}/?page_size=100' \\"
      echo "    | jq '.results[] | {name, is_private, last_updated}'"
    EOT
  }

  lifecycle {
    ignore_changes = [triggers]
  }
}
# HTH Guide Excerpt: end terraform
