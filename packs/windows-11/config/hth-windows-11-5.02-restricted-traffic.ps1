# Control: 5.2 Apply the Restricted-Traffic / Connected-Experiences Baseline
# Profile Level: L2 (Walk) | Track: Both (policies Enterprise-scoped; many reg keys honored on Pro)
# Frameworks: NIST 800-53 SC-7/SI-12 | CIS Controls v8 4.8/3.3
# Guide: https://howtoharden.com/guides/windows-11/#52-apply-the-restricted-traffic-connected-experiences-baseline
# Interface: policy registry (verified against the manage-connections restricted-traffic doc)
#   https://learn.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services
# Run elevated. DO NOT disable Windows Update, Root Certificate updates, or Defender
# (Microsoft states this REDUCES security). CRL/OCSP revocation traffic cannot be disabled.

# HTH Guide Excerpt: begin ps-restrict-connected-experiences
# Web-connected search / Cortana:
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name AllowCortana         -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name DisableWebSearch      -Type DWord -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name ConnectedSearchUseWeb -Type DWord -Value 0

# Find My Device:
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice" -Name AllowFindMyDevice -Type DWord -Value 0

# OneDrive file sync + pre-sign-in traffic:
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name DisableFileSyncNGSC -Type DWord -Value 1

# Settings sync to the cloud:
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name DisableSettingSync            -Type DWord -Value 2
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name DisableSettingSyncUserOverride -Type DWord -Value 1

# Activity feed:
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name EnableActivityFeed     -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name PublishUserActivities  -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name UploadUserActivities   -Type DWord -Value 0
# HTH Guide Excerpt: end ps-restrict-connected-experiences

# HTH Guide Excerpt: begin ps-smartscreen-keep-on
# SMARTSCREEN IS A SECURITY CONTROL. The restricted-traffic doc CAN disable it, but
# doing so removes anti-phishing/anti-malware URL+app reputation. This guide keeps it
# ON. Only disable it under an explicit threat-model decision - do NOT run this to
# turn it off. Confirm it is enabled:
$ss = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name EnableSmartScreen -ErrorAction SilentlyContinue
if ($ss.EnableSmartScreen -eq 0) { Write-Warning "5.2 SmartScreen is DISABLED by policy - re-enable unless deliberately overridden." }
# HTH Guide Excerpt: end ps-smartscreen-keep-on
