# =============================================================================
# HTH Pack Contract: v1
#   control: ona-5.1
#   guide:   https://howtoharden.com/guides/ona/#51-run-self-hosted-runners-for-sensitive-source-code
#   profile: L2
#   mode:    mutating
#   requires: ONA_TOKEN(read-write PAT)
#
# HTH Ona Control 5.1: Run Self-Hosted Runners for Sensitive Source Code
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 12.2 | NIST 800-53 SC-7, SA-9 | SOC 2 CC6.6
# Source: https://howtoharden.com/guides/ona/#51-run-self-hosted-runners-for-sensitive-source-code
#
# PROVIDER BLOCK LIVES IN hth-ona-1.01-configure-sso.tf.
#
# Transcribed from registry docs fetched 2026-08-19:
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/runner                (doc 13236804)
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/runner_token          (doc 13236807)
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/data-sources/runners          (doc 13236828)
#   https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/organization_policies (doc 13236800)
# all for provider-version 105656 = 0.4.0-beta.1.
#
# SINGLETON — merge these attributes into ONE ona_organization_policies resource
# if you adopt more than one pack; two resources managing the same object drift
# forever.
#
# CREDENTIAL-IN-STATE WARNING. ona_runner_token is an ORDINARY managed resource,
# not an ephemeral one. Verbatim from the provider's own state guide: the
# registration token "is valid for 24 hours and can only be used once", is marked
# sensitive, and Terraform "stores it in state so ordinary resources and module
# variables can consume it" — and "Sensitive fields are redacted from CLI output
# … but they are still stored in Terraform state. Redaction is not encryption."
# Applying the token resource below therefore writes a live credential into your
# state file. Use an encrypted, access-controlled remote backend, or leave
# var.mint_registration_token false and mint the token in the console instead.
#
# WHY TERRAFORM FOR THIS CONTROL: the runner record, its update window, its
# metrics egress, and the organization policy that forbids local runners are four
# objects that together decide whether sensitive source ever leaves your VPC.
#
# TRAPS
#  1. THE RUNNER RECORD IS NOT THE RUNNER. ona_runner creates the registration
#     record and, for aws_ec2, returns cloudformation_template_url. Deploying the
#     infrastructure is a separate step in YOUR cloud account with YOUR AWS/GCP
#     provider. A green apply here means "registered", not "running".
#  2. ONLY aws_ec2 AND gcp ARE SUPPORTED runner_provider values, and changing
#     runner_provider — or `region` on an aws_ec2 runner — REPLACES the runner.
#  3. ALLOWED LOCAL RUNNERS ARE THE BACK DOOR. Standing up a self-hosted runner
#     while local runners remain permitted lets a developer run agents on a
#     laptop, outside every network control you just built. allow_local_runners =
#     false below closes it. Note the schema's own remark: "The Ona API rejects
#     enabling local runners through organization policies" — you can turn this
#     off here, but you cannot turn it back on here.
#  4. LOCAL RUNNERS ARE DEPRECATED AT THE ENUM LEVEL, AND THERE IS A SECOND
#     LEVER. RUNNER_KIND_LOCAL_CONFIGURATION is a system-managed singleton whose
#     desiredPhase "can be set to STOPPED to disable all local runners" — an
#     API-side belt to this policy's braces. Not exposed in this provider.
#  5. NETWORK PREREQUISITES BYPASS PROXIES. The AWS runner needs direct TCP 443 to
#     Secrets Manager, CloudWatch Logs, ECR API, ECR Docker and S3, and those
#     bypass HTTP proxies — use PrivateLink/VPC endpoints. Allow Ona AMIs by owner
#     account ID 995913728426, not by AMI ID. None of this is expressible in this
#     schema; it belongs in your AWS Terraform.
#  6. CUSTOM METRICS EGRESS IS A DATA PATH. configuration.metrics.custom.url sends
#     runner metrics out of your VPC to whatever endpoint you name; its password
#     is a write-only argument rotated by password_version. If the point of self-
#     hosting is containment, review that URL like any other egress.
#  7. release_channel = "latest" TAKES UNREVIEWED BUILDS. "stable" plus a narrow
#     update_window is the reviewable posture.
#  8. ona_runner_token DESTROY REMOVES STATE ONLY — "Ona does not expose a durable
#     token object to revoke or delete". Removing the resource does not revoke an
#     already-minted token; it just stops tracking it. Rotation is
#     token_version, and Terraform will NOT mint a replacement when the 24 hours
#     expire.
# =============================================================================

variable "runner_name" {
  description = "Runner display name shown in Ona."
  type        = string
  default     = "hth-selfhosted-primary"
}

variable "runner_provider" {
  description = "Cloud provider for the runner. Supported values are aws_ec2 and gcp. Changing it REPLACES the runner."
  type        = string
  default     = "aws_ec2"

  validation {
    condition     = contains(["aws_ec2", "gcp"], var.runner_provider)
    error_message = "runner_provider must be one of: aws_ec2, gcp."
  }
}

variable "runner_region" {
  description = "Cloud region. Required for aws_ec2 runners. Changing it REPLACES the runner."
  type        = string
  default     = "us-east-1"
}

variable "allow_local_runners" {
  description = "Whether local runners are allowed. Keep false: a permitted local runner runs agents outside your VPC. The Ona API rejects re-enabling this through organization policies."
  type        = bool
  default     = false
}

variable "mint_registration_token" {
  description = "Mint a runner registration token through Terraform. WARNING: the token is written to Terraform STATE (unlike ephemeral resources). Leave false unless your state backend is encrypted and access-controlled."
  type        = bool
  default     = false
}

variable "runner_token_version" {
  description = "Rotation marker for the registration token. Changing it replaces the resource and mints a new token. Terraform does NOT rotate it automatically when the 24-hour lifetime expires."
  type        = string
  default     = "v1"
}

# HTH Guide Excerpt: begin terraform
resource "ona_runner" "selfhosted" {
  name = var.runner_name

  # aws_ec2 or gcp. Ona Cloud is the alternative this control exists to avoid for
  # sensitive source.
  runner_provider = var.runner_provider

  # `configuration` is a BLOCK, not an attribute.
  configuration {
    region = var.runner_region

    # "stable", not "latest": take reviewed builds only.
    release_channel = "stable"
    auto_update     = true

    devcontainer_image_cache_enabled = true
    log_level                        = "info"

    # Ona-managed metrics keep the telemetry path inside the vendor relationship
    # you already assessed. A custom remote-write URL here would be an additional
    # egress path out of your VPC — review it like any other.
    metrics {
      managed {
        enabled = true
      }
    }

    # Confine auto-updates to a maintenance window you actually watch. Times are
    # HH:00 UTC.
    update_window {
      start = "02:00"
      end   = "04:00"
    }
  }
}

# Closing the back door: a permitted local runner runs agents on a laptop, outside
# every network control the self-hosted runner just bought you.
# SINGLETON: at most one ona_organization_policies per organization (import id "current") —
# merge these attributes with any other ona pack you adopt; two resources drift forever.
resource "ona_organization_policies" "local_runners" {
  allow_local_runners = var.allow_local_runners
}

# Registration token. OPT-IN because applying it writes a live, single-use,
# 24-hour credential into Terraform STATE — this resource is NOT ephemeral.
resource "ona_runner_token" "bootstrap" {
  count = var.mint_registration_token ? 1 : 0

  runner_id     = ona_runner.selfhosted.runner_id
  token_version = var.runner_token_version
}
# HTH Guide Excerpt: end terraform

# HTH Guide Excerpt: begin verify
# Standing inventory of every runner the token can see. Read it to catch a runner
# someone stood up in the console outside this configuration.
data "ona_runners" "all" {}

output "ona_runner_inventory" {
  description = "Every runner visible to the token, with its provider and release channel. Investigate anything not declared here."
  value = [
    for r in data.ona_runners.all.runners : {
      name            = r.name
      runner_provider = r.runner_provider
      kind            = r.kind
      release_channel = r.configuration.release_channel
    }
  ]
}

output "ona_aws_cloudformation_template_url" {
  description = "CloudFormation template for deploying the AWS runner in YOUR account. Null for GCP runners. Registration is not deployment."
  value       = ona_runner.selfhosted.cloudformation_template_url
}
# HTH Guide Excerpt: end verify
