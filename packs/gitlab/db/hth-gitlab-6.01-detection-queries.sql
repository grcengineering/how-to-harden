-- =============================================================================
-- HTH GitLab Control 6.1: Enable Audit Events
-- Profile: L1 | Section: 6.1
-- =============================================================================

-- HTH Guide Excerpt: begin detection-queries
-- Detect unusual repository cloning
SELECT user_id, project_path, COUNT(*) as clone_count
FROM audit_events
WHERE action = 'repository_clone'
  AND created_at > NOW() - INTERVAL '1 hour'
GROUP BY user_id, project_path
HAVING COUNT(*) > 20;

-- Detect pipeline variable modifications
SELECT *
FROM audit_events
WHERE entity_type = 'Ci::Variable'
  AND action IN ('create', 'update', 'destroy')
  AND created_at > NOW() - INTERVAL '24 hours';
-- HTH Guide Excerpt: end detection-queries
