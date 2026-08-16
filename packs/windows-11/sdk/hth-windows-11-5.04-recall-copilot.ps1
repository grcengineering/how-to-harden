# Control: 5.4 Govern Recall and Copilot
# Profile Level: L2 (Walk) | Track: Both
# Frameworks: NIST 800-53 SI-12/CM-7 | CIS Controls v8 3.3/2.3
# Guide: https://howtoharden.com/guides/windows-11/#54-govern-recall-and-copilot
# Interface: DISM PowerShell + Appx + WindowsAI policy registry
#   https://learn.microsoft.com/en-us/windows/client-management/manage-recall
#   https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-windowsai
# Run elevated. Recall applies only to Copilot+ PCs. Policies require 24H2 + KB5055627.

# HTH Guide Excerpt: begin ps-recall-remove
# CONSUMER: remove the Recall optional feature entirely (requires a restart).
Disable-WindowsOptionalFeature -Online -FeatureName "Recall" -Remove
# Verify:
Get-WindowsOptionalFeature -Online -FeatureName "Recall" | Select-Object FeatureName, State
# HTH Guide Excerpt: end ps-recall-remove

# HTH Guide Excerpt: begin ps-recall-policy
# ENTERPRISE / managed (Pro-capable): turn off Recall snapshots and/or remove Recall
# by policy (equivalent to the WindowsAI GPO settings).
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Force | Out-Null
# "Turn off saving snapshots for Recall" (DisableAIDataAnalysis): 1 = disable saving snapshots
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name DisableAIDataAnalysis -Type DWord -Value 1
# "Allow Recall to be enabled" (AllowRecallEnablement): 0 = Recall is not available
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name AllowRecallEnablement -Type DWord -Value 0
# HTH Guide Excerpt: end ps-recall-policy

# HTH Guide Excerpt: begin ps-copilot-uninstall
# Copilot app: the legacy TurnOffWindowsCopilot policy is DEPRECATED and does not
# govern the current app. Uninstall it directly (per user):
$pkg = Get-AppxPackage -Name "Microsoft.Copilot" -ErrorAction SilentlyContinue
if ($pkg) {
  Remove-AppxPackage -Package $pkg.PackageFullName
  Write-Output "5.4 Copilot app removed."
} else {
  Write-Output "5.4 Copilot app not present."
}
# For managed fleets, enforce removal with the WindowsAI RemoveMicrosoftCopilotApp
# policy or App Control for Business / AppLocker.
# HTH Guide Excerpt: end ps-copilot-uninstall
