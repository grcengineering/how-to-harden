-- HTH GitHub Control 2.06: Monitor Branch Protection Changes
-- Profile: L1 | NIST: CM-3
-- https://howtoharden.com/guides/github/#21-enable-branch-protection-for-all-critical-branches

-- HTH Guide Excerpt: begin db-monitor-branch-protection
-- If using audit log analysis
SELECT * FROM github_audit_log
WHERE action = 'protected_branch.policy_override'
   OR action = 'protected_branch.destroy'
-- HTH Guide Excerpt: end db-monitor-branch-protection
