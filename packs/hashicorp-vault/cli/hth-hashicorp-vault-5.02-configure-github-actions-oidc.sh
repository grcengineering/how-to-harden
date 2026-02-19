#!/usr/bin/env bash
# HTH HashiCorp Vault Control 5.2: Implement OIDC for GitHub Actions
# Profile: L2 | NIST: IA-2, IA-5(2)
# https://howtoharden.com/guides/hashicorp-vault/#52-implement-oidc-for-github-actions

# HTH Guide Excerpt: begin cli-github-actions-oidc
# Configure JWT auth for GitHub Actions
vault auth enable -path=github-actions jwt

vault write auth/github-actions/config \
    oidc_discovery_url="https://token.actions.githubusercontent.com" \
    bound_issuer="https://token.actions.githubusercontent.com"

vault write auth/github-actions/role/deploy \
    role_type="jwt" \
    bound_audiences="https://github.com/your-org" \
    bound_subject="repo:your-org/your-repo:ref:refs/heads/main" \
    user_claim="sub" \
    policies="deploy-secrets" \
    ttl=5m
# HTH Guide Excerpt: end cli-github-actions-oidc
