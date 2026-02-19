# =============================================================================
# HTH Microsoft 365 Control 5.1: Enable Unified Audit Logging
# Profile: L1 | NIST: AU-2, AU-3, AU-6
# Source: https://howtoharden.com/guides/microsoft-365/#51-enable-unified-audit-logging
# =============================================================================

# HTH Guide Excerpt: begin cli-enable-audit-logging

# Connect to Exchange Online
Connect-ExchangeOnline

# Verify audit logging is enabled
Get-AdminAuditLogConfig | Select-Object UnifiedAuditLogIngestionEnabled

# Enable if not already enabled
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true

# Enable mailbox auditing for all mailboxes
Get-Mailbox -ResultSize Unlimited | Set-Mailbox -AuditEnabled $true

# HTH Guide Excerpt: end cli-enable-audit-logging
