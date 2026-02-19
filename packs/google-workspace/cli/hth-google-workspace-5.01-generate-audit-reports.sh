#!/usr/bin/env bash
# HTH Google Workspace Control 5.01: Generate Audit Reports
# Profile: L1 | NIST: AU-2, AU-3, AU-6
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
