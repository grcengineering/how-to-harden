# Control: 4.1 Encrypt the System Drive (BitLocker / Device Encryption)
# Profile Level: L1 (Crawl) | Track: Both (full BitLocker = Pro+; Device Encryption = Home)
# Frameworks: NIST 800-53 SC-28 | CIS Controls v8 3.6/3.11
# Guide: https://howtoharden.com/guides/windows-11/#41-encrypt-the-system-drive-bitlocker-or-device-encryption
# Interface: BitLocker PowerShell module (Pro/Enterprise/Education)
#   https://learn.microsoft.com/en-us/windows/security/operating-system-security/data-protection/bitlocker/operations-guide
# Run elevated. Home uses Settings > Privacy & security > Device encryption (no manage-bde).

# HTH Guide Excerpt: begin ps-bitlocker-enable
# ENTERPRISE/PRO: enable BitLocker on the OS drive with XTS-AES 256. For L2/L3 add a
# TPM+PIN protector (materially harder against VMK-extraction/bitpixie-class attacks
# than TPM-only). This example prompts for a PIN.
$pin = Read-Host -AsSecureString "Enter a BitLocker startup PIN"
Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly `
  -Pin $pin -TpmAndPinProtector -SkipHardwareTest
# Add a recovery password protector (escrow it per control 4.2):
Add-BitLockerKeyProtector -MountPoint "C:" -RecoveryPasswordProtector
# HTH Guide Excerpt: end ps-bitlocker-enable

# HTH Guide Excerpt: begin ps-bitlocker-status
# Verify full protection. "Waiting for Activation" / a clear key present means the
# drive is encrypted but NOT yet protected - resolve the recovery-key escrow (4.2).
$v = Get-BitLockerVolume -MountPoint "C:"
"ProtectionStatus : $($v.ProtectionStatus)"   # On = protected
"VolumeStatus     : $($v.VolumeStatus)"        # FullyEncrypted
"EncryptionMethod : $($v.EncryptionMethod)"    # XtsAes256 for hardened deployments
$v.KeyProtector | Format-Table KeyProtectorType, KeyProtectorId
# HTH Guide Excerpt: end ps-bitlocker-status
