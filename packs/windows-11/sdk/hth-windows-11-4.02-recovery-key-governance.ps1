# Control: 4.2 Govern the Encryption Recovery Key
# Profile Level: L1 (Crawl) | Track: Both (consumer privacy tension lives here)
# Frameworks: NIST 800-53 SC-12/SC-28 | CIS Controls v8 3.11
# Guide: https://howtoharden.com/guides/windows-11/#42-govern-the-encryption-recovery-key
# Interface: BitLocker PowerShell + registry
#   https://learn.microsoft.com/en-us/windows/security/operating-system-security/data-protection/bitlocker/configure
# Run elevated.

# HTH Guide Excerpt: begin ps-escrow-enterprise
# ENTERPRISE: back the recovery password up to Active Directory or Microsoft Entra.
# (Driven fleet-wide by the GPO "Choose how BitLocker-protected operating system
# drives can be recovered"; per-device escrow cmdlets shown here.)
$kp = (Get-BitLockerVolume -MountPoint "C:").KeyProtector |
  Where-Object KeyProtectorType -eq 'RecoveryPassword' | Select-Object -First 1
# To Microsoft Entra ID:
BackupToAAD-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $kp.KeyProtectorId
# To Active Directory (domain-joined):
#   Backup-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $kp.KeyProtectorId
# HTH Guide Excerpt: end ps-escrow-enterprise

# HTH Guide Excerpt: begin ps-consumer-key-custody
# CONSUMER privacy choice: Home Device Encryption escrows the recovery key to your
# Microsoft account by DEFAULT. To take manual custody instead, export the recovery
# password and store it OFFLINE (USB / printed / file on removable media):
$rp = (Get-BitLockerVolume -MountPoint "C:").KeyProtector |
  Where-Object KeyProtectorType -eq 'RecoveryPassword'
$rp | ForEach-Object { "ID: $($_.KeyProtectorId)  KEY: $($_.RecoveryPassword)" }
# Also available via: Manage BitLocker > "Back up your recovery key" (USB / file / print).

# To PREVENT automatic Device Encryption entirely (so you manage BitLocker yourself
# on Pro, with NO Microsoft-account escrow), set BEFORE encryption is enabled:
#   New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" -Force | Out-Null
#   Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" `
#     -Name PreventDeviceEncryption -Type DWord -Value 1
# NOTE: a local-account-only device leaves the clear key in place - "unprotected
# even though the data is encrypted." Manual offline custody is the private, protected path.
# HTH Guide Excerpt: end ps-consumer-key-custody
