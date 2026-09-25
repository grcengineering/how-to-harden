# =============================================================================
# HTH Cloudflare Control 1.5: Retire the Global API Key and Enforce Scoped API Tokens
# Profile Level: L1 (Crawl)
# Frameworks: NIST AC-6(1), IA-5 | CIS 5.4, 6.8
# Source: https://howtoharden.com/guides/cloudflare/#15-retire-the-global-api-key-and-enforce-scoped-api-tokens
#
# An account-owned API token for automation: named permission groups only,
# scoped to one account, with an expiry and a client IP allowlist.
# Resource syntax: developers.cloudflare.com/fundamentals/api/how-to/create-via-api/
#   single account = "com.cloudflare.api.account.<ACCOUNT_ID>": "*"
# The token value is returned once, as the sensitive attribute `value`; write
# it straight to a secrets manager. Creating account tokens requires a Super
# Administrator.
# =============================================================================

# HTH Guide Excerpt: begin terraform
data "cloudflare_account_api_token_permission_groups_list" "selected" {
  for_each   = toset(var.automation_token_permission_groups)
  account_id = var.cloudflare_account_id
  name       = each.value
}

resource "cloudflare_account_token" "automation" {
  account_id = var.cloudflare_account_id
  name       = "hth-automation"
  expires_on = var.automation_token_expires_on

  policies = [{
    effect = "allow"
    permission_groups = [
      for name in var.automation_token_permission_groups : {
        id = data.cloudflare_account_api_token_permission_groups_list.selected[name].result[0].id
      }
    ]
    resources = jsonencode({
      "com.cloudflare.api.account.${var.cloudflare_account_id}" = "*"
    })
  }]

  condition = {
    request_ip = {
      in = var.automation_token_allowed_cidrs
    }
  }
}
# HTH Guide Excerpt: end terraform
