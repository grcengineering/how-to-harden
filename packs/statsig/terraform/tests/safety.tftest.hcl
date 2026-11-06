mock_provider "statsig" {}

run "default_is_noop" {
  command = plan
  assert {
    condition     = length(statsig_settings_project.reviewed) == 0 && length(statsig_settings_reviews.reviewed) == 0
    error_message = "Defaults must manage no settings."
  }
}

run "reviewed_project_is_closed_without_renaming" {
  command = plan
  variables {
    reviewed_project = { name = "existing-project", default_unit_type = "user_id" }
  }
  assert {
    condition     = statsig_settings_project.reviewed["project"].visibility == "CLOSED" && statsig_settings_project.reviewed["project"].name == "existing-project"
    error_message = "Only the explicit reviewed project settings may be managed."
  }
}

run "empty_project_values_fail" {
  command = plan
  variables {
    reviewed_project = { name = "", default_unit_type = "" }
  }
  expect_failures = [var.reviewed_project]
}

run "reviews_preserve_other_explicit_flags" {
  command = plan
  variables {
    reviewed_other_review_flags = {
      deployment_model                     = "warehouse", is_metric_review_required = true, is_metric_review_required_on_verified_only = false,
      is_whn_analysis_only_review_required = true, is_whn_source_review_required = true
    }
  }
  assert {
    condition     = statsig_settings_reviews.reviewed["reviews"].is_config_review_required && statsig_settings_reviews.reviewed["reviews"].is_whn_source_review_required && !statsig_settings_reviews.reviewed["reviews"].is_metric_review_required_on_verified_only
    error_message = "Config reviews must be required and other reviewed flags preserved."
  }
}

run "cloud_rejects_whn_flags" {
  command = plan
  variables {
    reviewed_other_review_flags = {
      deployment_model                     = "cloud", is_metric_review_required = false, is_metric_review_required_on_verified_only = false,
      is_whn_analysis_only_review_required = true, is_whn_source_review_required = false
    }
  }
  expect_failures = [var.reviewed_other_review_flags]
}
