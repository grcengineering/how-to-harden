#!/usr/bin/env python3
# =============================================================================
# HTH Snowflake Control 1.2: Key-Pair Connection Example
# Profile: L1 | NIST: IA-5
# =============================================================================

# HTH Guide Excerpt: begin sdk-key-pair-connection
import snowflake.connector

conn = snowflake.connector.connect(
    account='your_account',
    user='svc_etl_pipeline',
    private_key_file='/path/to/rsa_key.pem',
    warehouse='ETL_WH',
    database='PRODUCTION'
)
# HTH Guide Excerpt: end sdk-key-pair-connection
