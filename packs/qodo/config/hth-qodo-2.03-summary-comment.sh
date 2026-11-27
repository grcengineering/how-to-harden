#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: qodo-2.3
#   guide: https://howtoharden.com/guides/qodo/#23-keep-ai-summaries-separate-from-author-descriptions
#   profile: L2
#   mode: read-only
#   requires: Bash; emits one native configuration fragment for reviewed merge
# HTH qodo 2.3: Keep AI summaries separate from author descriptions
# Profile: L2 (Walk)
# Guide: https://howtoharden.com/guides/qodo/#23-keep-ai-summaries-separate-from-author-descriptions
# Reference: https://docs.qodo.ai/configuration/configuration-and-command-reference
# HTH Guide Excerpt: begin summary-comment
set -euo pipefail
cat <<'HTH_CONFIG'
[qodo_describe_agent]
publish_mode = "comment"
HTH_CONFIG
# HTH Guide Excerpt: end summary-comment
