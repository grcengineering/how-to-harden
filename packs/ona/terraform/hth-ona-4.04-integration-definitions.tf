# HTH Pack Contract: v1
#   control: ona-4.4
#   guide: https://howtoharden.com/guides/ona/#44-approve-integration-scopes-trigger-identities-and-offboarding
#   profile: L2
#   mode: read-only
#   requires: ONA_TOKEN; Terraform>=1.14, Linux; shared versions.tf
# Source: https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/data-sources/integration_definitions.md
# Fetched 2026-11-05. No live validation. Review/import/plan before any application.
# Discovery returns NON-SECRET metadata; definitions are managed by Ona.
# Experimental definitions depend on backend visibility, not a complete catalog.
# Built-in integrations cannot override auth/credentials; custom MCP is separate.
# HTH Guide Excerpt: begin terraform
data "ona_integration_definitions" "available" {}
output "ona_integration_review_inventory" {
  value = [for definition in data.ona_integration_definitions.available.definitions : {
    id           = definition.id
    name         = definition.name
    host         = definition.host
    categories   = definition.categories
    experimental = definition.experimental
  }]
}
# HTH Guide Excerpt: end terraform
