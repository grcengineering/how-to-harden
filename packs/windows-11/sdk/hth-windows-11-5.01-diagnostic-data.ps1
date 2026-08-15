# Control: 5.1 Set Diagnostic Data to the Lowest Your Edition Allows
# Profile Level: L1 (Crawl) | Track: Both (hard edition floor)
# Frameworks: NIST 800-53 SI-12/PL-4 | CIS Controls v8 3.1/3.3
# Guide: https://howtoharden.com/guides/windows-11/#51-set-diagnostic-data-to-the-lowest-your-edition-allows
# Interface: registry (AllowTelemetry) + Diagnostic Data Viewer PowerShell module
#   https://learn.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization
# Run elevated.
# EDITION FLOOR: value 0 ("Diagnostic data off"/Security) is honored ONLY on
# Enterprise/Education/Server. On Pro and Home, 0 is silently treated as 1 (Required).

# HTH Guide Excerpt: begin ps-telemetry-off
# ENTERPRISE/EDUCATION: set diagnostic data to OFF (0). On Pro/Home this same value
# is coerced to Required (1) - it will NOT achieve zero.
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
  -Name AllowTelemetry -Type DWord -Value 0
# The Security/off level set by policy is NOT reflected in the Settings UI - verify
# via this registry value, not the toggle.
$edition = (Get-CimInstance Win32_OperatingSystem).Caption
if ($edition -notmatch 'Enterprise|Education') {
  Write-Warning "5.1 $edition cannot honor AllowTelemetry=0 - the floor here is Required (1). Minimize via consumer toggles + restricted traffic (5.2/5.3)."
}
# HTH Guide Excerpt: end ps-telemetry-off

# HTH Guide Excerpt: begin ps-diag-data-viewer
# BOTH: inspect exactly what the device is sending with the Diagnostic Data Viewer.
Install-Module -Name Microsoft.DiagnosticDataViewer -Scope CurrentUser -Force
Enable-DiagnosticDataViewing
Get-DiagnosticData -StartTime (Get-Date).AddHours(-12) -EndTime (Get-Date)
# CONSUMER: turn off optional diagnostics + inking/typing in
#   Settings > Privacy & security > Diagnostics & feedback (Required remains the floor).
# HTH Guide Excerpt: end ps-diag-data-viewer
