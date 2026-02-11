use std::time::Instant;

use crate::models::{
    AuditCheck, CheckResult, CheckStatus, Control, ControlResult, ControlStatus, HttpMethod,
    ScanReport,
};
use crate::vendor::VendorProvider;

use super::jq::JqEvaluator;

/// Executes audit checks against live vendor APIs.
pub struct AuditEngine {
    jq: JqEvaluator,
}

impl AuditEngine {
    pub fn new() -> Self {
        Self {
            jq: JqEvaluator::new(),
        }
    }

    /// Scan all controls for a vendor, filtered by profile level.
    pub async fn scan(
        &self,
        controls: &[Control],
        provider: &dyn VendorProvider,
        profile_level: u8,
    ) -> ScanReport {
        let mut results = Vec::new();

        for control in controls {
            if control.applies_at_level(profile_level) {
                let result = self.audit_control(control, provider).await;
                results.push(result);
            } else {
                results.push(ControlResult {
                    control_id: control.id.clone(),
                    title: control.title.clone(),
                    severity: control.severity,
                    profile_level: control.profile_level,
                    status: ControlStatus::Skip,
                    checks: Vec::new(),
                    compliance: control.compliance.clone(),
                });
            }
        }

        ScanReport::new(provider.vendor_slug().to_string(), profile_level, results)
    }

    /// Run all audit checks for a single control.
    pub async fn audit_control(
        &self,
        control: &Control,
        provider: &dyn VendorProvider,
    ) -> ControlResult {
        let mut checks = Vec::new();
        let mut has_failure = false;
        let mut has_error = false;

        for audit_check in &control.audit {
            let result = self.run_check(audit_check, provider).await;
            match result.status {
                CheckStatus::Fail => has_failure = true,
                CheckStatus::Error => has_error = true,
                CheckStatus::Pass => {}
            }
            checks.push(result);
        }

        let status = if has_error {
            ControlStatus::Error
        } else if has_failure {
            ControlStatus::Fail
        } else {
            ControlStatus::Pass
        };

        ControlResult {
            control_id: control.id.clone(),
            title: control.title.clone(),
            severity: control.severity,
            profile_level: control.profile_level,
            status,
            checks,
            compliance: control.compliance.clone(),
        }
    }

    /// Run a single audit check: call the API, evaluate jq, compare to expected.
    async fn run_check(
        &self,
        check: &AuditCheck,
        provider: &dyn VendorProvider,
    ) -> CheckResult {
        let start = Instant::now();

        // Enforce GET-only for audit checks
        if check.api.method != HttpMethod::GET {
            return CheckResult {
                check_id: check.id.clone(),
                description: check.description.clone(),
                status: CheckStatus::Error,
                actual: None,
                expected: check.expected,
                error: Some(format!(
                    "Audit check uses {} method — only GET is allowed in scan mode",
                    check.api.method
                )),
                duration_ms: start.elapsed().as_millis() as u64,
            };
        }

        // Execute the API call
        let response = match provider
            .execute_request(check.api.method, &check.api.endpoint, None)
            .await
        {
            Ok(json) => json,
            Err(e) => {
                return CheckResult {
                    check_id: check.id.clone(),
                    description: check.description.clone(),
                    status: CheckStatus::Error,
                    actual: None,
                    expected: check.expected,
                    error: Some(format!("API call failed: {e}")),
                    duration_ms: start.elapsed().as_millis() as u64,
                };
            }
        };

        // Evaluate the jq expression
        match self.jq.check(&check.api.check, &response, check.expected) {
            Ok(true) => CheckResult {
                check_id: check.id.clone(),
                description: check.description.clone(),
                status: CheckStatus::Pass,
                actual: Some(serde_json::Value::Bool(check.expected)),
                expected: check.expected,
                error: None,
                duration_ms: start.elapsed().as_millis() as u64,
            },
            Ok(false) => CheckResult {
                check_id: check.id.clone(),
                description: check.description.clone(),
                status: CheckStatus::Fail,
                actual: Some(serde_json::Value::Bool(!check.expected)),
                expected: check.expected,
                error: None,
                duration_ms: start.elapsed().as_millis() as u64,
            },
            Err(e) => CheckResult {
                check_id: check.id.clone(),
                description: check.description.clone(),
                status: CheckStatus::Error,
                actual: None,
                expected: check.expected,
                error: Some(format!("jq evaluation failed: {e}")),
                duration_ms: start.elapsed().as_millis() as u64,
            },
        }
    }
}

impl Default for AuditEngine {
    fn default() -> Self {
        Self::new()
    }
}
