# =============================================================================
# HTH SendGrid Control 1.4: Configure IP Access Management
# Profile Level: L2 (Hardened)
# Frameworks: CIS 13.5, NIST AC-17
# Source: https://howtoharden.com/guides/sendgrid/#14-configure-ip-access-management
# =============================================================================
#
# NOTE: The kenzo0107/sendgrid Terraform provider does not currently expose an
# IP Access Management resource. IP allowlisting must be configured via the
# SendGrid UI or the v3 API directly.
#
# API reference for manual/scripted enforcement:
#   POST https://api.sendgrid.com/v3/access_settings/whitelist
#   Body: { "ips": [{ "ip": "192.168.1.1" }] }
#
# Validation:
#   curl -s https://api.sendgrid.com/v3/access_settings/whitelist \
#     -H "Authorization: Bearer $SENDGRID_API_KEY"

# HTH Guide Excerpt: begin terraform
# IP Access Management is not yet supported by the kenzo0107/sendgrid provider.
# Configure via UI: Settings > IP Access Management
#
# Recommended automation approach using the SendGrid v3 API:
#
# variable "allowed_ips" is defined in variables.tf for future provider support.
#
# Manual API enforcement:
#   for ip in var.allowed_ips; do
#     curl -X POST https://api.sendgrid.com/v3/access_settings/whitelist \
#       -H "Authorization: Bearer $SENDGRID_API_KEY" \
#       -H "Content-Type: application/json" \
#       -d "{\"ips\": [{\"ip\": \"$ip\"}]}"
#   done
# HTH Guide Excerpt: end terraform
