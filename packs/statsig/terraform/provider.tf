terraform {
  required_version = ">= 1.7.0"
  required_providers {
    statsig = {
      source  = "statsig-io/statsig"
      version = "2.2.1"
    }
  }
}

# The provider reads STATSIG_CONSOLE_KEY. Never place a resolved key in HCL/state.
provider "statsig" {}

variable "hth_profile_level" {
  type    = number
  default = 1
  validation {
    condition     = contains([1, 2, 3, 4], var.hth_profile_level)
    error_message = "Use profile 1–4."
  }
}
