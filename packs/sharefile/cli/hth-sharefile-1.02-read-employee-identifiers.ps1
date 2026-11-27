# HTH Pack Contract: v1
#   control: sharefile-1.2
#   guide: https://howtoharden.com/guides/sharefile/#12-inventory-employee-privileges
#   profile: L1
#   mode: read-only
#   requires: ShareFile PowerShell module and an approved protected sfps profile
# Source: https://github.com/sharefile-org/ShareFile-PowerShell-Module/blob/main/Samples/StorageReport.ps1
# HTH Guide Excerpt: begin read-employee-identifiers-sdk
param(
    [Parameter(Mandatory)]
    [string]$ProfilePath
)
$ErrorActionPreference = 'Stop'
$resolved = Get-Item -LiteralPath $ProfilePath
if ($resolved.PSIsContainer -or $resolved.Extension -ne '.sfps' -or $resolved.PSProvider.Name -ne 'FileSystem') {
    throw 'Specify an existing ShareFile .sfps profile on the local filesystem.'
}
$client = Get-SfClient -Name $resolved.FullName
if ($null -eq $client) {
    throw 'Could not load authorized ShareFile client context.'
}
$employees = @(Send-SfRequest $client -Method GET -Entity Accounts/Employees -Select 'Id')
if (@($employees | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.Id) }).Count -gt 0) {
    throw 'Unexpected employee inventory record.'
}
[pscustomobject]@{
    scope = 'Employee IDs returned by the module. Check coverage before attesting.'
    ids = @($employees | ForEach-Object { $_.Id })
} | ConvertTo-Json -Depth 2
# HTH Guide Excerpt: end read-employee-identifiers-sdk
