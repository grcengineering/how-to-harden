-- HTH CyberArk Control 5.2: Monitor Rotation Failures — Detection Query
-- Profile: L1 | NIST: IA-5(1)
-- https://howtoharden.com/guides/cyberark/#52-monitor-rotation-failures

-- HTH Guide Excerpt: begin db-rotation-failures
-- Query for rotation failures (via SIEM or reporting)
SELECT AccountName, SafeName, LastFailReason, LastFailDate
FROM PasswordVault_Accounts
WHERE CPMStatus = 'FAILED'
ORDER BY LastFailDate DESC;
-- HTH Guide Excerpt: end db-rotation-failures
