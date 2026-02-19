# =============================================================================
# HTH Terraform Cloud Control 3.02: Sensitive Variable Handling
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-28
# Source: https://howtoharden.com/guides/terraform-cloud/#32-sensitive-variable-handling
# =============================================================================

# HTH Guide Excerpt: begin sensitive-variables
# Mark variables as sensitive
variable "db_password" {
  type      = string
  sensitive = true
}

# Output marking
output "connection_string" {
  value     = local.connection_string
  sensitive = true
}
# HTH Guide Excerpt: end sensitive-variables
