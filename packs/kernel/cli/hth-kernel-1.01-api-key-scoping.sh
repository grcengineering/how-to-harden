#!/usr/bin/env bash
# Control: 1.1 Scope API Keys to Projects
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 AC-6/AC-3, CIS Controls v8 6, SOC 2 CC6.3
# Guide: https://howtoharden.com/guides/kernel/
# Interface: Kernel CLI (first-party) — https://www.kernel.sh/docs/reference/cli/api-keys
set -euo pipefail

# HTH Guide Excerpt: begin create-project-scoped-key
# Create a PROJECT-SCOPED key: it can only access resources inside the
# project it was issued for. The plaintext key is returned exactly once —
# store it in your secret manager immediately.
kernel api-keys create \
  --name staging-ci \
  --days-to-expire 30 \
  --project-id proj_staging_9f3k \
  --output json

# Omitting --project-id creates an ORG-SCOPED key that can reach every
# project. Reserve org-scoped keys for administrative operations only.
kernel api-keys create \
  --name org-admin-breakglass \
  --days-to-expire 90 \
  --output json
# HTH Guide Excerpt: end create-project-scoped-key

# HTH Guide Excerpt: begin verify-key-scope
# Verify the effective scope of the key you are holding: GET /auth/context
# returns the principal, organization, and the credential's maximum and
# effective scope — without exposing the secret.
curl -sS https://api.onkernel.com/auth/context \
  -H "Authorization: Bearer ${KERNEL_API_KEY}"
# HTH Guide Excerpt: end verify-key-scope
