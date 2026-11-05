# HTH Pack Contract: v1
#   control: cursor-origin-1.1
#   guide: https://howtoharden.com/guides/cursor-origin/#11-limit-codebase-and-repository-access
#   profile: L1
#   mode: read-only
#   requires: Terraform >=1.5; cursor/cursor =0.8.0; CURSOR_TOKEN; reviewed hth_origin_owner/hth_origin_repo
#   changes: reads repository metadata and direct repository/namespace grants; Terraform state contains actor IDs
#   source: https://github.com/cursor/terraform-provider-cursor/tree/v0.8.0/docs/data-sources
# HTH Guide Excerpt: begin inventory-origin-grants
# Use with this directory's providers.tf and variables.tf. Never run stateful
# Terraform with an unapproved backend or log full state; sensitive hides CLI
# display, but does not encrypt state. This example is not an access verdict.
data "cursor_origin_repo" "hth_reviewed" {
  owner = var.hth_origin_owner
  name  = var.hth_origin_repo
}

data "cursor_origin_repo_grants" "hth_reviewed" {
  owner = var.hth_origin_owner
  repo  = var.hth_origin_repo
}

data "cursor_origin_owner_grants" "hth_reviewed" {
  owner = var.hth_origin_owner
}

output "hth_origin_access_inventory" {
  sensitive = true
  value = {
    repository_id             = data.cursor_origin_repo.hth_reviewed.id
    repository_visibility     = data.cursor_origin_repo.hth_reviewed.visibility
    repository_direct_grants  = data.cursor_origin_repo_grants.hth_reviewed.grants
    namespace_direct_grants   = data.cursor_origin_owner_grants.hth_reviewed.grants
    effective_access_assessed = false
  }
}
# Repo grants omit inherited namespace access; namespace grants omit per-repo
# grants. Neither resolves group membership, custom policy semantics or every
# repository in the namespace. Review those separately before changing access.
# HTH Guide Excerpt: end inventory-origin-grants
