#!/usr/bin/env bash
# HTH HashiCorp Vault Control 4.1: Enable Audit Devices (ClickOps CLI)
# Profile: L1 | NIST: AU-2, AU-3
# https://howtoharden.com/guides/hashicorp-vault/#41-enable-comprehensive-audit-logging

set -euo pipefail

# HTH Guide Excerpt: begin cli-enable-audit
# Enable file audit device
vault audit enable file file_path=/vault/audit/vault-audit.log

# Enable syslog audit device
vault audit enable syslog tag="vault" facility="AUTH"

# Enable socket audit device (for SIEM)
vault audit enable socket \
    address="siem.company.com:514" \
    socket_type="tcp"

# Verify audit devices
vault audit list -detailed
# HTH Guide Excerpt: end cli-enable-audit
