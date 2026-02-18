# =============================================================================
# Zscaler Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 2.1: URL Filtering
# -----------------------------------------------------------------------------

output "url_block_rule_id" {
  description = "ID of the high-risk URL category block rule"
  value       = zia_url_filtering_rules.block_high_risk.id
}

output "url_caution_rule_id" {
  description = "ID of the medium-risk URL category caution rule"
  value       = zia_url_filtering_rules.caution_medium_risk.id
}


# -----------------------------------------------------------------------------
# Section 2.3: Firewall Policies (L2+)
# -----------------------------------------------------------------------------

output "firewall_block_risky_protocols_id" {
  description = "ID of the risky protocol block rule (L2+ only)"
  value       = var.profile_level >= 2 ? zia_firewall_filtering_rule.block_risky_protocols[0].id : null
}

output "firewall_default_deny_id" {
  description = "ID of the firewall default deny rule (L2+ only)"
  value       = var.profile_level >= 2 ? zia_firewall_filtering_rule.default_deny[0].id : null
}


# -----------------------------------------------------------------------------
# Section 3.1: Application Segments
# -----------------------------------------------------------------------------

output "segment_group_id" {
  description = "ID of the hardened ZPA segment group"
  value       = zpa_segment_group.hardened.id
}

output "server_group_id" {
  description = "ID of the hardened ZPA server group"
  value       = zpa_server_group.hardened.id
}

output "application_segment_ids" {
  description = "Map of application segment names to their IDs"
  value       = { for k, v in zpa_application_segment.apps : k => v.id }
}


# -----------------------------------------------------------------------------
# Section 3.2: Access Policies
# -----------------------------------------------------------------------------

output "access_policy_hardened_id" {
  description = "ID of the hardened access policy rule"
  value       = length(var.scim_group_ids) > 0 ? zpa_policy_access_rule.hardened_access[0].id : null
}

output "access_policy_default_deny_id" {
  description = "ID of the ZPA default deny access policy rule"
  value       = zpa_policy_access_rule.default_deny.id
}


# -----------------------------------------------------------------------------
# Section 3.3: Device Posture (L2+)
# -----------------------------------------------------------------------------

output "posture_disk_encryption_id" {
  description = "ID of the disk encryption posture profile (L2+ only)"
  value       = var.profile_level >= 2 ? zpa_posture_profile.disk_encryption[0].id : null
}

output "posture_firewall_id" {
  description = "ID of the firewall posture profile (L2+ only)"
  value       = var.profile_level >= 2 ? zpa_posture_profile.firewall_enabled[0].id : null
}

output "posture_os_version_id" {
  description = "ID of the OS version posture profile (L2+ only)"
  value       = var.profile_level >= 2 ? zpa_posture_profile.os_version[0].id : null
}


# -----------------------------------------------------------------------------
# Section 5.1: SSL Inspection
# -----------------------------------------------------------------------------

output "ssl_inspect_all_id" {
  description = "ID of the SSL inspection rule for all traffic"
  value       = zia_ssl_inspection_rules.inspect_all.id
}

output "ssl_do_not_inspect_id" {
  description = "ID of the SSL inspection exception rule"
  value       = zia_ssl_inspection_rules.do_not_inspect.id
}


# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

output "profile_level_applied" {
  description = "The hardening profile level that was applied"
  value       = var.profile_level
}

output "hardening_summary" {
  description = "Summary of hardening controls applied at the selected profile level"
  value = {
    profile_level           = var.profile_level
    l1_controls_applied     = true
    l2_controls_applied     = var.profile_level >= 2
    l3_controls_applied     = var.profile_level >= 3
    url_filtering           = "configured"
    advanced_threat_protect = "configured"
    firewall_policies       = var.profile_level >= 2 ? "configured" : "skipped"
    application_segments    = length(var.application_segments)
    access_policies         = length(var.scim_group_ids) > 0 ? "configured" : "skipped"
    device_posture          = var.profile_level >= 2 ? "configured" : "skipped"
    ssl_inspection          = "configured"
    client_connector        = "portal-managed"
    logging                 = "portal-managed"
  }
}
