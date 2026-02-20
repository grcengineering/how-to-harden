# =============================================================================
# HTH Zscaler Control 3.2: Create Access Policies
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, AC-6 | CIS 6.4, 6.8
# Source: https://howtoharden.com/guides/zscaler/#32-create-access-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Retrieve the global access policy for rule attachment
data "zpa_policy_type" "access_policy" {
  policy_type = "ACCESS_POLICY"
}

# Access policy rule -- restrict access to hardened segment group by IdP group
resource "zpa_policy_access_rule" "hardened_access" {
  count = length(var.scim_group_ids) > 0 ? 1 : 0

  name        = "HTH-Hardened-Application-Access"
  description = "Restrict application access to authorized IdP groups only"
  action      = "ALLOW"
  policy_type = data.zpa_policy_type.access_policy.id
  operator    = "AND"

  conditions {
    operator = "OR"

    operands {
      object_type = "APP_GROUP"
      values      = [zpa_segment_group.hardened.id]
    }
  }

  conditions {
    operator = "OR"

    dynamic "operands" {
      for_each = var.scim_group_ids
      content {
        object_type   = "SCIM_GROUP"
        values        = [operands.value]
        idp_id        = var.idp_id
      }
    }
  }
}

# Default deny rule -- block all access not explicitly permitted
resource "zpa_policy_access_rule" "default_deny" {
  name        = "HTH-Default-Deny"
  description = "Default deny -- block all application access not explicitly allowed"
  action      = "DENY"
  policy_type = data.zpa_policy_type.access_policy.id
  order       = "99"
}

# HTH Guide Excerpt: end terraform
