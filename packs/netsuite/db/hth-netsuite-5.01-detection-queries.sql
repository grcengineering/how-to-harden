-- HTH NetSuite Control 5.1: Security Alerts
-- Profile: L1 | NIST: SI-4
-- https://howtoharden.com/guides/netsuite/#51-security-alerts

-- HTH Guide Excerpt: begin db-detect-unusual-activity
-- Detect unusual transaction volumes
SELECT entity, COUNT(*) as txn_count
FROM Transaction
WHERE trandate >= TODAY - 7
GROUP BY entity
HAVING COUNT(*) > 100;

-- Detect login anomalies
SELECT user, ipaddress, COUNT(*) as login_count
FROM LoginAudit
WHERE date >= TODAY - 1
GROUP BY user, ipaddress
HAVING COUNT(*) > 20;

-- Detect bulk data exports
SELECT user, action, recordtype, COUNT(*) as record_count
FROM SystemNote
WHERE date >= TODAY - 1
  AND action = 'export'
GROUP BY user, action, recordtype
HAVING COUNT(*) > 1000;
-- HTH Guide Excerpt: end db-detect-unusual-activity
