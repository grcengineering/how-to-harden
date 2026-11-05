#!/usr/bin/env bash
# HTH Control claude-enterprise 2.2: Native recording-state read
# Profile: L2 | Existing authorized ANTHROPIC_ADMIN_KEY; exact minimum Enterprise scope unverified
# https://howtoharden.com/guides/claude-enterprise/#22-enable-the-compliance-api-with-least-privilege-keys
# Source: official ant 2.7.0 organization:compliance-settings retrieve --help
set -euo pipefail
source "$(dirname "$0")/common.sh"
# HTH Guide Excerpt: begin native-cli-recording-state
# Read singleton, not a Security Center or effective-settings inventory.
# Disabled exits 1; malformed/unknown state exits nonzero. Enabled is not proof of delivery.
anthropic_cli_inventory organization:compliance-settings compliance_settings
# HTH Guide Excerpt: end native-cli-recording-state
