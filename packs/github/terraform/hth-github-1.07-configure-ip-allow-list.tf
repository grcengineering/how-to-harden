# =============================================================================
# HTH GitHub Control 1.07: Configure Enterprise IP Allow List
# Profile Level: L2 (Walk)
# Frameworks: NIST AC-17, SC-7
# Source: https://howtoharden.com/guides/github/#15-configure-enterprise-ip-allow-list
#
# Adds an allow-list ENTRY only. It does not turn the allow list on: enable the
# list in the enterprise console only after an entry covering your own egress
# IP exists, or you lock yourself (and this token) out.
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_enterprise_ip_allow_list_entry" "corporate" {
  enterprise_slug = var.enterprise_slug
  ip              = var.corporate_cidr
  name            = "Corporate Network"
  is_active       = true
}
# HTH Guide Excerpt: end terraform
