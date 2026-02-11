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
        .map(|c| control_to_sarif_result(c))
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
