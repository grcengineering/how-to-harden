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
