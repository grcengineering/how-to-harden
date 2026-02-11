use crate::error::HthResult;
use crate::models::{CheckStatus, Control, ControlResult, RemediationStep};
use crate::vendor::VendorProvider;

/// Executes remediation steps for failing controls.
pub struct RemediationEngine;

impl RemediationEngine {
    pub fn new() -> Self {
        Self
    }

    /// Determine which remediation steps should run based on scan results.
    pub fn plan_remediation<'a>(
        &self,
        control: &'a Control,
        scan_result: &ControlResult,
    ) -> Vec<&'a RemediationStep> {
        let remediation = match &control.remediate {
            Some(r) => r,
            None => return Vec::new(),
        };

        remediation
            .api
            .iter()
            .filter(|step| self.should_execute(step, scan_result))
            .collect()
    }

    /// Execute remediation steps against a live vendor API.
    pub async fn execute(
        &self,
        steps: &[&RemediationStep],
        provider: &dyn VendorProvider,
    ) -> HthResult<Vec<RemediationResult>> {
        let mut results = Vec::new();

        for step in steps {
            let result = provider
                .execute_request(step.method, &step.endpoint, step.body.as_ref())
                .await;

            results.push(RemediationResult {
                description: step.description.clone(),
                success: result.is_ok(),
                error: result.err().map(|e| e.to_string()),
            });
        }

        Ok(results)
    }

    /// Check if a remediation step should execute based on its condition.
    fn should_execute(&self, step: &RemediationStep, scan_result: &ControlResult) -> bool {
        let condition = match &step.condition {
            Some(c) => c,
            None => return true, // No condition = always run
        };

        let (negated, check_id) = if let Some(stripped) = condition.strip_prefix('!') {
            (true, stripped)
        } else {
            (false, condition.as_str())
        };

        // Find the referenced check result
        let check_passed = scan_result
            .checks
            .iter()
            .find(|c| c.check_id == check_id)
            .is_some_and(|c| c.status == CheckStatus::Pass);

        if negated {
            !check_passed // Run if check failed
        } else {
            check_passed // Run if check passed
        }
    }
}

impl Default for RemediationEngine {
    fn default() -> Self {
        Self::new()
    }
}

/// Result of a single remediation step.
#[derive(Debug, Clone)]
pub struct RemediationResult {
    pub description: String,
    pub success: bool,
    pub error: Option<String>,
}
