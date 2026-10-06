#!/usr/bin/env bash
# HTH GitHub Control 3.12: Allowed GitHub Actions List
# Profile: L1 | NIST: CM-7, SA-12
# https://howtoharden.com/guides/github/#31-restrict-third-party-github-actions-to-verified-creators-only
set -euo pipefail
: "${GITHUB_ORG:?Set GITHUB_ORG (your GitHub organization name)}"

# HTH Guide Excerpt: begin cli-actions-allowlist
# Tier 1 - GitHub Official (Always Allow)
# actions/*
# github/*

# Tier 2 - Verified Cloud Vendors
# aws-actions/*
# azure/*
# google-github-actions/*
# hashicorp/*
# docker/*

# Tier 3 - Common Verified Actions
# codecov/codecov-action@*
# snyk/actions/*
# sonatype-nexus-community/*

# The allow-list only takes effect when the organization policy is "selected"
gh api --method PUT "/orgs/${GITHUB_ORG}/actions/permissions" \
  -f enabled_repositories=all \
  -f allowed_actions=selected

# Configure the allow-list (booleans are typed with -F; -f would send strings)
gh api --method PUT "/orgs/${GITHUB_ORG}/actions/permissions/selected-actions" \
  -F github_owned_allowed=true \
  -F verified_allowed=true \
  -f 'patterns_allowed[]=actions/*' \
  -f 'patterns_allowed[]=github/*' \
  -f 'patterns_allowed[]=aws-actions/*' \
  -f 'patterns_allowed[]=azure/*' \
  -f 'patterns_allowed[]=google-github-actions/*' \
  -f 'patterns_allowed[]=hashicorp/*' \
  -f 'patterns_allowed[]=docker/*'
# HTH Guide Excerpt: end cli-actions-allowlist
