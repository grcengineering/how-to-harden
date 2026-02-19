#!/usr/bin/env bash
# HTH Databricks Control 4.1: Manage Secret Scopes
# Profile: L1 | NIST: SC-28
# https://howtoharden.com/guides/databricks/#41-use-databricks-secret-scopes

# HTH Guide Excerpt: begin cli-manage-secret-scopes
# Create secret scope backed by Databricks
databricks secrets create-scope --scope production-secrets

# Add secrets
databricks secrets put --scope production-secrets --key db-password
databricks secrets put --scope production-secrets --key api-key

# Grant read access to specific group
databricks secrets put-acl \
  --scope production-secrets \
  --principal data_engineers \
  --permission READ
# HTH Guide Excerpt: end cli-manage-secret-scopes
