# =============================================================================
# HTH Docker Hub Control 3.2: Prevent Secret Exposure
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-28, IA-5(7)
# Source: https://howtoharden.com/guides/dockerhub/#32-prevent-secret-exposure
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Secret exposure prevention via CI/CD pipeline scanning.
# Docker Hub images are scanned before push using local-exec hooks.
# In 2024, researchers found 10,456 images exposing secrets on Docker Hub.

# Pre-push secret scanning hook.
# Integrates with CI/CD to scan images for embedded secrets before pushing.
resource "null_resource" "secret_scanning_pipeline" {
  triggers = {
    organization = var.dockerhub_organization
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "=== Docker Image Secret Scanning Setup ==="
      echo ""
      echo "Add these steps to your CI/CD pipeline BEFORE docker push:"
      echo ""
      echo "Option 1: Docker Scout (built-in):"
      echo "  docker scout cves --only-package-type gem,npm,pip <image>"
      echo ""
      echo "Option 2: Trivy (open source):"
      echo "  trivy image --scanners secret <image>"
      echo ""
      echo "Option 3: Trufflehog:"
      echo "  trufflehog docker --image <image>"
      echo ""
      echo "Dockerfile best practices:"
      echo "  - Use multi-stage builds to exclude build-time secrets"
      echo "  - Use --mount=type=secret for build arguments"
      echo "  - Never use ENV for credentials"
      echo "  - Add .dockerignore with: .env, *.pem, *.key, credentials.*"
      echo ""
      echo "Example secure Dockerfile pattern:"
      echo "  # syntax=docker/dockerfile:1"
      echo "  FROM golang:1.22 AS builder"
      echo "  RUN --mount=type=secret,id=api_key ./configure"
      echo "  FROM gcr.io/distroless/static-debian12"
      echo "  COPY --from=builder /app /app"
    EOT
  }
}

# L2+: Automated Dockerfile linting for secret patterns.
resource "null_resource" "dockerfile_lint_setup" {
  count = var.profile_level >= 2 ? 1 : 0

  triggers = {
    organization = var.dockerhub_organization
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "=== Dockerfile Security Linting (L2 Hardened) ==="
      echo ""
      echo "Add hadolint to CI/CD pipeline:"
      echo "  docker run --rm -i hadolint/hadolint < Dockerfile"
      echo ""
      echo "Key rules enforced:"
      echo "  DL3000 - Use absolute WORKDIR"
      echo "  DL3001 - No invalid CMD instructions"
      echo "  DL3002 - Do not switch to root USER"
      echo "  DL3003 - Use WORKDIR instead of cd"
      echo "  DL3006 - Always tag the version of an image"
      echo "  DL3007 - Do not use latest tag"
      echo "  DL3009 - Delete apt-get lists after install"
      echo "  DL4006 - Set SHELL option -o pipefail"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
