#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 1.2: Configure Directory Sync (SCIM)
# Profile Level: L2 (Hardened)
# Frameworks: NIST AC-2, IA-5(1)
# Source: https://howtoharden.com/guides/vercel/#12-configure-directory-sync-scim
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin api

# --- Verify team SAML/SCIM configuration ---
echo "=== Directory Sync Configuration ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v2/teams/${VERCEL_TEAM_ID}" | \
  jq '{
    name: .name,
    saml: .saml,
    remoteCaching: .remoteCaching,
    membership: .membership
  }'

# --- List current team members and their roles ---
echo ""
echo "=== Current Team Members ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v2/teams/${VERCEL_TEAM_ID}/members?limit=100" | \
  jq '.members[] | {uid, email, role, joinedFrom}'

# --- Audit members for role compliance ---
echo ""
echo "=== Members with Owner Role (should be minimal) ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v2/teams/${VERCEL_TEAM_ID}/members?limit=100" | \
  jq '.members[] | select(.role == "OWNER") | {uid, email}'

# --- Verify Access Groups exist (Enterprise) ---
echo ""
echo "=== Access Groups ==="
curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v1/access-groups?teamId=${VERCEL_TEAM_ID}" | \
  jq '.accessGroups[]? | {name, membersCount, projectsCount}'

# HTH Guide Excerpt: end api
