# HTH Pack Contract: v1
#   control: cursor-origin-3.4
#   guide: https://howtoharden.com/guides/cursor-origin/#34-constrain-namespace-inbound-ip-access
#   profile: L2
#   mode: mutating
#   requires: Terraform >=1.5; cursor/cursor =0.8.0; CURSOR_TOKEN; eligible team namespace; approved caller/recovery CIDRs; opt-in management and enforcement
#   changes: optional posture read; opt-in per-entry ownership and allowlist flag; no whole-set replacement
#   source: https://github.com/cursor/terraform-provider-cursor/blob/v0.8.0/docs/resources/origin_inbound_ip_allowlist.md
# HTH Guide Excerpt: begin origin-inbound-ip-allowlist
# Management and enforcement default OFF. Import/review existing ownership first.
# Never combine these per-entry resources with the whole-set resource
# cursor_origin_inbound_ip_allowlist_entries for this namespace: it removes
# entries not listed in its configuration. The API's caller-address checks do
# not protect every caller. Prove independent recovery access before enforcement.
data "cursor_origin_inbound_ip_allowlist_entries" "hth_observed" {
  count     = var.hth_read_ip_posture || var.hth_manage_ip_allowlist ? 1 : 0
  namespace = var.hth_origin_owner
}

resource "cursor_origin_inbound_ip_allowlist_entry" "hth_egress" {
  for_each = var.hth_manage_ip_allowlist ? var.hth_origin_egress_cidrs : {}

  namespace           = var.hth_origin_owner
  cidr                = each.key
  description         = each.value
  enabled             = true
  deletion_protection = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "cursor_origin_inbound_ip_allowlist" "hth_namespace" {
  count = var.hth_manage_ip_allowlist && var.hth_enforce_ip_allowlist ? 1 : 0

  namespace           = var.hth_origin_owner
  enabled             = true
  deletion_protection = true
  depends_on          = [cursor_origin_inbound_ip_allowlist_entry.hth_egress]

  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = length(var.hth_origin_egress_cidrs) > 0 && var.hth_recovery_access_tested
      error_message = "Do not enforce until required caller egress is admitted and an independent recovery path is proven."
    }
  }
}

output "hth_origin_ip_allowlist_observed" {
  sensitive = true
  value     = data.cursor_origin_inbound_ip_allowlist_entries.hth_observed
}
# The data-source read observes posture; it is not a simulated caller reachability
# test. Enforcement requires enabled=true AND at least one enabled entry. A
# protected flag's destruction would disable enforcement; guards intentionally
# block it. CIDR edits keep the entry ID but can still lock other callers out.
# No disabled-flag resource is created by default; selecting only entry management
# must not turn off a namespace's existing enforcement.
# Provider 0.8.0 neither exposes nor reads the API's trustAppDeclaredIps setting.
# This output cannot assess that exception. Review it through the current native
# API before enforcement; this example does not change an existing trust setting.
# Native reference: https://cursor.com/docs/api/origin#inbound-ip-allowlist
# HTH Guide Excerpt: end origin-inbound-ip-allowlist
