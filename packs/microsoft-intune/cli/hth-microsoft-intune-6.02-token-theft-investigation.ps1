#!/usr/bin/env pwsh
# HTH Microsoft Intune Control 6.2: Operationalize Token Theft Investigation
# Profile: L2 | NIST: IR-4
# https://howtoharden.com/guides/microsoft-intune/#62-operationalize-token-theft-investigation
#
# Prerequisites:
#   Install-Module Microsoft.Graph.Identity.SignIns -Scope CurrentUser
#   Connect-MgGraph -Scopes "IdentityRiskyUser.ReadWrite.All","AuditLog.Read.All"

# HTH Guide Excerpt: begin powershell
# --- Query risky sign-ins for Intune admin accounts ---
Write-Host "=== Checking Risky Sign-Ins for Admin Accounts ===" -ForegroundColor Cyan

$intuneAdmins = Get-MgDirectoryRoleMember -DirectoryRoleId (
    Get-MgDirectoryRole -Filter "displayName eq 'Intune Administrator'" |
    Select-Object -ExpandProperty Id
)

foreach ($admin in $intuneAdmins) {
    $userId = $admin.Id
    $displayName = $admin.AdditionalProperties.displayName

    $riskySignIns = Get-MgRiskyUser -Filter "id eq '$userId'" -ErrorAction SilentlyContinue
    if ($riskySignIns -and $riskySignIns.RiskLevel -ne "none") {
        Write-Warning "RISKY USER: $displayName | Risk Level: $($riskySignIns.RiskLevel) | State: $($riskySignIns.RiskState)"
        Write-Host "  Action: Investigate in Microsoft Defender XDR > Identity > Risky users" -ForegroundColor Red
    } else {
        Write-Host "OK: $displayName - No risk detected" -ForegroundColor Green
    }
}

# --- Token theft response procedure ---
Write-Host "`n=== Token Theft Response Procedure ===" -ForegroundColor Yellow
Write-Host "If a compromised admin session is detected:" -ForegroundColor White
Write-Host "  1. Revoke all sessions: Revoke-MgUserSignInSession -UserId <userId>" -ForegroundColor White
Write-Host "  2. Disable account: Update-MgUser -UserId <userId> -AccountEnabled:`$false" -ForegroundColor White
Write-Host "  3. Review Intune audit logs for unauthorized actions during session" -ForegroundColor White
Write-Host "  4. Reverse unauthorized device actions if possible" -ForegroundColor White
Write-Host "  5. Reset credentials and re-provision FIDO2 keys" -ForegroundColor White
Write-Host "  6. Re-enable account after investigation completes" -ForegroundColor White
# HTH Guide Excerpt: end powershell
