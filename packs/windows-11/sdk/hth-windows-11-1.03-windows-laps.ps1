# Control: 1.3 Rotate Local Administrator Passwords with Windows LAPS
# Profile Level: L2 (Walk) | Track: Enterprise (AD or Entra join required)
# Frameworks: NIST 800-53 IA-5/AC-6 | CIS Controls v8 5.2/5.4
# Guide: https://howtoharden.com/guides/windows-11/#13-rotate-local-administrator-passwords-with-windows-laps
# Interface: Windows LAPS PowerShell module (built-in, Windows 11 23H2+/patched earlier)
#   https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-management-powershell
# Run elevated.

# HTH Guide Excerpt: begin ps-laps-configure
# Set the master switch via policy registry (BackupDirectory):
#   0 = Disabled, 1 = Back up to Microsoft Entra only, 2 = Back up to Active Directory only.
# (You cannot back up to both.) Delivered via GPO (System > LAPS) or the LAPS CSP;
# shown here as the resulting registry value under the Group Policy root.
New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\LAPS" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\LAPS" `
  -Name BackupDirectory -Type DWord -Value 2   # 2 = Active Directory

# For AD, one-time schema extension + device self-permission (run with rights):
#   Update-LapsADSchema
#   Set-LapsADComputerSelfPermission -Identity "OU=Workstations,DC=contoso,DC=com"
# HTH Guide Excerpt: end ps-laps-configure

# HTH Guide Excerpt: begin ps-laps-operate
# Retrieve the current managed password (choose the cmdlet matching your backup target):
#   Get-LapsADPassword  -Identity "WORKSTATION01" -AsPlainText   # Active Directory
#   Get-LapsAADPassword -DeviceIds "WORKSTATION01"               # Microsoft Entra

# Force an immediate rotation (works for either backup target):
Reset-LapsPassword -Verbose

# Diagnostics:
Get-LapsDiagnostics
# HTH Guide Excerpt: end ps-laps-operate
