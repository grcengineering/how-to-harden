#!/usr/bin/env bash
# HTH CyberArk Control 2.2: Implement Vault High Availability — DR Commands
# Profile: L2 | NIST: CP-9, CP-10
# https://howtoharden.com/guides/cyberark/#22-implement-vault-high-availability

set -euo pipefail

# HTH Guide Excerpt: begin cli-dr-replication
# Verify vault replication status
PAReplicate.exe Status

# Test DR failover (non-production)
PAReplicate.exe Failover /target:DR_VAULT
# HTH Guide Excerpt: end cli-dr-replication
