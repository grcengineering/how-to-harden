# HTH Pack Contract: v1
#   control: dochub-1.1
#   guide: https://howtoharden.com/guides/dochub/#11-configure-saml-and-verify-domain-ownership
#   profile: L1
#   mode: read-only
#   requires: Terraform, HashiCorp DNS provider, DocHub displayed CNAME and approved resolver
# Source (reviewed 2026-11-27): https://help.dochub.com/knowledge-base/account-settings/sso-single-sign-on
# HTH Guide Excerpt: begin verify-saml-domain-cname
terraform {
  required_providers {
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.2"
    }
  }
}

variable "verification_name" {
  type        = string
  description = "Fully qualified verification CNAME name shown in DocHub."
  validation {
    condition     = can(regex("^([A-Za-z0-9_-]{1,63}\\.)+[A-Za-z0-9-]{2,63}\\.?$", var.verification_name))
    error_message = "Provide the fully qualified verification record name."
  }
}

variable "expected_target" {
  type        = string
  sensitive   = true
  description = "Expected fully qualified CNAME target shown in DocHub."
  validation {
    condition     = can(regex("^([A-Za-z0-9_-]{1,63}\\.)+[A-Za-z0-9-]{2,63}\\.?$", var.expected_target))
    error_message = "Provide the fully qualified verification CNAME target."
  }
}

# DNS only. Use a trusted resolver, protect state, and check the vendor UI separately.
data "dns_cname_record_set" "verification" {
  host = "${trimsuffix(var.verification_name, ".")}."
  lifecycle {
    postcondition {
      condition     = lower(trimsuffix(self.cname, ".")) == lower(trimsuffix(var.expected_target, "."))
      error_message = "The CNAME did not match DocHub's displayed verification target."
    }
  }
}

output "dns_cname_matches" {
  value      = true
  depends_on = [data.dns_cname_record_set.verification]
}
# HTH Guide Excerpt: end verify-saml-domain-cname
