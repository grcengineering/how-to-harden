# Control: 1.2 Protect Sign-in Credentials (Hello, Credential Guard, LSA Protection)
# Profile Level: L1 (Crawl) | Track: Both (Credential Guard = Enterprise/Education only)
# Frameworks: NIST 800-53 IA-2/IA-5/SC-39 | CIS Controls v8 5.2/6.3
# Guide: https://howtoharden.com/guides/windows-11/#12-protect-sign-in-credentials-windows-hello-credential-guard-lsa-protection
# Interface: PowerShell + registry (verified against learn.microsoft.com Credential Guard / LSA protection docs)
# Run elevated.

# HTH Guide Excerpt: begin ps-verify-credential-guard
# ENTERPRISE/EDUCATION: Credential Guard is default-on for qualifying domain-joined
# devices since 22H2. Verify it is running via the Win32_DeviceGuard WMI class.
$dg = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard
Write-Output "VBS status: $($dg.VirtualizationBasedSecurityStatus) (2 = enabled and running)"
if ($dg.SecurityServicesRunning -contains 1) {
  Write-Output "1.2 PASS: Credential Guard is running."
} else {
  Write-Warning "1.2 Credential Guard NOT running (Enterprise/Education only; requires VBS + Secure Boot)."
}
# HTH Guide Excerpt: end ps-verify-credential-guard

# HTH Guide Excerpt: begin ps-lsa-protection
# BOTH: confirm/enable LSA protection (RunAsPPL). Default-on for new 22H2+ installs.
#   Value 1 = protected with a UEFI variable; 2 = without a UEFI variable (22H2+).
$lsa = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name RunAsPPL -ErrorAction SilentlyContinue
if ($lsa.RunAsPPL -in 1,2) {
  Write-Output "1.2 PASS: LSA protection enabled (RunAsPPL=$($lsa.RunAsPPL))."
} else {
  Write-Warning "1.2 LSA protection not set. To enable (UEFI-lock variant):"
  Write-Output '  Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name RunAsPPL -Type DWord -Value 1'
}
# HTH Guide Excerpt: end ps-lsa-protection
