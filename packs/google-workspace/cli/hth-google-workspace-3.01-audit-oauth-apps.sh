#!/usr/bin/env bash
# HTH Google Workspace Control 3.01: Audit OAuth Apps
# Profile: L1 | NIST: AC-3, CM-7
# Requires: GAM (https://github.com/GAM-team/GAM)

# HTH Guide Excerpt: begin cli-audit-oauth
# List all OAuth tokens in use
gam all users print tokens

# List apps with specific scopes
gam all users print tokens scopes "https://mail.google.com/"

# Revoke tokens for specific app
gam all users deprovision token clientid 1234567890.apps.googleusercontent.com

# Block unverified apps (via Admin SDK)
# Note: Use Admin Console for comprehensive control
# HTH Guide Excerpt: end cli-audit-oauth
