#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: bito-2.2
#   guide: https://howtoharden.com/guides/bito/#22-enable-independent-and-supplemental-secret-checks
#   profile: L1
#   mode: read-only
#   requires: Bash; emits one native configuration fragment for reviewed merge
# HTH bito 2.2: Enable independent and supplemental secret checks
# Profile: L1 (Crawl)
# Guide: https://howtoharden.com/guides/bito/#22-enable-independent-and-supplemental-secret-checks
# Reference: https://docs.bito.ai/ai-code-reviews-in-git/install-run-as-a-self-hosted-service/agent-configuration-bito-cra.properties-file
# HTH Guide Excerpt: begin self-hosted-secret-feedback
set -euo pipefail
cat <<'HTH_CONFIG'
secret_scanner_feedback=True
HTH_CONFIG
# HTH Guide Excerpt: end self-hosted-secret-feedback
