# HTH Pack Contract: v1
#   control: cursor-origin-3.5
#   guide: https://howtoharden.com/guides/cursor-origin/#35-require-trusted-ssh-certificates
#   profile: L2
#   mode: mutating
#   requires: Terraform >=1.5; cursor/cursor =0.8.0; CURSOR_TOKEN; team namespace; independently verified CA public key; explicit opt-ins and proven recovery access
#   changes: optional CA inventory; opt-in trusted CA and separately gated certificate requirement; no credential generation
#   source: https://github.com/cursor/terraform-provider-cursor/blob/v0.8.0/docs/resources/origin_ssh_certificate_authority.md
# HTH Guide Excerpt: begin origin-ssh-certificate-policy
# All writes default OFF. Import existing authorities/requirement before adopting
# them. Never supply a private key. Native deletion_protection and Terraform
# prevent_destroy intentionally block casual replacement and removal.
data "cursor_origin_ssh_certificate_authorities" "hth_observed" {
  count     = var.hth_read_ssh_posture || var.hth_manage_ssh_ca || var.hth_require_ssh_certificates ? 1 : 0
  namespace = var.hth_origin_owner
}

resource "cursor_origin_ssh_certificate_authority" "hth_reviewed" {
  count = var.hth_manage_ssh_ca ? 1 : 0

  namespace           = var.hth_origin_owner
  name                = var.hth_ssh_ca_name
  public_key          = var.hth_ssh_ca_public_key
  deletion_protection = true

  lifecycle {
    prevent_destroy       = true
    create_before_destroy = true
    precondition {
      condition     = length(trimspace(var.hth_ssh_ca_public_key)) > 0 && !strcontains(var.hth_ssh_ca_public_key, "PRIVATE KEY")
      error_message = "Supply and independently verify the organization's approved CA public key, never a private key."
    }
  }
}

resource "cursor_origin_ssh_certificate_requirement" "hth_namespace" {
  count = var.hth_require_ssh_certificates ? 1 : 0

  namespace            = var.hth_origin_owner
  require_certificates = true
  deletion_protection  = true
  depends_on           = [cursor_origin_ssh_certificate_authority.hth_reviewed]

  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = var.hth_manage_ssh_ca && var.hth_recovery_access_tested
      error_message = "Manage/import the verified CA and prove independent recovery access before requiring certificates."
    }
  }
}

output "hth_origin_ssh_authorities_observed" {
  sensitive = true
  value     = data.cursor_origin_ssh_certificate_authorities.hth_observed
}
# Requiring certificates refuses user-registered SSH keys and user API keys over
# HTTPS. It does not prove every application credential path is revoked.
# The CA API has no update/rename. Key/namespace changes replace the authority;
# removing it invalidates its issued certificates. Stage overlapping authorities
# during an approved rotation; create_before_destroy cannot override these
# deletion guards. The final authority cannot be removed while required.
# HTH Guide Excerpt: end origin-ssh-certificate-policy
