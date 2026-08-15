# Control: 2.2 Enable Memory Integrity (VBS/HVCI)
# Profile Level: L1 (Crawl) | Track: Both
# Frameworks: NIST 800-53 SI-7/SC-39 | CIS Controls v8 4.1/10.5
# Guide: https://howtoharden.com/guides/windows-11/#22-enable-memory-integrity-vbshvci
# Interface: registry + Win32_DeviceGuard WMI (verified against the enable-VBS/HVCI doc)
#   https://learn.microsoft.com/en-us/windows/security/hardware-security/enable-virtualization-based-protection-of-code-integrity
# Run elevated. A reboot is required after enabling. Update incompatible drivers first.

# HTH Guide Excerpt: begin ps-enable-hvci
# ENTERPRISE registry set (equivalent to GPO "Turn on Virtualization Based Security"
# with "Enabled without UEFI lock" for Code Integrity):
$dgRoot = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
$hvci   = "$dgRoot\Scenarios\HypervisorEnforcedCodeIntegrity"
New-Item -Path $hvci -Force | Out-Null
Set-ItemProperty -Path $dgRoot -Name EnableVirtualizationBasedSecurity -Type DWord -Value 1
Set-ItemProperty -Path $dgRoot -Name RequirePlatformSecurityFeatures    -Type DWord -Value 1  # 1 = Secure Boot
Set-ItemProperty -Path $hvci   -Name Enabled -Type DWord -Value 1
Set-ItemProperty -Path $hvci   -Name Locked  -Type DWord -Value 0  # 0 = no UEFI lock
Write-Output "2.2 HVCI registry set. Reboot to apply."
# CONSUMER: Windows Security > Device security > Core isolation details > Memory integrity > On.
# HTH Guide Excerpt: end ps-enable-hvci

# HTH Guide Excerpt: begin ps-verify-hvci
$dg = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard
$vbs = $dg.VirtualizationBasedSecurityStatus   # 0 not enabled, 1 enabled-not-running, 2 running
if ($vbs -eq 2 -and ($dg.SecurityServicesRunning -contains 2)) {
  Write-Output "2.2 PASS: VBS running and memory integrity (HVCI) active."
} else {
  Write-Warning "2.2 Memory integrity not fully running (VBS status=$vbs). Reboot may be pending, or a driver is incompatible."
}
# HTH Guide Excerpt: end ps-verify-hvci
