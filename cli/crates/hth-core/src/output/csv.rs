use crate::models::ScanReport;

/// Render a scan report as CSV.
pub fn render_scan_report(report: &ScanReport) -> String {
    let mut output = String::new();

    // Header row
    output.push_str("control_id,title,severity,profile_level,status,checks_passed,checks_total\n");

    for control in &report.controls {
        let checks_passed = control
            .checks
            .iter()
            .filter(|c| c.status == crate::models::CheckStatus::Pass)
            .count();

        output.push_str(&format!(
            "\"{}\",\"{}\",{},{},{},{},{}\n",
            control.control_id,
            control.title.replace('"', "\"\""),
            control.severity,
            control.profile_level,
            control.status,
            checks_passed,
            control.checks.len(),
        ));
    }

    output
}
