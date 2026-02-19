-- =============================================================================
-- HTH Snowflake Control 5.2: SIEM Log Export Task
-- Profile: L1
-- =============================================================================

-- HTH Guide Excerpt: begin db-siem-export-task
-- Create task to export logs to S3/Azure Blob for SIEM ingestion
CREATE OR REPLACE TASK export_login_history
    WAREHOUSE = security_wh
    SCHEDULE = '60 MINUTE'
AS
    COPY INTO @security_logs/login_history/
    FROM (
        SELECT *
        FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
        WHERE event_timestamp > DATEADD(minute, -60, CURRENT_TIMESTAMP())
    )
    FILE_FORMAT = (TYPE = JSON);

ALTER TASK export_login_history RESUME;
-- HTH Guide Excerpt: end db-siem-export-task
