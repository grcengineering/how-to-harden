# Control: 3.1 Harden Microsoft Defender Antivirus
# Profile Level: L1 (Crawl) | Track: Both
# Frameworks: NIST 800-53 SI-3/SI-4 | CIS Controls v8 10.1/10.6
# Guide: https://howtoharden.com/guides/windows-11/#31-harden-microsoft-defender-antivirus
# Interface: Defender PowerShell (Set-MpPreference / Get-MpComputerStatus)
#   https://learn.microsoft.com/en-us/defender-endpoint/enable-cloud-protection-microsoft-defender-antivirus
# Run elevated.

# HTH Guide Excerpt: begin ps-defender-cloud-pua
# Cloud-delivered protection (MAPS) + safe-sample submission + PUA blocking.
# SubmitSamplesConsent: SendSafeSamples is the recommended default; NeverSend
# lowers protection and disables Block-at-First-Sight.
Set-MpPreference -MAPSReporting Advanced -SubmitSamplesConsent SendSafeSamples
Set-MpPreference -PUAProtection Enabled   # Enabled(1) = block; AuditMode(2) to observe first
# HTH Guide Excerpt: end ps-defender-cloud-pua

# HTH Guide Excerpt: begin ps-defender-verify
# Tamper protection is turned ON via Windows Security > Virus & threat protection >
# Manage settings > Tamper Protection (on unmanaged devices), or via Intune/MDE on
# managed fleets. Verify the overall posture:
$s = Get-MpComputerStatus
"IsTamperProtected      : $($s.IsTamperProtected)"
"RealTimeProtection     : $($s.RealTimeProtectionEnabled)"
"AntivirusEnabled       : $($s.AntivirusEnabled)"
$p = Get-MpPreference
"MAPSReporting          : $($p.MAPSReporting)"       # 2 = Advanced
"SubmitSamplesConsent   : $($p.SubmitSamplesConsent)" # 1 = SendSafeSamples
"PUAProtection          : $($p.PUAProtection)"        # 1 = Enabled (block)
if (-not $s.IsTamperProtected) { Write-Warning "3.1 Tamper protection is OFF - enable it in Windows Security." }
# HTH Guide Excerpt: end ps-defender-verify
