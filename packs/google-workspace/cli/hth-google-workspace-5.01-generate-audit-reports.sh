#!/usr/bin/env bash
# HTH Google Workspace Control 5.01: Generate Audit Reports
# Profile: L1 | NIST: AU-2, AU-3, AU-6
#
# TOOL STATUS NOTE (2026-04):
#   GAM is a COMMUNITY-MAINTAINED CLI, NOT a first-party Google product.
#   For first-party automation, use the Admin SDK Reports API
#   (admin.googleapis.com/admin/reports/v1/activities/...).
# Requires: GAM (https://github.com/GAM-team/GAM)

# HTH Guide Excerpt: begin cli-audit-reports
# Generate login report
gam report login start -7d end today

# Generate admin audit report
gam report admin start -7d end today

# Export Drive audit events
gam report drive start -7d end today event download

# Find suspicious logins
gam report login filter "is_suspicious==True"
# HTH Guide Excerpt: end cli-audit-reports
