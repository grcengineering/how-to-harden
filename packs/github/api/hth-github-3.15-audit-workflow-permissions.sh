#!/usr/bin/env bash
# HTH GitHub Control 3.15: Audit Workflows for Missing Permissions
# Profile: L1 | SLSA: Build L2
# https://howtoharden.com/guides/github/#32-use-least-privilege-workflow-permissions

# HTH Guide Excerpt: begin api-audit-workflow-permissions
# Find workflows with 'write-all' or missing permissions
find .github/workflows -name "*.yml" -exec grep -L "permissions:" {} \;
# HTH Guide Excerpt: end api-audit-workflow-permissions
