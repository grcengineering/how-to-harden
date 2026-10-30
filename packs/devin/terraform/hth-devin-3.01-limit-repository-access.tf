# HTH Pack Contract: v1
#   control: devin-3.1
#   guide: https://howtoharden.com/guides/devin/#31-limit-repository-and-mcp-access
#   profile: L2
#   mode: mutating
#   requires: DEVIN_TOKEN(enterprise service user with repository-permission management), org_id, git_connection_id, approved_repo_path
# NIST 800-53 AC-3/AC-6. Source (available in 0.5.0):
# https://github.com/CognitionAI/terraform-provider-devin/blob/v0.5.0/docs/resources/git_permission.md
# ADDITIVE grant, not a full access policy: other broad grants may still permit writes.
# Review/remove overlapping grants separately; do not claim this tightens existing ones.
# No apply performed by HTH. Copy providers.tf and this file into a fresh directory.
# HTH Guide Excerpt: begin exact-repo-read-only
variable "org_id" {
  type = string
}
variable "git_connection_id" {
  type = string
}
variable "approved_repo_path" {
  type        = string
  description = "One exact owner/repository path approved for this organization."
  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.approved_repo_path))
    error_message = "Provide an exact owner/repository path, never a wildcard or group prefix."
  }
}
resource "devin_git_permission" "hth_one_repo" {
  org_id            = var.org_id
  git_connection_id = var.git_connection_id
  repo_path         = var.approved_repo_path
  read_only         = true
}
# HTH Guide Excerpt: end exact-repo-read-only
