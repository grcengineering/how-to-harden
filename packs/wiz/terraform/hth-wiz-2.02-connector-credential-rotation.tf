# =============================================================================
# HTH Wiz Control 2.2: Connector Credential Rotation
# Profile Level: L2 (Hardened)
# Frameworks: NIST IA-5(1)
# Source: https://howtoharden.com/guides/wiz/#22-connector-credential-rotation
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Credential rotation monitoring control
# Detects cloud connectors with credentials that have not been rotated
# within the organization's rotation policy window.
#
# Rotation schedule:
#   AWS:   External ID rotation annually
#   Azure: App registration secret rotation quarterly
#   GCP:   Service account key rotation quarterly
resource "wiz_control" "connector_credential_rotation" {
  count = var.profile_level >= 2 ? 1 : 0

  name        = "HTH: Connector Credential Rotation Monitoring"
  description = "Detects cloud connectors with stale credentials that require rotation per HTH hardening guide section 2.2"
  severity    = "HIGH"
  enabled     = true
  project_id  = "*"

  resolution_recommendation = "Rotate connector credentials according to schedule: AWS External ID annually, Azure app secret quarterly, GCP service account key quarterly. See https://howtoharden.com/guides/wiz/#22-connector-credential-rotation"

  query = jsonencode({
    type = [
      "CLOUD_ACCOUNT"
    ]
    select = true
    where = {
      status = {
        EQUALS = [
          "CONNECTED"
        ]
      }
    }
  })

  scope_query = jsonencode({
    type = [
      "SUBSCRIPTION"
    ]
    select = true
  })
}
# HTH Guide Excerpt: end terraform
