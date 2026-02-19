-- HTH CyberArk Control 6.1: Enable Comprehensive Audit Logging — Detection Queries
-- Profile: L1 | NIST: AU-2, AU-3
-- https://howtoharden.com/guides/cyberark/#61-enable-comprehensive-audit-logging

-- HTH Guide Excerpt: begin db-mass-retrieval
SELECT UserName, COUNT(*) as RetrievalCount
FROM AuditLog
WHERE Action = 'Retrieve Password'
  AND Timestamp > DATEADD(hour, -1, GETDATE())
GROUP BY UserName
HAVING COUNT(*) > 20;
-- HTH Guide Excerpt: end db-mass-retrieval

-- HTH Guide Excerpt: begin db-after-hours-access
SELECT *
FROM AuditLog
WHERE Action IN ('Logon', 'Retrieve Password')
  AND (DATEPART(hour, Timestamp) < 6 OR DATEPART(hour, Timestamp) > 20)
  AND DATEPART(dw, Timestamp) IN (1, 7);  -- Weekends
-- HTH Guide Excerpt: end db-after-hours-access

-- HTH Guide Excerpt: begin db-failed-auth-spike
SELECT UserName, SourceIP, COUNT(*) as FailedAttempts
FROM AuditLog
WHERE Action = 'Logon'
  AND Status = 'Failed'
  AND Timestamp > DATEADD(minute, -15, GETDATE())
GROUP BY UserName, SourceIP
HAVING COUNT(*) > 5;
-- HTH Guide Excerpt: end db-failed-auth-spike
