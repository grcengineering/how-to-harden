-- HTH Docker Hub Control 4.1: Audit Logging
-- Profile: L1 | NIST: AU-2
-- https://howtoharden.com/guides/dockerhub/#41-audit-logging

-- HTH Guide Excerpt: begin db-detect-unusual-push
-- Detect unusual push activity
SELECT user, repository, COUNT(*) as push_count
FROM docker_audit_log
WHERE action = 'push'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user, repository
HAVING COUNT(*) > 10;
-- HTH Guide Excerpt: end db-detect-unusual-push
