use crate::models::ScanReport;

/// Render a scan report as JSON.
pub fn render_scan_report(report: &ScanReport) -> String {
    serde_json::to_string_pretty(report).unwrap_or_else(|e| format!("{{\"error\": \"{e}\"}}"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::*;
    use chrono::Utc;

    fn make_test_report() -> ScanReport {
        ScanReport {
            vendor: "github".to_string(),
            profile_level: 2,
            timestamp: Utc::now(),
            controls: vec![
                ControlResult {
                    control_id: "gh-1.1".to_string(),
                    title: "Enable MFA".to_string(),
                    severity: Severity::Critical,
                    profile_level: 1,
                    status: ControlStatus::Pass,
                    checks: vec![],
                    compliance: ComplianceMapping::default(),
                },
                ControlResult {
                    control_id: "gh-1.2".to_string(),
                    title: "Branch Protection".to_string(),
                    severity: Severity::High,
                    profile_level: 1,
                    status: ControlStatus::Fail,
                    checks: vec![],
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
    fn json_output_parses_as_valid_json() {
        let report = make_test_report();
        let output = render_scan_report(&report);
        let parsed: serde_json::Value =
            serde_json::from_str(&output).expect("JSON output must be valid JSON");
        assert!(parsed.is_object());
    }

    #[test]
    fn json_output_has_correct_vendor() {
        let report = make_test_report();
        let output = render_scan_report(&report);
        let parsed: serde_json::Value = serde_json::from_str(&output).unwrap();
        assert_eq!(parsed["vendor"], "github");
    }

    #[test]
    fn json_output_has_correct_profile_level() {
        let report = make_test_report();
        let output = render_scan_report(&report);
        let parsed: serde_json::Value = serde_json::from_str(&output).unwrap();
        assert_eq!(parsed["profile_level"], 2);
    }

    #[test]
    fn json_output_controls_array_length_matches() {
        let report = make_test_report();
        let output = render_scan_report(&report);
        let parsed: serde_json::Value = serde_json::from_str(&output).unwrap();
        let controls = parsed["controls"].as_array().unwrap();
        assert_eq!(controls.len(), 2);
    }
}
