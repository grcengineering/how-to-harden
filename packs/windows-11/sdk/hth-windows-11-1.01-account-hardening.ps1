# Control: 1.1 Apply a Microsoft Security Baseline / Harden Accounts
# Profile Level: L1 (Crawl) | Track: Both
# Frameworks: NIST 800-53 CM-2/CM-6 | CIS Controls v8 4.1/4.7
# Guide: https://howtoharden.com/guides/windows-11/#11-apply-a-microsoft-security-baseline-enterprise-or-harden-accounts-consumer
# Interface: PowerShell (built-in) + Security Compliance Toolkit (LGPO.exe)
#   https://learn.microsoft.com/en-us/windows/security/operating-system-security/device-management/windows-security-configuration-framework/security-compliance-toolkit-10
# Run elevated (Administrator).

# HTH Guide Excerpt: begin ps-baseline-lgpo
# ENTERPRISE (Pro/Enterprise/Education): apply a downloaded Microsoft security
# baseline to Local Group Policy on a standalone machine with LGPO.exe (shipped
# in the Security Compliance Toolkit). Import the baseline's GPO backup:
#   LGPO.exe /g ".\Windows 11 v25H2 Security Baseline\GPOs"
# Verify drift afterward with Policy Analyzer against the baseline .PolicyRules.
# NOTE: Group Policy tooling and the baselines are NOT supported on Windows Home.
# HTH Guide Excerpt: end ps-baseline-lgpo

# HTH Guide Excerpt: begin ps-account-audit
# CONSUMER + ENTERPRISE: enumerate local administrators and flag whether the
# current interactive user runs as admin day-to-day (the highest-value control).
$admins = Get-LocalGroupMember -Group "Administrators" |
  Select-Object -ExpandProperty Name
Write-Output "Local administrators:"
$admins | ForEach-Object { Write-Output "  $_" }

$me = "$env:USERDOMAIN\$env:USERNAME"
if ($admins -contains $me) {
  Write-Warning "1.1 Daily account '$me' is a local administrator - create and use a STANDARD account for daily work."
} else {
  Write-Output "1.1 PASS: daily account is not a local administrator."
}
# HTH Guide Excerpt: end ps-account-audit
