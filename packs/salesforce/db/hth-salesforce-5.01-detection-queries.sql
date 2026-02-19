-- HTH Salesforce Control 5.1: Enable Event Monitoring for API Anomalies
-- Profile: L1 | NIST: AU-2, AU-6, SI-4
-- https://howtoharden.com/guides/salesforce/#51-enable-event-monitoring-for-api-anomalies

-- HTH Guide Excerpt: begin db-bulk-data-export
-- Query EventLogFile for large API responses
SELECT EventTime, Username, SourceIp, ClientId, RequestedEntities, CPU_TIME
FROM EventLogFile
WHERE EventType = 'API'
  AND CPU_TIME > 10000  -- High CPU indicates large query
  AND EventTime = LAST_N_HOURS:24
ORDER BY CPU_TIME DESC
-- HTH Guide Excerpt: end db-bulk-data-export

-- HTH Guide Excerpt: begin db-api-unexpected-ips
-- Detect API calls from IPs NOT in allowlist
SELECT EventTime, SourceIp, ClientId, Username, Status
FROM LoginHistory
WHERE LoginType = 'Application'
  AND SourceIp NOT IN ('35.166.202.113', '52.35.87.209', '34.221.135.142')  -- Gainsight IPs
  AND EventTime = LAST_N_DAYS:7
-- HTH Guide Excerpt: end db-api-unexpected-ips

-- HTH Guide Excerpt: begin db-unusual-time-access
-- Detect API activity during off-hours
SELECT EventTime, ClientId, Username, SourceIp
FROM EventLogFile
WHERE EventType = 'API'
  AND HOUR(EventTime) NOT IN (9,10,11,12,13,14,15,16,17)  -- Outside 9am-5pm
-- HTH Guide Excerpt: end db-unusual-time-access
