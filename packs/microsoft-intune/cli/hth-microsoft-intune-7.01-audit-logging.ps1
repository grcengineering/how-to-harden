#!/usr/bin/env pwsh
# HTH Microsoft Intune Control 7.1: Enable Comprehensive Intune Audit Logging
# Profile: L1 | NIST: AU-2, AU-3
# https://howtoharden.com/guides/microsoft-intune/#71-enable-comprehensive-intune-audit-logging
#
# Prerequisites:
#   Install-Module Az.Monitor -Scope CurrentUser
#   Connect-AzAccount

# HTH Guide Excerpt: begin powershell
# --- Configure Intune diagnostic settings to export logs to Log Analytics ---
Write-Host "=== Configuring Intune Diagnostic Log Export ===" -ForegroundColor Cyan

$workspaceName      = "hth-intune-logs"
$resourceGroupName  = "rg-security-monitoring"
$subscriptionId     = (Get-AzContext).Subscription.Id

# Get or create Log Analytics workspace
$workspace = Get-AzOperationalInsightsWorkspace `
    -ResourceGroupName $resourceGroupName `
    -Name $workspaceName `
    -ErrorAction SilentlyContinue

if (-not $workspace) {
    Write-Host "Creating Log Analytics workspace: $workspaceName" -ForegroundColor Yellow
    $workspace = New-AzOperationalInsightsWorkspace `
        -ResourceGroupName $resourceGroupName `
        -Name $workspaceName `
        -Location "eastus" `
        -Sku "PerGB2018" `
        -RetentionInDays 365
}

$workspaceId = $workspace.ResourceId

# Configure diagnostic settings for Intune
# Note: Intune diagnostic settings are configured via the Intune admin center
# or via the Azure Monitor REST API targeting the Microsoft Intune resource provider
Write-Host "`n=== Intune Diagnostic Settings Configuration ===" -ForegroundColor Cyan
Write-Host "Navigate to: Intune admin center > Tenant administration > Diagnostics settings" -ForegroundColor Yellow
Write-Host "Create diagnostic setting: HTH-IntuneAuditExport" -ForegroundColor Yellow
Write-Host "Select categories:" -ForegroundColor White
Write-Host "  - AuditLogs (all administrative actions)" -ForegroundColor Green
Write-Host "  - OperationalLogs (device actions, compliance changes)" -ForegroundColor Green
Write-Host "  - DeviceComplianceOrg (compliance state changes)" -ForegroundColor Green
Write-Host "Destination: Log Analytics workspace '$workspaceName'" -ForegroundColor White
Write-Host "Workspace Resource ID: $workspaceId" -ForegroundColor White

# --- Verify log flow with a test query ---
Write-Host "`n=== Verification Query ===" -ForegroundColor Cyan
Write-Host "Run in Log Analytics to verify log flow:" -ForegroundColor Yellow
Write-Host 'IntuneAuditLogs | take 10 | project TimeGenerated, OperationName, InitiatedByUserPrincipalName' -ForegroundColor White
# HTH Guide Excerpt: end powershell
