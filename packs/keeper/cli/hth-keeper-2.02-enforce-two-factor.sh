#!/usr/bin/env bash
# HTH Keeper Control 2.2: Enforce Two-Factor Authentication
# Profile: L1 | CIS Controls: 6.5 | NIST 800-53: IA-2(1)
# https://howtoharden.com/guides/keeper/#22-enforce-two-factor-authentication
#
# Interface: Keeper Commander CLI (first-party).
#   Enterprise commands: https://docs.keeper.io/en/keeperpam/commander-cli/command-reference/enterprise-management-commands
#   Batch mode:          https://docs.keeper.io/en/keeperpam/commander-cli/commander-installation-setup/configuration/global-options
# Prerequisite: an authenticated Commander session (`keeper shell`, then `login`),
# or a config file created during a prior login for non-interactive batch runs.

set -euo pipefail

# HTH Guide Excerpt: begin cli-enforce-2fa
# Require two-factor authentication via the REQUIRE_TWO_FACTOR (BOOLEAN)
# role enforcement policy. Commands are piped to Commander in batch mode.
keeper --batch-mode - <<'EOF'
enterprise-role "Keeper Administrator" --enforcement "REQUIRE_TWO_FACTOR:True"
enterprise-role "Everyone" --enforcement "REQUIRE_TWO_FACTOR:True"
EOF
# HTH Guide Excerpt: end cli-enforce-2fa

# HTH Guide Excerpt: begin cli-verify-2fa-enforcement
# Verbose role view (-v) lists the enforcement policies applied to a role;
# confirm REQUIRE_TWO_FACTOR appears for every role that holds vault users.
keeper --batch-mode - <<'EOF'
enterprise-role "Keeper Administrator" -v
enterprise-role "Everyone" -v
EOF
# HTH Guide Excerpt: end cli-verify-2fa-enforcement
