# =============================================================================
# HTH Docker Hub Control 2.2: Image Signing (Content Trust)
# Profile Level: L2 (Hardened)
# Frameworks: NIST SI-7
# Source: https://howtoharden.com/guides/dockerhub/#22-image-signing-content-trust
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Docker Content Trust (DCT) enforcement for image signing.
# Only applied at L2+ profile levels.
# DCT uses Notary to cryptographically sign images at push time.
resource "null_resource" "content_trust_setup" {
  count = var.profile_level >= 2 ? 1 : 0

  triggers = {
    organization = var.dockerhub_organization
    enabled      = var.enable_content_trust
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "=== Docker Content Trust (DCT) Setup ==="
      echo ""
      echo "Enable DCT globally in your environment:"
      echo "  export DOCKER_CONTENT_TRUST=1"
      echo ""
      echo "Initialize signing for each repository:"
      echo "  docker trust key generate ${var.dockerhub_organization}"
      echo "  docker trust signer add --key ${var.dockerhub_organization}.pub ${var.dockerhub_organization} ${var.dockerhub_organization}/<repo>:latest"
      echo ""
      echo "Sign and push an image:"
      echo "  DOCKER_CONTENT_TRUST=1 docker push ${var.dockerhub_organization}/<repo>:latest"
      echo ""
      echo "Verify signatures:"
      echo "  docker trust inspect --pretty ${var.dockerhub_organization}/<repo>:latest"
      echo ""
      echo "CI/CD enforcement:"
      echo "  Set DOCKER_CONTENT_TRUST=1 in pipeline environment"
      echo "  Unsigned images will be rejected on pull"
    EOT
  }
}

# L3: Enforce Sigstore/Cosign signing for maximum security environments.
# Cosign provides keyless signing via OIDC identity for stronger provenance.
resource "null_resource" "cosign_signing_setup" {
  count = var.profile_level >= 3 ? 1 : 0

  triggers = {
    organization = var.dockerhub_organization
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "=== Sigstore/Cosign Image Signing (L3 Maximum Security) ==="
      echo ""
      echo "Install cosign:"
      echo "  go install github.com/sigstore/cosign/v2/cmd/cosign@latest"
      echo ""
      echo "Keyless signing (OIDC-based):"
      echo "  cosign sign ${var.dockerhub_organization}/<repo>:latest"
      echo ""
      echo "Key-pair signing:"
      echo "  cosign generate-key-pair"
      echo "  cosign sign --key cosign.key ${var.dockerhub_organization}/<repo>:latest"
      echo ""
      echo "Verify in CI/CD:"
      echo "  cosign verify --key cosign.pub ${var.dockerhub_organization}/<repo>:latest"
      echo ""
      echo "SLSA provenance attestation:"
      echo "  cosign attest --predicate provenance.json ${var.dockerhub_organization}/<repo>:latest"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
