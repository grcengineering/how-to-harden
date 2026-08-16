# Control: 2.1 Verify Secure Boot and TPM 2.0
# Profile Level: L1 (Crawl) | Track: Both
# Frameworks: NIST 800-53 SI-7/SC-51 | CIS Controls v8 4.1
# Guide: https://howtoharden.com/guides/windows-11/#21-verify-secure-boot-and-tpm-20
# Interface: PowerShell SecureBoot + TPM modules (built-in)
#   https://learn.microsoft.com/en-us/powershell/module/secureboot/confirm-securebootuefi
# Run elevated.

# HTH Guide Excerpt: begin ps-verify-secureboot-tpm
# Secure Boot: returns $True when supported AND enabled; a BIOS/non-UEFI machine
# raises "Cmdlet not supported on this platform." Do not reconfigure the TPM via
# TPM.msc - Windows auto-initializes and owns it; verify state only.
try {
  if (Confirm-SecureBootUEFI) {
    Write-Output "2.1 PASS: Secure Boot is enabled."
  } else {
    Write-Warning "2.1 Secure Boot is supported but DISABLED - enable it in UEFI firmware."
  }
} catch {
  Write-Warning "2.1 Secure Boot not available (legacy BIOS / non-UEFI): $($_.Exception.Message)"
}

$tpm = Get-Tpm
if ($tpm.TpmPresent -and $tpm.TpmReady) {
  Write-Output "2.1 PASS: TPM present and ready."
} else {
  Write-Warning "2.1 TPM not present/ready (TpmPresent=$($tpm.TpmPresent), TpmReady=$($tpm.TpmReady))."
}
# HTH Guide Excerpt: end ps-verify-secureboot-tpm
