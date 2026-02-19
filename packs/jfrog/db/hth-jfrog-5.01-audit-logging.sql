-- HTH JFrog Control 5.1: Audit Logging
-- Profile: L1 | NIST: AU-2, AU-3
-- https://howtoharden.com/guides/jfrog/#51-audit-logging

-- HTH Guide Excerpt: begin detection-queries
-- Detect unusual upload patterns
SELECT user, repo, COUNT(*) as upload_count
FROM artifactory_access_log
WHERE action = 'DEPLOY'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user, repo
HAVING COUNT(*) > 50;

-- Detect downloads of vulnerable artifacts
SELECT user, path, xray_status
FROM artifactory_access_log a
JOIN xray_scan_results x ON a.path = x.artifact_path
WHERE a.action = 'DOWNLOAD'
  AND x.severity = 'critical'
  AND a.timestamp > NOW() - INTERVAL '24 hours';

-- Detect anonymous access attempts
SELECT source_ip, path, COUNT(*) as attempts
FROM artifactory_access_log
WHERE user = 'anonymous'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY source_ip, path
HAVING COUNT(*) > 10;
-- HTH Guide Excerpt: end detection-queries
