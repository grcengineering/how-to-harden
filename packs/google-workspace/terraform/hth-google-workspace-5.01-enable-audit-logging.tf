# =============================================================================
# HTH Google Workspace Control 5.1: Enable Audit Logging and Investigation Tool
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.2, NIST AU-2/AU-3/AU-6, CIS Google Workspace 5.1
# Source: https://howtoharden.com/guides/google-workspace/#51-enable-audit-logging-and-investigation-tool
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Google Workspace audit logs are enabled by default.  This control
# ensures long-term retention via BigQuery export, creates alert
# notification groups, and sets up the GCP infrastructure for log
# analysis.

# BigQuery dataset for long-term audit log retention
resource "google_bigquery_dataset" "audit_logs" {
  count = var.gcp_project_id != "" ? 1 : 0

  dataset_id    = var.bigquery_dataset_id
  project       = var.gcp_project_id
  friendly_name = "Google Workspace Audit Logs"
  description   = "HTH 5.1 -- Long-term retention of Google Workspace audit logs"
  location      = "US"

  default_table_expiration_ms = var.log_retention_days * 24 * 60 * 60 * 1000

  labels = {
    purpose    = "security-audit"
    managed_by = "terraform"
    hth        = "5-01"
  }
}

# IAM binding to allow Workspace to write logs to BigQuery.
# The Workspace service account must have BigQuery Data Editor access.
resource "google_bigquery_dataset_iam_member" "workspace_writer" {
  count = var.gcp_project_id != "" ? 1 : 0

  dataset_id = google_bigquery_dataset.audit_logs[0].dataset_id
  project    = var.gcp_project_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.service_account_email}"
}

# Group for security alert notifications
resource "googleworkspace_group" "security_alerts" {
  email       = "security-alerts@${var.primary_domain}"
  name        = "Security Alerts"
  description = "HTH 5.1 -- Receives Google Workspace security alert notifications (suspicious login, gov attack, device compromise)"
}

# Group for admin audit notifications
resource "googleworkspace_group" "admin_audit" {
  email       = "admin-audit@${var.primary_domain}"
  name        = "Admin Audit Notifications"
  description = "HTH 5.1 -- Receives notifications for admin actions (role changes, policy modifications)"
}

# L2: Create a dedicated service account for log analysis with read-only access
resource "google_bigquery_dataset_iam_member" "analyst_reader" {
  count = var.profile_level >= 2 && var.gcp_project_id != "" ? 1 : 0

  dataset_id = google_bigquery_dataset.audit_logs[0].dataset_id
  project    = var.gcp_project_id
  role       = "roles/bigquery.dataViewer"
  member     = "group:security-alerts@${var.primary_domain}"
}

# L2: BigQuery view for failed login attempts (pre-built detection query)
resource "google_bigquery_table" "failed_logins" {
  count = var.profile_level >= 2 && var.gcp_project_id != "" ? 1 : 0

  dataset_id = google_bigquery_dataset.audit_logs[0].dataset_id
  project    = var.gcp_project_id
  table_id   = "vw_failed_logins"

  view {
    query          = <<-SQL
      SELECT
        actor.email,
        COUNT(*) as failed_attempts,
        ARRAY_AGG(DISTINCT ip_address IGNORE NULLS) as source_ips
      FROM `${var.gcp_project_id}.${var.bigquery_dataset_id}.login_logs`
      WHERE event_name = 'login_failure'
        AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
      GROUP BY actor.email
      HAVING failed_attempts > 10
      ORDER BY failed_attempts DESC
    SQL
    use_legacy_sql = false
  }

  labels = {
    purpose    = "security-detection"
    managed_by = "terraform"
    hth        = "5-01"
  }
}

# L2: BigQuery view for external file sharing activity
resource "google_bigquery_table" "external_sharing" {
  count = var.profile_level >= 2 && var.gcp_project_id != "" ? 1 : 0

  dataset_id = google_bigquery_dataset.audit_logs[0].dataset_id
  project    = var.gcp_project_id
  table_id   = "vw_external_sharing"

  view {
    query          = <<-SQL
      SELECT
        actor.email,
        doc_title,
        target_user,
        event_time
      FROM `${var.gcp_project_id}.${var.bigquery_dataset_id}.drive_logs`
      WHERE event_name = 'change_user_access'
        AND target_user NOT LIKE '%@${var.primary_domain}'
        AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
      ORDER BY event_time DESC
    SQL
    use_legacy_sql = false
  }

  labels = {
    purpose    = "security-detection"
    managed_by = "terraform"
    hth        = "5-01"
  }
}
# HTH Guide Excerpt: end terraform
