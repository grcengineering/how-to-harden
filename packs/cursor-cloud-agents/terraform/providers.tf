# Source-backed schema, fetched 2026-11-05. Temporary init/schema validation only;
# no vendor credentials, plan, apply, import or tenant operations were used.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    cursor = {
      source  = "cursor/cursor"
      version = "= 0.8.0"
    }
  }
}

# Inject CURSOR_TOKEN at execution time; never commit a token or state file.
# Team/organization admin keys are not required for these workflow operations.
provider "cursor" {}
