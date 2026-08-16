# Control: 3.3 Enable Controlled Folder Access and Network Protection
# Profile Level: L2 (Walk) | Track: Both
# Frameworks: NIST 800-53 SI-3/SC-7 | CIS Controls v8 10.1/13.3
# Guide: https://howtoharden.com/guides/windows-11/#33-enable-controlled-folder-access-and-network-protection
# Interface: Defender PowerShell (Set-MpPreference)
#   https://learn.microsoft.com/en-us/defender-endpoint/controlled-folder-access-configure
#   https://learn.microsoft.com/en-us/defender-endpoint/enable-network-protection
# Run elevated.

# HTH Guide Excerpt: begin ps-controlled-folder-access
# Ransomware protection: only allowed apps may modify protected folders.
#   Modes: 0 Disabled, 1 Enabled, 2 AuditMode, 3 BlockDiskModificationOnly, 4 AuditDiskModificationOnly
Set-MpPreference -EnableControlledFolderAccess Enabled
# Add extra protected folders / allow a trusted line-of-business app if needed:
#   Add-MpPreference -ControlledFolderAccessProtectedFolders "D:\Sensitive"
#   Add-MpPreference -ControlledFolderAccessAllowedApplications "C:\Apps\app1.exe"
# HTH Guide Excerpt: end ps-controlled-folder-access

# HTH Guide Excerpt: begin ps-network-protection
# Block connections to low-reputation/malicious domains for ALL apps (not just browsers).
Set-MpPreference -EnableNetworkProtection Enabled   # Enabled(1) = block; AuditMode to observe

# Verify both:
$p = Get-MpPreference
"EnableControlledFolderAccess : $($p.EnableControlledFolderAccess)"  # 1 = Enabled
"EnableNetworkProtection      : $($p.EnableNetworkProtection)"       # 1 = Enabled
# HTH Guide Excerpt: end ps-network-protection
