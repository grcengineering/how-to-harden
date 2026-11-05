#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: claude-enterprise-1.3
#   guide: https://howtoharden.com/guides/claude-enterprise/#13-apply-least-privilege-roles-and-groups
#   profile: L1
#   mode: read-only
#   requires: ANTHROPIC_ADMIN_KEY(Enterprise read:members)
# Source: https://platform.claude.com/docs/en/manage-claude/user-management
source "$(dirname "$0")/common.sh"
# HTH Guide Excerpt: begin native-cli-member-inventory
# Native ant 2.7.0+; this inventories roles and does not set SSO or custom roles.
anthropic_cli_inventory organization:users user
# HTH Guide Excerpt: end native-cli-member-inventory
