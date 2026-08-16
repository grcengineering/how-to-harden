# Control: 7.1 Establish Endpoint Audit Logging and Detection
# Profile Level: L2 (Walk) | Track: Both (SIEM forwarding = enterprise)
# Frameworks: NIST 800-53 AU-2/AU-6/SI-4 | CIS Controls v8 8.2/8.5/8.9
# Guide: https://howtoharden.com/guides/windows-11/#71-establish-endpoint-audit-logging-and-detection
# Interface: auditpol + registry (verified against the 25H2 baseline command-line-in-4688 change)
# Run elevated.

# HTH Guide Excerpt: begin ps-process-audit
# Enable process-creation auditing and INCLUDE THE COMMAND LINE in Event ID 4688
# (the single highest-value telemetry for detecting living-off-the-land attacks; the
# 25H2 security baseline enables this).
auditpol /set /subcategory:"Process Creation" /success:enable /failure:enable
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit" `
  -Name ProcessCreationIncludeCmdLine_Enabled -Type DWord -Value 1
# HTH Guide Excerpt: end ps-process-audit

# HTH Guide Excerpt: begin ps-review-security-events
# Review the signal locally (CONSUMER) or forward to a SIEM (ENTERPRISE via Windows
# Event Forwarding / Sentinel connector). Recent process-creation events:
Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=4688 } -MaxEvents 20 |
  Format-Table TimeCreated, @{n='CmdLine';e={ ($_.Properties[8].Value) }} -AutoSize

# Defender / ASR detections:
Get-WinEvent -LogName "Microsoft-Windows-Windows Defender/Operational" -MaxEvents 20 -ErrorAction SilentlyContinue |
  Where-Object Id -in 1116,1117,1121,1122 | Format-Table TimeCreated, Id, Message -AutoSize
# HTH Guide Excerpt: end ps-review-security-events
