# Control: 6.3 Control Delivery Optimization and Update Currency
# Profile Level: L2 (Walk) | Track: Both (DO peer settings broad; update deferral Pro+)
# Frameworks: NIST 800-53 SI-2/SC-7 | CIS Controls v8 7.3/7.4
# Guide: https://howtoharden.com/guides/windows-11/#63-control-delivery-optimization-and-update-currency
# Interface: registry (policy) + DeliveryOptimization PowerShell
#   https://learn.microsoft.com/en-us/windows/deployment/do/waas-delivery-optimization-reference
#   https://learn.microsoft.com/en-us/windows/deployment/update/waas-configure-wufb
# Run elevated. NEVER disable Windows Update (Microsoft states this reduces security).

# HTH Guide Excerpt: begin ps-delivery-optimization
# Disable peer-to-peer update sharing (DODownloadMode 0 = HTTP only). Use 1 (LAN) with
# subnet peer restriction if you want LAN peering without internet peers.
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" `
  -Name DODownloadMode -Type DWord -Value 0
Get-DeliveryOptimizationStatus | Select-Object -First 1 DownloadMode
# HTH Guide Excerpt: end ps-delivery-optimization

# HTH Guide Excerpt: begin ps-update-deferral
# ENTERPRISE (Pro+): stage updates for testing WITHOUT ever turning updates off.
# Defer feature updates up to 365 days, quality updates up to 30 days.
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name DeferFeatureUpdates            -Type DWord -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name DeferFeatureUpdatesPeriodInDays -Type DWord -Value 30
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name DeferQualityUpdates            -Type DWord -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name DeferQualityUpdatesPeriodInDays -Type DWord -Value 7
# CONSUMER (Home): keep automatic updates on; use Settings > Windows Update > Pause
# only briefly (35-day maximum). Confirm the build is current and supported.
# HTH Guide Excerpt: end ps-update-deferral
