#!/usr/bin/env bash
# HTH CyberArk Control 2.1: Harden Vault Server Configuration — DBParm.ini
# Profile: L1 | NIST: SC-8, SC-28
# https://howtoharden.com/guides/cyberark/#21-harden-vault-server-configuration
#
# CyberArk Vault Server consumes DBParm.ini natively. This script emits
# the hardened config to the vault's configuration directory. Apply on the
# Vault Server host (not via Conjur CLI — Vault has no first-party CLI).

set -euo pipefail

DBPARM_PATH="${DBPARM_PATH:-/CYBR/Server/Conf/DBParm.ini}"

# HTH Guide Excerpt: begin config-dbparm-encryption
cat > "${DBPARM_PATH}" <<'INI'
[MAIN]
EncryptionMethod=AES256
ServerKeyAge=365
BackupKeyAge=365
INI
# HTH Guide Excerpt: end config-dbparm-encryption

echo "Wrote hardened DBParm.ini to ${DBPARM_PATH}"
echo "Restart the CyberArk Vault service for changes to take effect."
