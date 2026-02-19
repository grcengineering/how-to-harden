-- HTH Salesforce Control 2.1.1: IP Allowlisting - Restricting Gainsight
-- Profile: L1 | NIST: AC-3, SC-7
-- https://howtoharden.com/guides/salesforce/#211-ip-allowlisting-restricting-gainsight

-- HTH Guide Excerpt: begin db-detect-gainsight-blocks
-- Query for blocked Gainsight login attempts
SELECT Id, LoginTime, SourceIp, Status, Application
FROM LoginHistory
WHERE Application = 'Gainsight'
  AND Status = 'Failed'
  AND LoginTime = LAST_N_DAYS:7
-- HTH Guide Excerpt: end db-detect-gainsight-blocks
