#!/usr/bin/env bash
# HTH Google Workspace Control 1.01: Check 2-Step Verification Enrollment
# Profile: L1 | NIST: IA-2(1), IA-2(6)
# Requires: GAM (https://github.com/GAM-team/GAM)

# HTH Guide Excerpt: begin cli-check-2sv
# List users not enrolled in 2SV
gam print users query "isEnrolledIn2Sv=false"

# Generate report of 2SV status
gam report users parameters accounts:is_2sv_enrolled,accounts:is_2sv_enforced

# Send reminder to users not enrolled
gam print users query "isEnrolledIn2Sv=false" | \
  gam csv - gam user ~primaryEmail sendemail subject "MFA Enrollment Required" \
  message "Please enroll in 2-Step Verification within 7 days."
# HTH Guide Excerpt: end cli-check-2sv
