use crate::models::ScanReport;

/// Render a scan report as JSON.
pub fn render_scan_report(report: &ScanReport) -> String {
    serde_json::to_string_pretty(report).unwrap_or_else(|e| format!("{{\"error\": \"{e}\"}}"))
}
