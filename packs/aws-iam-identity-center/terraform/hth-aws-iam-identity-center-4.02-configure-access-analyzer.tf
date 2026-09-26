# =============================================================================
# HTH Pack Contract: v1
#   control: aws-iam-identity-center-4.2
#   guide:   https://howtoharden.com/guides/aws-iam-identity-center/#42-configure-access-analyzer
#   profile: L2
#   mode:    mutating
#   requires: AWS credentials in the management or delegated-administrator account for an ORGANIZATION analyzer (access-analyzer:CreateAnalyzer, access-analyzer:CreateArchiveRule, events:PutRule, events:PutTargets)
#
# HTH AWS IAM Identity Center Control 4.2: Configure Access Analyzer
# Profile Level: L2 (Walk)
# Frameworks: NIST AC-6, SOC 2 CC6.1, ISO 27001 A.9.2.5
# Source: https://howtoharden.com/guides/aws-iam-identity-center/#42-configure-access-analyzer
#
# ALERTING GOES THROUGH EVENTBRIDGE. IAM Access Analyzer publishes no CloudWatch
# metric (there is no "AccessAnalyzer" namespace in the published-metrics list);
# AWS documents EventBridge events with detail-type "Access Analyzer Finding" as
# the monitoring path. A metric alarm on a namespace nobody publishes, with
# treat_missing_data = "notBreaching", never fires.
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

# Archive only findings for IAM roles trusted by accounts you have named as
# trusted. Without the principal.AWS filter this rule would archive EVERY
# non-public role finding -- including roles trusted by unknown external
# accounts, which is exactly what this control exists to surface.
resource "aws_accessanalyzer_archive_rule" "trusted_external_accounts" {
  count = length(var.trusted_external_account_ids) > 0 ? 1 : 0

  analyzer_name = aws_accessanalyzer_analyzer.organization.analyzer_name
  rule_name     = "trusted-external-accounts"

  filter {
    criteria = "isPublic"
    eq       = ["false"]
  }

  filter {
    criteria = "resourceType"
    eq       = ["AWS::IAM::Role"]
  }

  filter {
    criteria = "principal.AWS"
    eq       = var.trusted_external_account_ids
  }
}

# Route new ACTIVE external-access findings to SNS through EventBridge
resource "aws_cloudwatch_event_rule" "access_analyzer_findings" {
  name        = "hth-access-analyzer-findings"
  description = "New IAM Access Analyzer external-access findings (AC-6)"

  event_pattern = jsonencode({
    source        = ["aws.access-analyzer"]
    "detail-type" = ["Access Analyzer Finding"]
    detail = {
      status = ["ACTIVE"]
    }
  })

  tags = {
    ManagedBy = "how-to-harden"
    Control   = "4.2-configure-access-analyzer"
  }
}

resource "aws_cloudwatch_event_target" "access_analyzer_findings_sns" {
  count = length(var.alarm_sns_topic_arns)

  rule      = aws_cloudwatch_event_rule.access_analyzer_findings.name
  target_id = "hth-access-analyzer-sns-${count.index}"
  arn       = var.alarm_sns_topic_arns[count.index]
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

variable "trusted_external_account_ids" {
  description = "12-digit AWS account IDs whose role-trust findings may be auto-archived. Empty = archive nothing."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.trusted_external_account_ids : can(regex("^[0-9]{12}$", id))])
    error_message = "trusted_external_account_ids must be 12-digit AWS account IDs"
  }
}

variable "alarm_sns_topic_arns" {
  description = "SNS topic ARNs for Access Analyzer finding alerts. Each topic policy must allow events.amazonaws.com to sns:Publish."
  type        = list(string)
  default     = []
}
