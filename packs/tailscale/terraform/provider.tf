# Official provider reference: https://github.com/tailscale/terraform-provider-tailscale/tree/v0.29.3/docs
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "= 0.29.3"
    }
  }
}

# Supply credentials and TAILSCALE_TAILNET through provider environment variables.
# Never commit credentials, plan files, state, or evidence. Keep the default origin.
provider "tailscale" {
  base_url = "https://api.tailscale.com"
}

variable "hth_profile_level" {
  description = "Set TF_VAR_hth_profile_level to the intended profile (1..4)."
  type        = number
  default     = 1
  validation {
    condition     = contains([1, 2, 3, 4], var.hth_profile_level)
    error_message = "hth_profile_level must be 1, 2, 3 or 4."
  }
}

variable "collect_inventory" {
  description = "Explicit opt-in to read current users, devices and policy into private Terraform state."
  type        = bool
  default     = false
}
