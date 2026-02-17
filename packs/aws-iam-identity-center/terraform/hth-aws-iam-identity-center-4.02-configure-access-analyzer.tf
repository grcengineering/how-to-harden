# =============================================================================
# HTH AWS IAM Identity Center Control 4.2: Configure Access Analyzer
# Profile Level: L2 (Hardened)
# Frameworks: NIST AC-6, SOC 2 CC6.1, ISO 27001 A.9.2.5
# Source: https://howtoharden.com/guides/aws-iam-identity-center/#42-configure-access-analyzer
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Organization-level IAM Access Analyzer for cross-account visibility
resource "aws_accessanalyzer_analyzer" "organization" {
  analyzer_name = "hth-org-access-analyzer"
  type          = var.analyzer_type

  tags = {
    ManagedBy = "how-to-harden"
    Control   = "4.2-configure-access-analyzer"
  }
}

# Archive rule to auto-suppress known trusted cross-account access
resource "aws_accessanalyzer_archive_rule" "trusted_org_accounts" {
  analyzer_name = aws_accessanalyzer_analyzer.organization.analyzer_name
  rule_name     = "trusted-organization-accounts"

  filter {
    criteria = "isPublic"
    eq       = ["false"]
  }

  filter {
    criteria = "resourceType"
    eq       = ["AWS::IAM::Role"]
  }
}

# CloudWatch alarm for new Access Analyzer findings
resource "aws_cloudwatch_metric_alarm" "access_analyzer_findings" {
  alarm_name          = "hth-access-analyzer-new-findings"
  alarm_description   = "Alert on new IAM Access Analyzer findings (AC-6)"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ActiveFindings"
  namespace           = "AccessAnalyzer"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    AnalyzerName = aws_accessanalyzer_analyzer.organization.analyzer_name
  }

  alarm_actions = var.alarm_sns_topic_arns

  tags = {
    ManagedBy = "how-to-harden"
    Control   = "4.2-configure-access-analyzer"
  }
}
# HTH Guide Excerpt: end terraform

variable "analyzer_type" {
  description = "Access Analyzer type: ORGANIZATION (recommended) or ACCOUNT"
  type        = string
  default     = "ORGANIZATION"

  validation {
    condition     = contains(["ORGANIZATION", "ACCOUNT"], var.analyzer_type)
    error_message = "analyzer_type must be ORGANIZATION or ACCOUNT"
  }
}

variable "alarm_sns_topic_arns" {
  description = "SNS topic ARNs for Access Analyzer finding alerts"
  type        = list(string)
  default     = []
}
