#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: anthropic-api-2.1
#   guide: https://howtoharden.com/guides/anthropic-api/#21-segment-workspaces-by-environment
#   profile: L1
#   mode: read-only
#   requires: ANTHROPIC_ADMIN_KEY(Console admin credential)
# Source: https://platform.claude.com/docs/en/manage-claude/workspaces
source "$(dirname "$0")/../../claude-enterprise/cli/common.sh"
# HTH Guide Excerpt: begin native-cli-workspace-inventory
# ant 2.7.0+; Includes Default Workspace explicitly; the API otherwise omits it.
anthropic_cli_inventory organization:workspaces workspace --include-default
# HTH Guide Excerpt: end native-cli-workspace-inventory
