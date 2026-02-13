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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::*;
    use chrono::Utc;

    fn make_test_report() -> ScanReport {
        ScanReport {
            vendor: "test".to_string(),
            profile_level: 1,
            timestamp: Utc::now(),
            controls: vec![
                ControlResult {
                    control_id: "t-1.1".to_string(),
                    title: "Pass Control".to_string(),
                    severity: Severity::High,
                    profile_level: 1,
                    status: ControlStatus::Pass,
                    checks: vec![CheckResult {
                        check_id: "c1".to_string(),
                        description: "check".to_string(),
                        status: CheckStatus::Pass,
                        actual: None,
                        expected: true,
                        error: None,
                        duration_ms: 50,
                    }],
                    compliance: ComplianceMapping::default(),
                },
                ControlResult {
                    control_id: "t-1.2".to_string(),
                    title: "Fail Control".to_string(),
                    severity: Severity::Critical,
                    profile_level: 1,
                    status: ControlStatus::Fail,
                    checks: vec![CheckResult {
                        check_id: "c2".to_string(),
                        description: "check".to_string(),
                        status: CheckStatus::Fail,
                        actual: None,
                        expected: true,
                        error: None,
                        duration_ms: 75,
                    }],
                    compliance: ComplianceMapping::default(),
                },
            ],
            summary: ScanSummary {
                total: 2,
                passed: 1,
                failed: 1,
                skipped: 0,
                errors: 0,
            },
        }
    }

    #[test]
    fn csv_has_correct_header_row() {
        let report = make_test_report();
        let output = render_scan_report(&report);
        let first_line = output.lines().next().unwrap();
        assert_eq!(
            first_line,
            "control_id,title,severity,profile_level,status,checks_passed,checks_total"
        );
    }

    #[test]
    fn csv_has_correct_number_of_data_rows() {
        let report = make_test_report();
        let output = render_scan_report(&report);
        let lines: Vec<&str> = output.lines().collect();
        // 1 header + 2 data rows
        assert_eq!(lines.len(), 3);
    }

    #[test]
    fn csv_values_for_pass_status() {
        let report = make_test_report();
        let output = render_scan_report(&report);
        let lines: Vec<&str> = output.lines().collect();
        // First data row should contain PASS
        assert!(lines[1].contains("PASS"));
        assert!(lines[1].contains("\"t-1.1\""));
    }

    #[test]
    fn csv_values_for_fail_status() {
        let report = make_test_report();
        let output = render_scan_report(&report);
        let lines: Vec<&str> = output.lines().collect();
        // Second data row should contain FAIL
        assert!(lines[2].contains("FAIL"));
        assert!(lines[2].contains("\"t-1.2\""));
    }
}
