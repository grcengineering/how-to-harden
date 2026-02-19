# =============================================================================
# HTH Databricks Control 4.1: Use Databricks Secret Scopes
# Profile: L1 | NIST: SC-28
# https://howtoharden.com/guides/databricks/#41-use-databricks-secret-scopes
# =============================================================================

# HTH Guide Excerpt: begin sdk-use-secrets-in-notebook
# Access secrets in notebook
db_password = dbutils.secrets.get(scope="production-secrets", key="db-password")

# Secret is redacted in logs
print(db_password)  # Shows [REDACTED]
# HTH Guide Excerpt: end sdk-use-secrets-in-notebook
