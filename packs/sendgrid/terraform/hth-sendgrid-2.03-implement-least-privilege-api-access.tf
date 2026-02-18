# =============================================================================
# HTH SendGrid Control 2.3: Implement Least Privilege API Access
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/sendgrid/#23-implement-least-privilege-api-access
# =============================================================================
#
# This control is enforced through the api_keys variable in Control 2.1.
# Each key is created with explicit scopes -- never full access.
#
# Common least-privilege scope sets:
#   Transactional email:  ["mail.send"]
#   Marketing campaigns:  ["mail.send", "marketing.automation.read",
#                          "marketing.automation.update"]
#   Statistics only:      ["stats.read", "stats.global.read"]
#   Webhook management:   ["user.webhooks.event.settings.read",
#                          "user.webhooks.event.settings.update"]

# HTH Guide Excerpt: begin terraform
# Least privilege is enforced by the api_keys variable structure.
# Each key in var.api_keys requires an explicit set of scopes.
# Full-access keys are never created by this code pack.
#
# Example variable configuration in terraform.tfvars:
#
# api_keys = {
#   transactional_sender = {
#     scopes = ["mail.send"]
#   }
#   marketing_automation = {
#     scopes = ["mail.send", "marketing.automation.read",
#               "marketing.automation.update"]
#   }
#   stats_reader = {
#     scopes = ["stats.read", "stats.global.read"]
#   }
# }
# HTH Guide Excerpt: end terraform
