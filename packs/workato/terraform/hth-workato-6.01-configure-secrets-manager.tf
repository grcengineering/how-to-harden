# HTH Workato Control 6.01: Configure External Secrets Manager Integration
# Profile: L3 | NIST: SC-12, IA-5(7)
# https://howtoharden.com/guides/workato/#61-configure-external-secrets-manager-integration

# HTH Guide Excerpt: begin terraform-secrets-manager
resource "aws_secretsmanager_secret" "workato_salesforce" {
  name        = "workato/connections/salesforce-prod"
  description = "Workato Salesforce production connection credentials"

  tags = {
    Application = "Workato"
    Connection  = "Salesforce"
    Environment = "Production"
  }
}

resource "aws_secretsmanager_secret_rotation" "workato_salesforce" {
  secret_id           = aws_secretsmanager_secret.workato_salesforce.id
  rotation_lambda_arn = aws_lambda_function.secret_rotation.arn

  rotation_rules {
    automatically_after_days = 90
  }
}
# HTH Guide Excerpt: end terraform-secrets-manager
