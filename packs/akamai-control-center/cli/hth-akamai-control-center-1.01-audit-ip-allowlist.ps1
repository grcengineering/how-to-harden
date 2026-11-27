# HTH Pack Contract: v1
#   control: akamai-control-center-1.1
#   guide: https://howtoharden.com/guides/akamai-control-center/
#   profile: L2
#   mode: read-only
#   requires: PowerShell 5.1, Akamai.IAM 3.0.0+, approved EdgeGrid credentials
# HTH Guide Excerpt: begin audit-ip-allowlist
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$EdgeRCFile,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Section,
    [ValidateNotNullOrEmpty()][string]$AccountSwitchKey
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $EdgeRCFile -PathType Leaf)) {
    throw 'Select a locally protected EdgeGrid resource file.'
}
Import-Module Akamai.IAM -MinimumVersion 3.0.0
$query = @{
    EdgeRCFile = $EdgeRCFile
    Section = $Section
    ErrorAction = 'Stop'
    Debug = $false
    Verbose = $false
}
if ($PSBoundParameters.ContainsKey('AccountSwitchKey')) {
    $query.AccountSwitchKey = $AccountSwitchKey
}
try {
    $status = Akamai.IAM\Get-IAMIPAllowListStatus @query
} catch {
    throw 'Akamai IAM status read failed. Check the account, credential permissions, and connectivity.'
}
if ($null -eq $status) {
    throw 'Akamai IAM returned no allowlist status. Do not infer it is disabled.'
}
ConvertTo-Json -InputObject $status -Depth 4 -Compress
# HTH Guide Excerpt: end audit-ip-allowlist
