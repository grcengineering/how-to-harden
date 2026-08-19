# =============================================================================
# HTH Pack Contract: v1
#   control: ona-3.2
#   guide:   https://howtoharden.com/guides/ona/#32-control-the-in-environment-web-browser
#   profile: L2
#   mode:    mutating
#   requires: ONA_TOKEN(read-write PAT)
#
# HTH Ona Control 3.2: Control the In-Environment Web Browser
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 9.2 | NIST 800-53 SC-7, AC-4
# Source: https://howtoharden.com/guides/ona/#32-control-the-in-environment-web-browser
#
# PROVIDER BLOCK LIVES IN hth-ona-1.01-configure-sso.tf.
#
# Transcribed from https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/organization_policies
# (registry v2 provider-doc 13236800, provider-version 105656 = 0.4.0-beta.1).
#
# SINGLETON — merge these attributes into ONE ona_organization_policies resource
# if you adopt more than one pack; two resources managing the same object drift
# forever.
#
# WHY TERRAFORM FOR THIS CONTROL: one organization-wide boolean with no allow
# list and no per-project override. Nothing to tune means nothing to notice when
# it changes — which is exactly the case for declaring it.
#
# TRAPS
#  1. THIS IS A UI AFFORDANCE, NOT AN EGRESS CONTROL. web_browser_disabled removes
#     the built-in browser users can open from environment pages. It does not stop
#     curl, wget, or any process in the environment reaching the internet. If the
#     requirement is data-egress control, this is a partial measure — pair it with
#     network controls on a self-hosted runner (pack 5.01).
#  2. OMITTING THE ATTRIBUTE LEAVES IT UNMANAGED. Verbatim: "Omit to leave the
#     remote setting unmanaged." Declare it explicitly or a console flip never
#     appears as drift.
#  3. PROTO3 OMITS DEFAULTS. Absent web_browser_disabled on the API read path
#     means FALSE — the browser is ENABLED. Never read a missing key as compliant.
#  4. DESTROY IS NOT DELETE. Destroying ona_organization_policies restores the
#     server-defined policy configuration captured before Terraform took over,
#     which can re-enable the browser.
# =============================================================================

variable "web_browser_disabled" {
  description = "Disable the built-in web browser on environment pages. Does not restrict network egress from inside the environment."
  type        = bool
  default     = true
}

# HTH Guide Excerpt: begin terraform
# SINGLETON: at most one ona_organization_policies per organization (import id "current") —
# merge these attributes with any other ona pack you adopt; two resources drift forever.
resource "ona_organization_policies" "web_browser" {
  web_browser_disabled = var.web_browser_disabled
}
# HTH Guide Excerpt: end terraform

output "ona_web_browser_disabled" {
  description = "Effective posture. false means users can open the in-environment browser."
  value       = ona_organization_policies.web_browser.web_browser_disabled
}
