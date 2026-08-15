# Control: 6.1 Harden the Windows Firewall
# Profile Level: L1 (Crawl) | Track: Both
# Frameworks: NIST 800-53 SC-7/AU-2 | CIS Controls v8 4.4/4.5/8.5
# Guide: https://howtoharden.com/guides/windows-11/#61-harden-the-windows-firewall
# Interface: NetSecurity PowerShell module (built-in)
#   https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/configure-with-command-line
# Run elevated.

# HTH Guide Excerpt: begin ps-firewall-enable
# Enable all three profiles with default-deny inbound, allow outbound.
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True `
  -DefaultInboundAction Block -DefaultOutboundAction Allow
# HTH Guide Excerpt: end ps-firewall-enable

# HTH Guide Excerpt: begin ps-firewall-logging
# Turn on dropped-packet and successful-connection logging; grow the log to >= 20 MB.
Set-NetFirewallProfile -Profile Domain,Public,Private `
  -LogFileName "%SystemRoot%\System32\LogFiles\Firewall\pfirewall.log" `
  -LogMaxSizeKilobytes 20480 -LogAllowed True -LogBlocked True

# Verify posture:
Get-NetFirewallProfile | Format-Table Name, Enabled, DefaultInboundAction, DefaultOutboundAction, LogBlocked
# HTH Guide Excerpt: end ps-firewall-logging
