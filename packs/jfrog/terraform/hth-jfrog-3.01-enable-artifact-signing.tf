# =============================================================================
# HTH JFrog Control 3.1: Enable Artifact Signing
# Profile Level: L2 (Hardened)
# Frameworks: NIST SI-7
# Source: https://howtoharden.com/guides/jfrog/#31-enable-artifact-signing
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Configure GPG signing key for artifact verification (L2+)
resource "artifactory_keypair" "gpg_signing" {
  count = var.profile_level >= 2 ? 1 : 0

  pair_name   = "hth-artifact-signing"
  pair_type   = "GPG"
  alias       = "hth-gpg"
  public_key  = var.gpg_public_key
  passphrase  = ""
}

# Associate signing key with release repository for signature enforcement
resource "artifactory_local_maven_repository" "signed_release" {
  count = var.profile_level >= 2 ? 1 : 0

  key                   = "${var.release_repo_key}-signed"
  description           = "HTH: Signed release repository with GPG verification (L2+)"
  handle_releases       = true
  handle_snapshots      = false
  xray_index            = true
  primary_keypair_ref   = artifactory_keypair.gpg_signing[0].pair_name
}

# HTH Guide Excerpt: end terraform
