#!/usr/bin/env bash
# HTH Google Workspace Control 1.02: Manage Admin Roles
# Profile: L1 | NIST: AC-6(1), AC-6(5)
#
# TOOL STATUS NOTE (2026-04):
#   GAM is a COMMUNITY-MAINTAINED CLI, NOT a first-party Google product.
#   For first-party automation, use the Admin SDK Directory API roles
#   endpoint (admin.googleapis.com/admin/directory/v1/customer/.../roles).
# Requires: GAM (https://github.com/GAM-team/GAM)

# HTH Guide Excerpt: begin cli-manage-admin-roles
# List all Super Admins
gam print admins role "Super Admin"

# Create delegated admin role
gam create adminrole "Help Desk Admin" privileges \
  USERS_RETRIEVE,USERS_UPDATE,USERS_ALIAS

# Assign delegated role
gam create admin user helpdesk@domain.com role "Help Desk Admin"

# Remove Super Admin from non-essential users
gam delete admin user bob@domain.com role "Super Admin"
# HTH Guide Excerpt: end cli-manage-admin-roles
