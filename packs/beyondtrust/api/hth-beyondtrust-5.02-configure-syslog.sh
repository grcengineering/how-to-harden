#!/usr/bin/env bash
# HTH BeyondTrust Control 5.02: Forward Logs to SIEM
# Profile: L1 | NIST: AU-6
# https://howtoharden.com/guides/beyondtrust/#52-forward-logs-to-siem

# HTH Guide Excerpt: begin api-configure-syslog
# Configure syslog forwarding
# In BeyondTrust configuration:
# Management > System > Logging > Syslog

# Syslog configuration
Protocol: TLS
Server: siem.company.com
Port: 6514
Format: CEF (Common Event Format)
Events: All security events
# HTH Guide Excerpt: end api-configure-syslog
