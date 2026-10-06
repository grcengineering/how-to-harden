#!/usr/bin/env bash
# HTH GitHub Control 3.15: Audit Workflows for Missing Permissions
# Profile: L1 | SLSA: Build L2
# https://howtoharden.com/guides/github/#32-use-least-privilege-workflow-permissions
#
# Local, read-only audit of a checked-out repository. Exits 1 when a finding exists.
set -euo pipefail

# HTH Guide Excerpt: begin api-audit-workflow-permissions
# Workflows with no permissions: key (they inherit the repository/org default)
MISSING=$(find .github/workflows \( -name '*.yml' -o -name '*.yaml' \) -exec grep -L 'permissions:' {} + || true)
# Workflows that grant write-all
WRITEALL=$(grep -rlE 'permissions:[[:space:]]*write-all' .github/workflows || true)
if [ -n "${MISSING}" ]; then echo "${MISSING}" | sed 's/^/NO PERMISSIONS KEY: /'; fi
if [ -n "${WRITEALL}" ]; then echo "${WRITEALL}" | sed 's/^/WRITE-ALL: /'; fi
[ -z "${MISSING}${WRITEALL}" ] || exit 1
echo "All workflows declare least-privilege permissions."
# HTH Guide Excerpt: end api-audit-workflow-permissions
