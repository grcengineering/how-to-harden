-- =============================================================================
-- HTH New Relic Control 4.1: NrAuditEvent Detection Queries
-- Profile: L1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect configuration changes
SELECT * FROM NrAuditEvent
WHERE actionIdentifier LIKE '%update%'
SINCE 24 hours ago

-- Detect API key creation
SELECT * FROM NrAuditEvent
WHERE actionIdentifier LIKE '%apiKey%'
SINCE 7 days ago

-- Detect user additions
SELECT * FROM NrAuditEvent
WHERE actionIdentifier LIKE '%user%'
SINCE 7 days ago
-- HTH Guide Excerpt: end db-detect-anomalies
