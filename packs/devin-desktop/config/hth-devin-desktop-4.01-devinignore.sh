#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-desktop-4.1
#   guide: https://howtoharden.com/guides/devin-desktop/#41-exclude-sensitive-files-from-agent-context
#   profile: L1
#   mode: read-only
#   requires: bash
# HTH Devin Desktop 4.1: Exclude Sensitive Files from Agent Context
# Profile Level: L1 | NIST 800-53: CM-6
# Verified against official documentation: 2026-10-29; no live product validation.

# HTH Guide Excerpt: begin devinignore
set -euo pipefail
# Source: https://docs.devin.ai/desktop/context-awareness/devin-ignore
# Prints a candidate .devinignore; does not alter the repository or inspect secrets.
# Review and merge into the repository root .devinignore. Do not overwrite existing rules.
# These gitignore-style exclusions are not a shell sandbox or a DLP boundary.
cat <<'IGNORE'
# HTH sensitive-file baseline; adapt to your repository and test harmless canaries.
.env
.env.*
*.pem
*.key
*.p12
*.pfx
credentials.json
secrets/
private-data/
IGNORE
# HTH Guide Excerpt: end devinignore
