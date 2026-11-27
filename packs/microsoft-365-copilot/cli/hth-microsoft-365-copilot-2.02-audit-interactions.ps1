# HTH Pack Contract: v1
#   control: microsoft-365-copilot-2.2
#   guide: https://howtoharden.com/guides/microsoft-365-copilot/
#   profile: L2
#   mode: read-only
#   requires: PowerShell and authorized Exchange Online audit module
# HTH Microsoft 365 Copilot 2.2: Verify Copilot audit activity without exporting content.
# Profile: L1 (Crawl). NIST SP 800-53 Rev. 5 AU-2, AU-6, AU-9.
# Guide: https://howtoharden.com/guides/microsoft-365-copilot/
# HTH Guide Excerpt: begin audit-interactions
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$AuditUserPrincipalName,
    [Parameter(Mandatory)][string]$PilotUserPrincipalName,
    [ValidateRange(1, 24)][int]$Hours = 2
)

$ErrorActionPreference = 'Stop'
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName $AuditUserPrincipalName -ShowBanner:$false
try {
    $endUtc = [DateTime]::UtcNow
    $startUtc = $endUtc.AddHours(-$Hours)
    $query = @{
        StartDate = $startUtc
        EndDate = $endUtc
        RecordType = 'CopilotInteraction'
        UserIds = $PilotUserPrincipalName
        ResultSize = 100
    }
    $rows = @(Search-UnifiedAuditLog @query | Where-Object { $null -ne $_ })
    [pscustomobject]@{
        StartUtc = $startUtc.ToString('o')
        EndUtc = $endUtc.ToString('o')
        SampleCount = $rows.Count
        SampleLimit = 100
    } | ConvertTo-Json -Compress
} finally {
    Disconnect-ExchangeOnline -Confirm:$false
}
# HTH Guide Excerpt: end audit-interactions
