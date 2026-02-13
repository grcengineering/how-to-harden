use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use super::control::{ComplianceMapping, Severity};

/// Complete scan report for a vendor.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScanReport {
    pub vendor: String,
    pub profile_level: u8,
    pub timestamp: DateTime<Utc>,
    pub controls: Vec<ControlResult>,
    pub summary: ScanSummary,
}

impl ScanReport {
    /// Build a report from control results.
    pub fn new(vendor: String, profile_level: u8, controls: Vec<ControlResult>) -> Self {
        let summary = ScanSummary::from_results(&controls);
        Self {
            vendor,
            profile_level,
            timestamp: Utc::now(),
            controls,
            summary,
        }
    }

    /// Returns the exit code: 0 if all pass, 1 if any fail.
    pub fn exit_code(&self) -> i32 {
        if self.summary.failed > 0 || self.summary.errors > 0 {
            1
        } else {
            0
        }
    }
}

/// Result for a single control.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ControlResult {
    pub control_id: String,
    pub title: String,
    pub severity: Severity,
    pub profile_level: u8,
    pub status: ControlStatus,
    pub checks: Vec<CheckResult>,
    pub compliance: ComplianceMapping,
}

/// Result for a single audit check within a control.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CheckResult {
    pub check_id: String,
    pub description: String,
    pub status: CheckStatus,
    pub actual: Option<serde_json::Value>,
    pub expected: bool,
    pub error: Option<String>,
    pub duration_ms: u64,
}

/// Status of a control (aggregate of its checks).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ControlStatus {
    Pass,
    Fail,
    Skip,
    Error,
}

impl std::fmt::Display for ControlStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ControlStatus::Pass => write!(f, "PASS"),
            ControlStatus::Fail => write!(f, "FAIL"),
            ControlStatus::Skip => write!(f, "SKIP"),
            ControlStatus::Error => write!(f, "ERROR"),
        }
    }
}

/// Status of an individual check.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum CheckStatus {
    Pass,
    Fail,
    Error,
}

impl std::fmt::Display for CheckStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            CheckStatus::Pass => write!(f, "PASS"),
            CheckStatus::Fail => write!(f, "FAIL"),
            CheckStatus::Error => write!(f, "ERROR"),
        }
    }
}

/// Summary statistics for a scan.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScanSummary {
    pub total: usize,
    pub passed: usize,
    pub failed: usize,
    pub skipped: usize,
    pub errors: usize,
}

impl ScanSummary {
    pub fn from_results(controls: &[ControlResult]) -> Self {
        let mut summary = Self {
            total: controls.len(),
            passed: 0,
            failed: 0,
            skipped: 0,
            errors: 0,
        };
        for control in controls {
            match control.status {
                ControlStatus::Pass => summary.passed += 1,
                ControlStatus::Fail => summary.failed += 1,
                ControlStatus::Skip => summary.skipped += 1,
                ControlStatus::Error => summary.errors += 1,
            }
        }
        summary
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Helper to build a ControlResult with a given status.
    fn make_control_result(id: &str, status: ControlStatus) -> ControlResult {
        ControlResult {
            control_id: id.to_string(),
            title: format!("Control {id}"),
            severity: Severity::High,
            profile_level: 1,
            status,
            checks: vec![],
            compliance: ComplianceMapping::default(),
        }
    }

    // --- ScanSummary::from_results ---

    #[test]
    fn from_results_counts_correctly() {
        let controls = vec![
            make_control_result("c1", ControlStatus::Pass),
            make_control_result("c2", ControlStatus::Pass),
            make_control_result("c3", ControlStatus::Fail),
            make_control_result("c4", ControlStatus::Skip),
            make_control_result("c5", ControlStatus::Error),
        ];
        let summary = ScanSummary::from_results(&controls);
        assert_eq!(summary.total, 5);
        assert_eq!(summary.passed, 2);
        assert_eq!(summary.failed, 1);
        assert_eq!(summary.skipped, 1);
        assert_eq!(summary.errors, 1);
    }

    #[test]
    fn from_results_empty_controls() {
        let summary = ScanSummary::from_results(&[]);
        assert_eq!(summary.total, 0);
        assert_eq!(summary.passed, 0);
        assert_eq!(summary.failed, 0);
        assert_eq!(summary.skipped, 0);
        assert_eq!(summary.errors, 0);
    }

    // --- ScanReport::exit_code ---

    #[test]
    fn exit_code_zero_when_all_pass() {
        let report = ScanReport::new(
            "test".to_string(),
            1,
            vec![
                make_control_result("c1", ControlStatus::Pass),
                make_control_result("c2", ControlStatus::Pass),
            ],
        );
        assert_eq!(report.exit_code(), 0);
    }

    #[test]
    fn exit_code_one_when_any_fail() {
        let report = ScanReport::new(
            "test".to_string(),
            1,
            vec![
                make_control_result("c1", ControlStatus::Pass),
                make_control_result("c2", ControlStatus::Fail),
            ],
        );
        assert_eq!(report.exit_code(), 1);
    }

    #[test]
    fn exit_code_one_when_any_errors() {
        let report = ScanReport::new(
            "test".to_string(),
            1,
            vec![
                make_control_result("c1", ControlStatus::Pass),
                make_control_result("c2", ControlStatus::Error),
            ],
        );
        assert_eq!(report.exit_code(), 1);
    }

    #[test]
    fn exit_code_zero_with_skips_only() {
        let report = ScanReport::new(
            "test".to_string(),
            1,
            vec![
                make_control_result("c1", ControlStatus::Pass),
                make_control_result("c2", ControlStatus::Skip),
            ],
        );
        assert_eq!(report.exit_code(), 0);
    }

    // --- ScanReport::new ---

    #[test]
    fn new_produces_correct_summary() {
        let report = ScanReport::new(
            "github".to_string(),
            2,
            vec![
                make_control_result("g1", ControlStatus::Pass),
                make_control_result("g2", ControlStatus::Fail),
                make_control_result("g3", ControlStatus::Fail),
            ],
        );
        assert_eq!(report.vendor, "github");
        assert_eq!(report.profile_level, 2);
        assert_eq!(report.summary.total, 3);
        assert_eq!(report.summary.passed, 1);
        assert_eq!(report.summary.failed, 2);
    }

    // --- ControlStatus::Display ---

    #[test]
    fn control_status_display_all_variants() {
        assert_eq!(format!("{}", ControlStatus::Pass), "PASS");
        assert_eq!(format!("{}", ControlStatus::Fail), "FAIL");
        assert_eq!(format!("{}", ControlStatus::Skip), "SKIP");
        assert_eq!(format!("{}", ControlStatus::Error), "ERROR");
    }

    // --- CheckStatus::Display ---

    #[test]
    fn check_status_display_all_variants() {
        assert_eq!(format!("{}", CheckStatus::Pass), "PASS");
        assert_eq!(format!("{}", CheckStatus::Fail), "FAIL");
        assert_eq!(format!("{}", CheckStatus::Error), "ERROR");
    }

    // --- Serde round-trip: ControlStatus ---

    #[test]
    fn control_status_serde_roundtrip() {
        for status in [ControlStatus::Pass, ControlStatus::Fail, ControlStatus::Skip, ControlStatus::Error] {
            let json = serde_json::to_string(&status).unwrap();
            let deserialized: ControlStatus = serde_json::from_str(&json).unwrap();
            assert_eq!(deserialized, status);
        }
    }

    #[test]
    fn control_status_serializes_to_lowercase() {
        assert_eq!(serde_json::to_string(&ControlStatus::Pass).unwrap(), "\"pass\"");
        assert_eq!(serde_json::to_string(&ControlStatus::Fail).unwrap(), "\"fail\"");
        assert_eq!(serde_json::to_string(&ControlStatus::Skip).unwrap(), "\"skip\"");
        assert_eq!(serde_json::to_string(&ControlStatus::Error).unwrap(), "\"error\"");
    }
}
