# =============================================================================
# HTH Microsoft 365 Control 3.2: Review and Revoke Overprivileged App Permissions
# Profile: L2 | NIST: AC-6
# Source: https://howtoharden.com/guides/microsoft-365/#32-review-and-revoke-overprivileged-app-permissions
# =============================================================================

# HTH Guide Excerpt: begin cli-audit-app-permissions

# List all applications with Mail.ReadWrite permission
$apps = Get-MgApplication -All

foreach ($app in $apps) {
    $permissions = Get-MgApplication -ApplicationId $app.Id -Property RequiredResourceAccess
    $mailPermissions = $permissions.RequiredResourceAccess.ResourceAccess |
        Where-Object { $_.Id -eq "e2a3a72e-5f79-4c64-b1b1-878b674786c9" } # Mail.ReadWrite GUID

    if ($mailPermissions) {
        Write-Host "App: $($app.DisplayName) has Mail.ReadWrite permission"
    }
}

# HTH Guide Excerpt: end cli-audit-app-permissions
