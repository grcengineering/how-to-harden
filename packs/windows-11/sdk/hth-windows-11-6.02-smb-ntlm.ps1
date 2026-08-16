# Control: 6.2 Harden SMB and Block Legacy NTLM
# Profile Level: L2 (Walk) | Track: Both (24H2 controls)
# Frameworks: NIST 800-53 SC-8/IA-2 | CIS Controls v8 4.8/3.10
# Guide: https://howtoharden.com/guides/windows-11/#62-harden-smb-and-block-legacy-ntlm
# Interface: SmbShare/SmbClient PowerShell (built-in)
#   https://learn.microsoft.com/en-us/windows-server/storage/file-server/smb-signing
#   https://learn.microsoft.com/en-us/windows-server/storage/file-server/smb-ntlm-blocking
# Run elevated. BlockNTLM and SMB auditing require Windows 11 24H2+.

# HTH Guide Excerpt: begin ps-smb-signing
# Require SMB signing on both client and server sides (default on 24H2 Ent/Pro/Edu;
# enforce explicitly and verify).
Set-SmbClientConfiguration -RequireSecuritySignature $true -Force
Set-SmbServerConfiguration -RequireSecuritySignature $true -Force
Get-SmbClientConfiguration | Format-List RequireSecuritySignature
Get-SmbServerConfiguration | Format-List RequireSecuritySignature
# HTH Guide Excerpt: end ps-smb-signing

# HTH Guide Excerpt: begin ps-smb-audit-then-blockntlm
# STEP 1 (24H2): audit for peers that don't support signing/encryption BEFORE enforcing.
Set-SmbServerConfiguration -AuditClientDoesNotSupportSigning  $true -Force
Set-SmbClientConfiguration -AuditServerDoesNotSupportSigning  $true -Force
# Review events, then STEP 2: block NTLM on the SMB client (allowlist real dependencies).
Set-SmbClientConfiguration -BlockNTLM $true -Force
Get-SmbClientConfiguration | Format-List BlockNTLM
# Per-connection exception when a specific server legitimately needs NTLM:
#   New-SmbMapping -RemotePath \\server\share -BlockNTLM $false
# HTH Guide Excerpt: end ps-smb-audit-then-blockntlm
