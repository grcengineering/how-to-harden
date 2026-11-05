# HTH Pack Contract: v1
#   control: cursor-origin-2.1
#   guide: https://howtoharden.com/guides/cursor-origin/#21-enforce-native-merge-and-push-rulesets
#   profile: L1
#   mode: mutating
#   requires: Terraform >=1.5; cursor/cursor =0.8.0; CURSOR_TOKEN; reviewed namespace/repo/refs/check actor IDs; hth_manage_rulesets=true
#   changes: opt-in active merge and push rulesets; no rule or bypass preservation is inferred
#   source: https://github.com/cursor/terraform-provider-cursor/blob/v0.8.0/docs/resources/origin_repo_ruleset.md
# HTH Guide Excerpt: begin protect-origin-rulesets
# OFF by default. Read/import existing rulesets and preserve all intended rules
# and bypass actors in reviewed configuration: updates replace the full lists.
# This is one (section,type) pack with both native rule kinds, not duplicate files.
resource "cursor_origin_repo_ruleset" "hth_merge" {
  count = var.hth_manage_rulesets ? 1 : 0

  owner               = var.hth_origin_owner
  repo                = var.hth_origin_repo
  name                = "${var.hth_ruleset_name}-merge"
  kind                = "merge_branch"
  enforcement         = "active"
  included_ref_names  = var.hth_protected_refs
  deletion_protection = true
  allow_unenforced    = false
  allow_broad_bypass  = false

  rule {
    pull_request {
      required_approving_review_count   = 2
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = true
      require_last_push_approval        = true
      required_review_thread_resolution = true
    }
  }

  rule {
    require_branch_up_to_date {}
  }

  rule {
    require_status_checks {
      # Keep this block explicit: provider 0.8.0 fails schema validation when
      # an unknown-length dynamic required_check list reaches its validator.
      required_check {
        actor_kind = try(var.hth_required_check.actor_kind, "")
        actor_id   = try(var.hth_required_check.actor_id, "")
        group_key  = try(var.hth_required_check.group_key, "")
      }
    }
  }

  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = var.hth_required_check != null
      error_message = "Identify the actual trusted CI check before managing this ruleset; preserve/add all other intended checks as explicit blocks."
    }
  }
}

resource "cursor_origin_repo_ruleset" "hth_push" {
  count = var.hth_manage_rulesets ? 1 : 0

  owner               = var.hth_origin_owner
  repo                = var.hth_origin_repo
  name                = "${var.hth_ruleset_name}-push"
  kind                = "push_branch"
  enforcement         = "active"
  included_ref_names  = var.hth_protected_refs
  deletion_protection = true
  allow_unenforced    = false
  allow_broad_bypass  = false

  rule {
    block_direct_updates {}
  }
  rule {
    non_fast_forward {}
  }
  rule {
    deletion {}
  }

  lifecycle {
    prevent_destroy = true
  }
}
# No bypass_actor is created. Omitting one from an imported managed ruleset's
# configuration removes it on update; this is not a merge operation.
# HTH Guide Excerpt: end protect-origin-rulesets
