#!/usr/bin/env bash
# HTH HashiCorp Vault Control 6.2: Implement Disaster Recovery
# Profile: L2 | NIST: CP-9, CP-10
# https://howtoharden.com/guides/hashicorp-vault/#62-implement-disaster-recovery

set -euo pipefail

# HTH Guide Excerpt: begin cli-disaster-recovery
# Create Raft snapshot
vault operator raft snapshot save backup.snap

# Verify snapshot
vault operator raft snapshot inspect backup.snap

# Restore from snapshot (DR scenario)
vault operator raft snapshot restore backup.snap

# For Enterprise: Configure DR replication
vault write -f sys/replication/dr/primary/enable
# HTH Guide Excerpt: end cli-disaster-recovery
