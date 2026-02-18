# =============================================================================
# HTH Oracle HCM Control 1.2: Implement Security Roles
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, AC-6
# Source: https://howtoharden.com/guides/oracle-hcm/#12-implement-security-roles
# =============================================================================

# HTH Guide Excerpt: begin terraform
# IT Security Manager group — security configuration access
resource "oci_identity_domains_group" "it_security_managers" {
  idcs_endpoint = var.idcs_domain_url

  schemas      = ["urn:ietf:params:scim:schemas:core:2.0:Group"]
  display_name = var.it_security_manager_group_name

  urnietfpaaboramsscaborimschemasoaboracleidcsextensiongroup_group {
    description = "IT Security Managers — security configuration access for Oracle HCM"
  }
}

# HCM Application Administrator group — full HCM admin
resource "oci_identity_domains_group" "hcm_admins" {
  idcs_endpoint = var.idcs_domain_url

  schemas      = ["urn:ietf:params:scim:schemas:core:2.0:Group"]
  display_name = var.hcm_admin_group_name

  urnietfpaaboramsscaborimschemasoaboracleidcsextensiongroup_group {
    description = "HCM Application Administrators — full admin access for Oracle HCM"
  }
}

# HR Analyst group — read-only HR data access
resource "oci_identity_domains_group" "hr_analysts" {
  idcs_endpoint = var.idcs_domain_url

  schemas      = ["urn:ietf:params:scim:schemas:core:2.0:Group"]
  display_name = var.hr_analyst_group_name

  urnietfpaaboramsscaborimschemasoaboracleidcsextensiongroup_group {
    description = "HR Analysts — read-only access to HR data in Oracle HCM"
  }
}

# Dynamic group for HCM service instances (for OCI policy grants)
resource "oci_identity_domains_dynamic_resource_group" "hcm_service_instances" {
  idcs_endpoint = var.idcs_domain_url

  schemas      = ["urn:ietf:params:scim:schemas:oracle:idcs:DynamicResourceGroup"]
  display_name = "HTH-HCM-Service-Instances"
  description  = "Dynamic group matching Oracle HCM Cloud service instances"

  matching_rule = "Any {instance.compartment.id = '${var.idcs_compartment_id}'}"
}
# HTH Guide Excerpt: end terraform
