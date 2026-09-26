# =============================================================================
# HTH GitHub Control 5.02: Enable Delete Branch on Merge
# Profile Level: L2 (Walk)
# Frameworks: NIST CM-3
# Source: https://howtoharden.com/guides/github/#62-pin-dependencies-to-specific-versions-hash-verification
#
# github_repository manages the WHOLE repository. The import block adopts the
# existing repository instead of creating a new one, and archive_on_destroy
# archives rather than deletes it on destroy. ignore_changes keeps every other
# repository setting as it is today (without it, undeclared settings revert to
# provider defaults on the first apply).
# =============================================================================

# HTH Guide Excerpt: begin terraform
import {
  to = github_repository.how_to_harden
  id = var.repository_name
}

resource "github_repository" "how_to_harden" {
  name                   = var.repository_name
  delete_branch_on_merge = true
  archive_on_destroy     = true

  # Manage only this control's setting; leave every other repository
  # setting exactly as it is today.
  lifecycle {
    ignore_changes = [
      allow_auto_merge,
      allow_merge_commit,
      allow_rebase_merge,
      allow_squash_merge,
      allow_update_branch,
      archived,
      auto_init,
      description,
      gitignore_template,
      has_discussions,
      has_issues,
      has_projects,
      has_wiki,
      homepage_url,
      is_template,
      license_template,
      merge_commit_message,
      merge_commit_title,
      squash_merge_commit_message,
      squash_merge_commit_title,
      pages,
      security_and_analysis,
      template,
    ]
  }
}
# HTH Guide Excerpt: end terraform
