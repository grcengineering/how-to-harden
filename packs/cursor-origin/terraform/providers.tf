# Fetched schema: https://github.com/cursor/terraform-provider-cursor/tree/v0.8.0/docs
# Temporary init/schema validation only; no vendor credentials, plan, apply,
# import, credential exchange or live tenant API call was run by HTH.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    cursor = {
      source  = "cursor/cursor"
      version = "= 0.8.0"
    }
  }
}

# CURSOR_TOKEN is supplied by an approved runtime secret-injection mechanism.
# Do not put token values in .tf, .tfvars, command arguments or committed state.
# Team/organization admin keys are unnecessary for the ID-based reads below.
provider "cursor" {}
