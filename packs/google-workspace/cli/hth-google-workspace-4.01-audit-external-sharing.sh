#!/usr/bin/env bash
# HTH Google Workspace Control 4.01: Audit External Drive Sharing
# Profile: L1 | NIST: AC-3, AC-22
# Requires: GAM (https://github.com/GAM-team/GAM)

# HTH Guide Excerpt: begin cli-audit-sharing
# Audit files shared externally
gam all users print filelist query "visibility='anyoneWithLink' or visibility='anyoneCanFind'"

# Find files shared with specific external domains
gam all users print filelist query "sharedWithExternalUsers"

# Generate sharing report
gam report drive user all parameters doc_type,visibility,shared_with_user_accounts
# HTH Guide Excerpt: end cli-audit-sharing
