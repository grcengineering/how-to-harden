#!/usr/bin/env bash
# HTH Control claude-enterprise 4.1: Effective spend limits (read-only)
# Profile: L2 | Requires: official ant 2.7.0+, ANTHROPIC_ADMIN_KEY(read:spend_limits)
# https://howtoharden.com/guides/claude-enterprise/#41-enforce-per-member-spend-limits
# Source: official ant 2.7.0 organization:spend-limits:effective list --help
set -euo pipefail
source "$(dirname "$0")/common.sh"
# HTH Guide Excerpt: begin native-cli-spend-inventory
# Inventory only; null amounts and inherited/future scopes need explicit review.
anthropic_cli_inventory organization:spend-limits:effective spend_limits --period monthly
# HTH Guide Excerpt: end native-cli-spend-inventory
