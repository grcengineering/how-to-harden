mock_provider "anthropic" {}

run "empty_by_default" {
  command = plan
  assert {
    condition     = length(anthropic_workspace.environment) == 0
    error_message = "The sample must not create workspaces without explicit names."
  }
}

run "scoped_us_workspaces" {
  command = plan
  variables {
    workspace_names = ["engineering-dev", "engineering-prod"]
  }
  assert {
    condition = alltrue([for w in anthropic_workspace.environment :
      w.data_residency.workspace_geo == "us" && w.data_residency.default_inference_geo == "us" &&
    w.data_residency.allowed_inference_geos.values == toset(["us"])])
    error_message = "Every created workspace must carry the reviewed residency boundary."
  }
}
