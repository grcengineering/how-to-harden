#!/usr/bin/env bash
# HTH GitHub Control 2.08: Configure Commit Signing
# Profile: L2 | NIST: SI-7
# https://howtoharden.com/guides/github/#24-enforce-commit-signing

# HTH Guide Excerpt: begin cli-configure-commit-signing
# Configure Git to sign commits with SSH key
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true

# Configure Git to sign commits with GPG key
git config --global user.signingkey YOUR_GPG_KEY_ID
git config --global commit.gpgsign true

# Verify a signed commit
git log --show-signature -1
# HTH Guide Excerpt: end cli-configure-commit-signing
