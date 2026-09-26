#!/usr/bin/env bash
# =============================================================================
# HTH GitLab Control 4.2: Enable Commit Signing
# Profile: L2 | Section: 4.2
# =============================================================================
#
# Writes to the caller's GLOBAL git config. SIGNING_KEY_ID is required so the
# script fails loudly instead of storing a placeholder as the signing key.
# Find your key ID with: gpg --list-secret-keys --keyid-format=long
set -euo pipefail
: "${SIGNING_KEY_ID:?Set SIGNING_KEY_ID to the GPG key ID you added under Avatar > Edit profile > Access > GPG keys}"

# HTH Guide Excerpt: begin git-signing-config
git config --global commit.gpgsign true
git config --global user.signingkey "${SIGNING_KEY_ID}"
# HTH Guide Excerpt: end git-signing-config
