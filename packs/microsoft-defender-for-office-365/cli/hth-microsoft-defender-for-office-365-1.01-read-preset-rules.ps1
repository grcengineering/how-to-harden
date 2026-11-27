# HTH Pack Contract: v1
#   control: microsoft-defender-for-office-365-1.1
#   guide: https://howtoharden.com/guides/microsoft-defender-for-office-365/#11-review-preset-rules-and-actual-mailbox-coverage
#   profile: L1
#   mode: read-only
#   requires: PowerShell, ExchangeOnlineManagement module, one active Exchange Online session with preset-rule read permissions
# Source (reviewed 2026-11-27): https://learn.microsoft.com/en-us/defender-office-365/preset-security-policies
# HTH Guide Excerpt: begin read-preset-rules
param([Parameter(Mandatory)][guid]$ExpectedTenantId)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Refuse ambiguous or prefixed sessions; do not sign in or switch tenant.
$connections = @(Get-ConnectionInformation)
if ($connections.Count -ne 1) {
    throw 'UNKNOWN: expected one connection in this PowerShell session.'
}
$connection = $connections[0]
if ($connection.TenantID -ne $ExpectedTenantId -or $connection.IsEopSession -or
    $connection.ModulePrefix -or $connection.TokenStatus -ne 'Active') {
    throw 'UNKNOWN: Exchange Online connection did not match the expected active tenant.'
}

$rules = @(
    Get-ATPProtectionPolicyRule -ErrorAction Stop |
        Where-Object { $_.Name -in @('Standard Preset Security Policy','Strict Preset Security Policy') } |
        Select-Object Name, State
)
foreach ($rule in $rules) {
    if ([string]$rule.State -notin @('Enabled','Disabled')) {
        throw 'UNKNOWN: unexpected preset rule state.'
    }
}
$result = [ordered]@{
    rules = @($rules | ForEach-Object { @{ name = $_.Name; state = [string]$_.State } })
    recipient_coverage_checked = $false
    protection_effectiveness_checked = $false
}
$result | ConvertTo-Json -Depth 4
# HTH Guide Excerpt: end read-preset-rules
