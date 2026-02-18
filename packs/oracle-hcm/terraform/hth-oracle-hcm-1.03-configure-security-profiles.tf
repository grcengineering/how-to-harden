# =============================================================================
# HTH Oracle HCM Control 1.3: Configure Security Profiles
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-6(1)
# Source: https://howtoharden.com/guides/oracle-hcm/#13-configure-security-profiles
# =============================================================================

# HTH Guide Excerpt: begin terraform
# OCI IAM policy restricting HCM admin access to the security manager group
resource "oci_identity_policy" "hcm_security_profile_policy" {
  compartment_id = var.oci_tenancy_ocid
  name           = "HTH-HCM-Security-Profiles"
  description    = "Restrict HCM security configuration to IT Security Manager group"

  statements = [
    "Allow group '${var.idcs_compartment_id}'/'${var.it_security_manager_group_name}' to manage identity-domains in compartment id ${var.idcs_compartment_id}",
    "Allow group '${var.idcs_compartment_id}'/'${var.hcm_admin_group_name}' to use identity-domains in compartment id ${var.idcs_compartment_id}",
    "Allow group '${var.idcs_compartment_id}'/'${var.hr_analyst_group_name}' to read identity-domains in compartment id ${var.idcs_compartment_id}",
  ]
}

# Password policy enforcing strong authentication requirements
resource "oci_identity_domains_password_policy" "hcm_password_policy" {
  idcs_endpoint = var.idcs_domain_url

  schemas     = ["urn:ietf:params:scim:schemas:oracle:idcs:PasswordPolicy"]
  name        = "HTH-HCM-Password-Policy"
  description = "Hardened password policy for Oracle HCM Cloud access"
  priority    = 1

  # Password complexity
  min_length       = var.profile_level >= 2 ? 15 : 12
  min_upper_case   = 1
  min_lower_case   = 1
  min_numerals     = 1
  min_special_chars = 1

  # Password lifecycle
  password_expires_after     = var.profile_level >= 2 ? 60 : 90
  num_passwords_in_history   = var.profile_level >= 2 ? 12 : 5
  min_password_age           = 1
  max_incorrect_attempts     = var.profile_level >= 2 ? 3 : 5
  lockout_duration           = var.profile_level >= 2 ? 30 : 15

  # L3: Disallow dictionary words
  dictionary_word_disallowed = var.profile_level >= 3 ? true : false
  first_name_disallowed      = true
  last_name_disallowed       = true
  user_name_disallowed       = true
}

# L2: Restrict compensation data visibility at the OCI policy layer
resource "oci_identity_policy" "restrict_compensation" {
  count = var.restrict_compensation_visibility ? 1 : 0

  compartment_id = var.oci_tenancy_ocid
  name           = "HTH-HCM-Restrict-Compensation"
  description    = "Deny compensation data access to non-authorized groups"

  statements = [
    "Allow group '${var.idcs_compartment_id}'/'${var.it_security_manager_group_name}' to manage compensation-data in compartment id ${var.idcs_compartment_id}",
  ]
}

# L2: Restrict payroll data access at the OCI policy layer
resource "oci_identity_policy" "restrict_payroll" {
  count = var.restrict_payroll_data ? 1 : 0

  compartment_id = var.oci_tenancy_ocid
  name           = "HTH-HCM-Restrict-Payroll"
  description    = "Restrict payroll data access to authorized roles only"

  statements = [
    "Allow group '${var.idcs_compartment_id}'/'${var.it_security_manager_group_name}' to manage payroll-data in compartment id ${var.idcs_compartment_id}",
  ]
}
# HTH Guide Excerpt: end terraform
