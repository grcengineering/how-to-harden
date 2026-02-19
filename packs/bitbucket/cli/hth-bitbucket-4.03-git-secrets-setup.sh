#!/usr/bin/env bash
# HTH Bitbucket Control 4.3: Git Secrets Pre-Commit Hook
# Profile: L1 | NIST: IA-5
# https://howtoharden.com/guides/bitbucket/#43-scan-for-secrets-in-commits

# HTH Guide Excerpt: begin cli-git-secrets-setup
# Install git-secrets
brew install git-secrets

# Configure for repository
cd your-repo
git secrets --install
git secrets --register-aws

# Add custom patterns
git secrets --add 'PRIVATE KEY'
git secrets --add 'api[_-]?key'
# HTH Guide Excerpt: end cli-git-secrets-setup
