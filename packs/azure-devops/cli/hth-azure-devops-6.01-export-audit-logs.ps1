# =============================================================================
# HTH Azure DevOps Control 6.1: Export Audit Logs
# Profile: L1 | NIST: AU-2, AU-3
# =============================================================================

# HTH Guide Excerpt: begin cli-export-audit-logs
$org = "your-org"
$continuationToken = ""

do {
    $response = Invoke-RestMethod `
        -Uri "https://auditservice.dev.azure.com/$org/_apis/audit/auditlog?api-version=7.1&continuationToken=$continuationToken" `
        -Headers $headers

    $response.decoratedAuditLogEntries | ForEach-Object {
        # Send to SIEM
        Send-ToSiem $_
    }

    $continuationToken = $response.continuationToken
} while ($continuationToken)
# HTH Guide Excerpt: end cli-export-audit-logs
