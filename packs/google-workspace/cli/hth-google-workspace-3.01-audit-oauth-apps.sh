#!/usr/bin/env bash
# HTH Google Workspace Control 3.01: Audit OAuth Apps
# Profile: L1 | NIST: AC-3, CM-7
#
# TOOL STATUS NOTE (2026-04):
#   GAM is a COMMUNITY-MAINTAINED CLI, NOT a first-party Google product.
#   For first-party automation, use the Admin SDK Directory API tokens
#   endpoint (admin.googleapis.com/admin/directory/v1/users/.../tokens).
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
