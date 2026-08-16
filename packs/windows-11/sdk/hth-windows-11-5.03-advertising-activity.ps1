# Control: 5.3 Disable Advertising, Tailored Experiences, and Activity Collection
# Profile Level: L1 (Crawl) | Track: Both
# Frameworks: NIST 800-53 SI-12/PL-4 | CIS Controls v8 3.3
# Guide: https://howtoharden.com/guides/windows-11/#53-disable-advertising-tailored-experiences-and-activity-collection
# Interface: registry (verified against the general-privacy + manage-connections docs)
#   https://learn.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services
# Run elevated for the HKLM keys; HKCU keys apply to the current user.

# HTH Guide Excerpt: begin ps-advertising-id
# Advertising ID off (per-machine policy + per-user value):
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name DisabledByGroupPolicy -Type DWord -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name Enabled -Type DWord -Value 0
# HTH Guide Excerpt: end ps-advertising-id

# HTH Guide Excerpt: begin ps-tailored-activity
# Tailored experiences (stop diagnostic data driving personalized tips/ads):
New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name DisableTailoredExperiencesWithDiagnosticData -Type DWord -Value 1
# Turn off Microsoft consumer experiences (Enterprise/Education-effective; harmless elsewhere):
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name DisableWindowsConsumerFeatures -Type DWord -Value 1

# Activity history is local-only since Jan 2024; stop it entirely (mirrors 5.2's System keys):
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name PublishUserActivities -Type DWord -Value 0 -ErrorAction SilentlyContinue

Write-Output "5.3 Applied. CONSUMER: also clear activity history and set Location services off in Settings > Privacy & security (desktop apps are exempt from per-app location control, so device-wide off is stronger)."
# HTH Guide Excerpt: end ps-tailored-activity
