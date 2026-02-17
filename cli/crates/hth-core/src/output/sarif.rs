use serde_json::json;

use crate::models::{ControlResult, ControlStatus, ScanReport, Severity};

/// Render a scan report as SARIF 2.1.0 JSON.
pub fn render_scan_report(report: &ScanReport) -> String {
    let rules: Vec<serde_json::Value> = report
        .controls
        .iter()
        .map(|c| {
            json!({
                "id": c.control_id,
                "name": c.title,
                "shortDescription": {
                    "text": c.title
                },
                "defaultConfiguration": {
                    "level": severity_to_sarif_level(c.severity)
                },
                "properties": {
                    "severity": c.severity.as_str(),
                    "profileLevel": c.profile_level,
                    "compliance": c.compliance
                }
            })
        })
        .collect();

    let results: Vec<serde_json::Value> = report
        .controls
        .iter()
        .filter(|c| c.status == ControlStatus::Fail || c.status == ControlStatus::Error)
        .map(control_to_sarif_result)
        .collect();

    let sarif = json!({
        "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/main/sarif-2.1/schema/sarif-schema-2.1.0.json",
        "version": "2.1.0",
        "runs": [{
            "tool": {
                "driver": {
                    "name": "hth",
                    "fullName": "How to Harden CLI",
                    "version": env!("CARGO_PKG_VERSION"),
                    "informationUri": "https://howtoharden.com",
                    "rules": rules
                }
            },
            "results": results,
            "invocations": [{
                "executionSuccessful": report.summary.errors == 0,
                "startTimeUtc": report.timestamp.to_rfc3339(),
                "properties": {
                    "vendor": report.vendor,
                    "profileLevel": report.profile_level,
                    "summary": {
                        "total": report.summary.total,
                        "passed": report.summary.passed,
                        "failed": report.summary.failed,
                        "skipped": report.summary.skipped,
                        "errors": report.summary.errors
                    }
                }
            }]
        }]
    });

    serde_json::to_string_pretty(&sarif).unwrap_or_else(|e| format!("{{\"error\": \"{e}\"}}"))
}

fn severity_to_sarif_level(severity: Severity) -> &'static str {
    match severity {
        Severity::Critical | Severity::High => "error",
        Severity::Medium => "warning",
        Severity::Low => "note",
    }
}

fn control_to_sarif_result(control: &ControlResult) -> serde_json::Value {
    let failing_checks: Vec<String> = control
        .checks
        .iter()
        .filter(|c| c.status != crate::models::CheckStatus::Pass)
        .map(|c| c.description.clone())
        .collect();

    json!({
        "ruleId": control.control_id,
        "level": severity_to_sarif_level(control.severity),
        "message": {
            "text": format!(
                "{}: {}",
                control.title,
                failing_checks.join("; ")
            )
        },
        "kind": "fail"
    })
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
                    control_id: "test-1.1".to_string(),
                    title: "Test Control Pass".to_string(),
                    severity: Severity::High,
                    profile_level: 1,
                    status: ControlStatus::Pass,
                    checks: vec![CheckResult {
                        check_id: "check-1".to_string(),
                        description: "A passing check".to_string(),
                        status: CheckStatus::Pass,
                        actual: Some(serde_json::json!(true)),
                        expected: true,
                        error: None,
                        duration_ms: 100,
                    }],
                    compliance: ComplianceMapping::default(),
                },
                ControlResult {
                    control_id: "test-1.2".to_string(),
                    title: "Test Control Fail".to_string(),
                    severity: Severity::Critical,
                    profile_level: 1,
                    status: ControlStatus::Fail,
                    checks: vec![CheckResult {
                        check_id: "check-2".to_string(),
                        description: "A failing check".to_string(),
                        status: CheckStatus::Fail,
                        actual: Some(serde_json::json!(false)),
                        expected: true,
                        error: None,
                        duration_ms: 200,
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

    fn make_all_pass_report() -> ScanReport {
        ScanReport {
            vendor: "test".to_string(),
            profile_level: 1,
            timestamp: Utc::now(),
            controls: vec![ControlResult {
                control_id: "test-1.1".to_string(),
                title: "Test Control Pass".to_string(),
                severity: Severity::High,
                profile_level: 1,
                status: ControlStatus::Pass,
                checks: vec![],
                compliance: ComplianceMapping::default(),
            }],
            summary: ScanSummary {
                total: 1,
                passed: 1,
                failed: 0,
                skipped: 0,
                errors: 0,
            },
        }
    }

    #[test]
    fn sarif_output_parses_as_valid_json() {
        let report = make_test_report();
        let output = render_scan_report(&report);
        let parsed: serde_json::Value =
            serde_json::from_str(&output).expect("SARIF output must be valid JSON");
        assert!(parsed.is_object());
    }

    #[test]
    fn sarif_version_is_2_1_0() {
        let report = make_test_report();
        let output = render_scan_report(&report);
        let parsed: serde_json::Value = serde_json::from_str(&output).unwrap();
        assert_eq!(parsed["version"], "2.1.0");
    }

    #[test]
    fn sarif_has_exactly_one_run() {
        let report = make_test_report();
        let output = render_scan_report(&report);
        let parsed: serde_json::Value = serde_json::from_str(&output).unwrap();
        let runs = parsed["runs"].as_array().expect("runs should be an array");
        assert_eq!(runs.len(), 1);
    }

    #[test]
    fn sarif_tool_driver_name_is_hth() {
        let report = make_test_report();
        let output = render_scan_report(&report);
        let parsed: serde_json::Value = serde_json::from_str(&output).unwrap();
        assert_eq!(parsed["runs"][0]["tool"]["driver"]["name"], "hth");
    }

    #[test]
    fn sarif_results_only_contain_failing_and_error_controls() {
        let report = make_test_report();
        let output = render_scan_report(&report);
        let parsed: serde_json::Value = serde_json::from_str(&output).unwrap();
        let results = parsed["runs"][0]["results"].as_array().unwrap();
        // The report has 1 pass and 1 fail, so only 1 result
        assert_eq!(results.len(), 1);
        assert_eq!(results[0]["ruleId"], "test-1.2");
    }

    #[test]
    fn sarif_all_pass_produces_zero_results() {
        let report = make_all_pass_report();
        let output = render_scan_report(&report);
        let parsed: serde_json::Value = serde_json::from_str(&output).unwrap();
        let results = parsed["runs"][0]["results"].as_array().unwrap();
        assert_eq!(results.len(), 0);
    }
}
