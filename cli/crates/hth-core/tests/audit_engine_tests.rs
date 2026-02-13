//! Integration tests for the AuditEngine.
//!
//! These tests verify that the audit engine correctly:
//! - Calls vendor APIs via the VendorProvider trait
//! - Evaluates jq expressions against API responses
//! - Produces correct pass/fail/error/skip results
//! - Filters controls by profile level
//! - Rejects non-GET methods in scan mode
//! - Generates accurate scan report summaries
//!
//! All tests use a MockVendorProvider that returns predefined JSON
//! responses, requiring zero network access.

use std::collections::HashMap;
use std::sync::Mutex;

use async_trait::async_trait;
use serde_json::json;

use hth_core::engine::AuditEngine;
use hth_core::error::{HthError, HthResult};
use hth_core::models::{
    AuditCheck, CheckStatus, ComplianceMapping, Control, ControlStatus, HttpMethod,
    Severity,
};
use hth_core::models::control::ApiCall;
use hth_core::vendor::VendorProvider;

// ---------------------------------------------------------------------------
// MockVendorProvider
// ---------------------------------------------------------------------------

/// A test double that implements VendorProvider with canned responses
/// and records every API call the engine makes.
struct MockVendorProvider {
    slug: String,
    responses: HashMap<String, serde_json::Value>,
    calls: Mutex<Vec<(HttpMethod, String)>>,
}

impl MockVendorProvider {
    fn new(slug: &str) -> Self {
        Self {
            slug: slug.to_string(),
            responses: HashMap::new(),
            calls: Mutex::new(Vec::new()),
        }
    }

    fn with_response(mut self, endpoint: &str, response: serde_json::Value) -> Self {
        self.responses.insert(endpoint.to_string(), response);
        self
    }

    fn call_count(&self) -> usize {
        self.calls.lock().unwrap().len()
    }

    fn calls(&self) -> Vec<(HttpMethod, String)> {
        self.calls.lock().unwrap().clone()
    }
}

#[async_trait]
impl VendorProvider for MockVendorProvider {
    fn vendor_slug(&self) -> &str {
        &self.slug
    }

    fn display_name(&self) -> &str {
        &self.slug
    }

    fn resolve_url(&self, endpoint: &str) -> String {
        format!("https://mock.api{endpoint}")
    }

    fn auth_headers(&self) -> Vec<(String, String)> {
        vec![("Authorization".into(), "Bearer mock-token".into())]
    }

    async fn execute_request(
        &self,
        method: HttpMethod,
        endpoint: &str,
        _body: Option<&serde_json::Value>,
    ) -> HthResult<serde_json::Value> {
        self.calls
            .lock()
            .unwrap()
            .push((method, endpoint.to_string()));
        match self.responses.get(endpoint) {
            Some(response) => Ok(response.clone()),
            None => Err(HthError::HttpStatus {
                method: format!("{method}"),
                url: self.resolve_url(endpoint),
                status: 404,
                body: "Not found".to_string(),
            }),
        }
    }

    async fn validate_credentials(&self) -> HthResult<()> {
        Ok(())
    }

    fn terraform_provider_block(&self) -> String {
        String::new()
    }
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Build a minimal Control with a single audit check.
fn make_test_control(id: &str, level: u8, endpoint: &str, check: &str) -> Control {
    Control {
        id: id.to_string(),
        vendor: "test".to_string(),
        title: format!("Test Control {id}"),
        section: "1.1".to_string(),
        profile_level: level,
        severity: Severity::High,
        guide_url: None,
        description: "Test control".to_string(),
        compliance: ComplianceMapping::default(),
        audit: vec![AuditCheck {
            id: format!("{id}-check"),
            description: "Test check".to_string(),
            api: ApiCall {
                method: HttpMethod::GET,
                endpoint: endpoint.to_string(),
                check: check.to_string(),
                body: None,
            },
            expected: true,
        }],
        remediate: None,
        tags: vec![],
    }
}

/// Build a Control with multiple audit checks.
fn make_multi_check_control(
    id: &str,
    level: u8,
    checks: Vec<(&str, &str, &str)>,
) -> Control {
    let audit = checks
        .into_iter()
        .enumerate()
        .map(|(i, (check_id, endpoint, expr))| AuditCheck {
            id: check_id.to_string(),
            description: format!("Check {i}"),
            api: ApiCall {
                method: HttpMethod::GET,
                endpoint: endpoint.to_string(),
                check: expr.to_string(),
                body: None,
            },
            expected: true,
        })
        .collect();

    Control {
        id: id.to_string(),
        vendor: "test".to_string(),
        title: format!("Test Control {id}"),
        section: "1.1".to_string(),
        profile_level: level,
        severity: Severity::High,
        guide_url: None,
        description: "Test control with multiple checks".to_string(),
        compliance: ComplianceMapping::default(),
        audit,
        remediate: None,
        tags: vec![],
    }
}

/// Build a Control with a specific HTTP method on the audit check.
fn make_control_with_method(id: &str, method: HttpMethod) -> Control {
    Control {
        id: id.to_string(),
        vendor: "test".to_string(),
        title: format!("Test Control {id}"),
        section: "1.1".to_string(),
        profile_level: 1,
        severity: Severity::High,
        guide_url: None,
        description: "Test control".to_string(),
        compliance: ComplianceMapping::default(),
        audit: vec![AuditCheck {
            id: format!("{id}-check"),
            description: "Test check".to_string(),
            api: ApiCall {
                method,
                endpoint: "/api/v1/test".to_string(),
                check: ".enabled == true".to_string(),
                body: None,
            },
            expected: true,
        }],
        remediate: None,
        tags: vec![],
    }
}

// ===========================================================================
// 1. Basic Pass / Fail Tests
// ===========================================================================

#[tokio::test]
async fn test_audit_control_passes_when_check_matches() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("github")
        .with_response("/orgs/test", json!({"two_factor_requirement_enabled": true}));

    let control = make_test_control(
        "gh-1.1",
        1,
        "/orgs/test",
        ".two_factor_requirement_enabled == true",
    );

    let result = engine.audit_control(&control, &provider).await;

    assert_eq!(result.status, ControlStatus::Pass);
    assert_eq!(result.checks.len(), 1);
    assert_eq!(result.checks[0].status, CheckStatus::Pass);
}

#[tokio::test]
async fn test_audit_control_fails_when_check_doesnt_match() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("github")
        .with_response("/orgs/test", json!({"two_factor_requirement_enabled": false}));

    let control = make_test_control(
        "gh-1.1",
        1,
        "/orgs/test",
        ".two_factor_requirement_enabled == true",
    );

    let result = engine.audit_control(&control, &provider).await;

    assert_eq!(result.status, ControlStatus::Fail);
    assert_eq!(result.checks.len(), 1);
    assert_eq!(result.checks[0].status, CheckStatus::Fail);
}

// ===========================================================================
// 2. Multiple Checks per Control
// ===========================================================================

#[tokio::test]
async fn test_control_with_multiple_checks_all_pass() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("github")
        .with_response("/orgs/test", json!({"two_factor_requirement_enabled": true}))
        .with_response(
            "/orgs/test/members?filter=2fa_disabled",
            json!([]),
        );

    let control = make_multi_check_control(
        "gh-1.1",
        1,
        vec![
            (
                "2fa-enabled",
                "/orgs/test",
                ".two_factor_requirement_enabled == true",
            ),
            (
                "no-members-without-2fa",
                "/orgs/test/members?filter=2fa_disabled",
                ". | length == 0",
            ),
        ],
    );

    let result = engine.audit_control(&control, &provider).await;

    assert_eq!(result.status, ControlStatus::Pass);
    assert_eq!(result.checks.len(), 2);
    assert_eq!(result.checks[0].status, CheckStatus::Pass);
    assert_eq!(result.checks[1].status, CheckStatus::Pass);
}

#[tokio::test]
async fn test_control_with_multiple_checks_one_fails() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("github")
        .with_response("/orgs/test", json!({"two_factor_requirement_enabled": true}))
        .with_response(
            "/orgs/test/members?filter=2fa_disabled",
            json!([{"login": "baduser"}]),
        );

    let control = make_multi_check_control(
        "gh-1.1",
        1,
        vec![
            (
                "2fa-enabled",
                "/orgs/test",
                ".two_factor_requirement_enabled == true",
            ),
            (
                "no-members-without-2fa",
                "/orgs/test/members?filter=2fa_disabled",
                ". | length == 0",
            ),
        ],
    );

    let result = engine.audit_control(&control, &provider).await;

    // Overall control should fail because one check failed
    assert_eq!(result.status, ControlStatus::Fail);
    assert_eq!(result.checks.len(), 2);
    assert_eq!(result.checks[0].status, CheckStatus::Pass);
    assert_eq!(result.checks[1].status, CheckStatus::Fail);
}

// ===========================================================================
// 3. Error Handling
// ===========================================================================

#[tokio::test]
async fn test_audit_control_error_on_api_failure() {
    let engine = AuditEngine::new();
    // Provider with NO response registered for the endpoint -> 404
    let provider = MockVendorProvider::new("github");

    let control = make_test_control(
        "gh-1.1",
        1,
        "/orgs/nonexistent",
        ".two_factor_requirement_enabled == true",
    );

    let result = engine.audit_control(&control, &provider).await;

    assert_eq!(result.status, ControlStatus::Error);
    assert_eq!(result.checks.len(), 1);
    assert_eq!(result.checks[0].status, CheckStatus::Error);
    assert!(result.checks[0].error.is_some());
    assert!(
        result.checks[0]
            .error
            .as_ref()
            .unwrap()
            .contains("API call failed"),
        "Error message should mention API call failure, got: {}",
        result.checks[0].error.as_ref().unwrap()
    );
}

#[tokio::test]
async fn test_audit_rejects_non_get_post_method() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test")
        .with_response("/api/v1/test", json!({"enabled": true}));

    let control = make_control_with_method("post-ctrl", HttpMethod::POST);
    let result = engine.audit_control(&control, &provider).await;

    assert_eq!(result.status, ControlStatus::Error);
    assert_eq!(result.checks[0].status, CheckStatus::Error);
    assert!(
        result.checks[0]
            .error
            .as_ref()
            .unwrap()
            .contains("only GET is allowed"),
        "Error should mention only GET is allowed, got: {}",
        result.checks[0].error.as_ref().unwrap()
    );
}

#[tokio::test]
async fn test_audit_rejects_non_get_put_method() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test")
        .with_response("/api/v1/test", json!({"enabled": true}));

    let control = make_control_with_method("put-ctrl", HttpMethod::PUT);
    let result = engine.audit_control(&control, &provider).await;

    assert_eq!(result.status, ControlStatus::Error);
    assert_eq!(result.checks[0].status, CheckStatus::Error);
    assert!(
        result.checks[0]
            .error
            .as_ref()
            .unwrap()
            .contains("only GET is allowed"),
    );
}

#[tokio::test]
async fn test_audit_rejects_non_get_delete_method() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test")
        .with_response("/api/v1/test", json!({"enabled": true}));

    let control = make_control_with_method("delete-ctrl", HttpMethod::DELETE);
    let result = engine.audit_control(&control, &provider).await;

    assert_eq!(result.status, ControlStatus::Error);
    assert_eq!(result.checks[0].status, CheckStatus::Error);
}

#[tokio::test]
async fn test_audit_rejects_non_get_patch_method() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test")
        .with_response("/api/v1/test", json!({"enabled": true}));

    let control = make_control_with_method("patch-ctrl", HttpMethod::PATCH);
    let result = engine.audit_control(&control, &provider).await;

    assert_eq!(result.status, ControlStatus::Error);
    assert_eq!(result.checks[0].status, CheckStatus::Error);
}

// ===========================================================================
// 4. Profile Level Filtering
// ===========================================================================

#[tokio::test]
async fn test_scan_filters_by_profile_level_l1_only() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test")
        .with_response("/api/l1", json!({"enabled": true}))
        .with_response("/api/l2", json!({"enabled": true}))
        .with_response("/api/l3", json!({"enabled": true}));

    let controls = vec![
        make_test_control("ctrl-l1", 1, "/api/l1", ".enabled == true"),
        make_test_control("ctrl-l2", 2, "/api/l2", ".enabled == true"),
        make_test_control("ctrl-l3", 3, "/api/l3", ".enabled == true"),
    ];

    // Scan at L1: only L1 control should run
    let report = engine.scan(&controls, &provider, 1).await;

    assert_eq!(report.controls.len(), 3);
    assert_eq!(report.summary.total, 3);
    assert_eq!(report.summary.passed, 1);
    assert_eq!(report.summary.skipped, 2);

    // Verify statuses individually
    assert_eq!(report.controls[0].status, ControlStatus::Pass);
    assert_eq!(report.controls[1].status, ControlStatus::Skip);
    assert_eq!(report.controls[2].status, ControlStatus::Skip);
}

#[tokio::test]
async fn test_scan_l2_includes_l1_controls() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test")
        .with_response("/api/l1", json!({"enabled": true}))
        .with_response("/api/l2", json!({"enabled": true}))
        .with_response("/api/l3", json!({"enabled": true}));

    let controls = vec![
        make_test_control("ctrl-l1", 1, "/api/l1", ".enabled == true"),
        make_test_control("ctrl-l2", 2, "/api/l2", ".enabled == true"),
        make_test_control("ctrl-l3", 3, "/api/l3", ".enabled == true"),
    ];

    // Scan at L2: L1 and L2 run, L3 is SKIP
    let report = engine.scan(&controls, &provider, 2).await;

    assert_eq!(report.summary.passed, 2);
    assert_eq!(report.summary.skipped, 1);

    assert_eq!(report.controls[0].status, ControlStatus::Pass);
    assert_eq!(report.controls[1].status, ControlStatus::Pass);
    assert_eq!(report.controls[2].status, ControlStatus::Skip);
}

#[tokio::test]
async fn test_scan_l3_includes_all() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test")
        .with_response("/api/l1", json!({"enabled": true}))
        .with_response("/api/l2", json!({"enabled": true}))
        .with_response("/api/l3", json!({"enabled": true}));

    let controls = vec![
        make_test_control("ctrl-l1", 1, "/api/l1", ".enabled == true"),
        make_test_control("ctrl-l2", 2, "/api/l2", ".enabled == true"),
        make_test_control("ctrl-l3", 3, "/api/l3", ".enabled == true"),
    ];

    // Scan at L3: all controls run
    let report = engine.scan(&controls, &provider, 3).await;

    assert_eq!(report.summary.passed, 3);
    assert_eq!(report.summary.skipped, 0);

    assert_eq!(report.controls[0].status, ControlStatus::Pass);
    assert_eq!(report.controls[1].status, ControlStatus::Pass);
    assert_eq!(report.controls[2].status, ControlStatus::Pass);
}

// ===========================================================================
// 5. jq Expression Tests (real GitHub pack expressions)
// ===========================================================================

#[tokio::test]
async fn test_github_2fa_check_expression() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("github").with_response(
        "/orgs/acme",
        json!({
            "login": "acme",
            "id": 12345,
            "two_factor_requirement_enabled": true,
            "default_repository_permission": "read",
            "members_can_create_repositories": false
        }),
    );

    let control = make_test_control(
        "gh-2fa",
        1,
        "/orgs/acme",
        ".two_factor_requirement_enabled == true",
    );

    let result = engine.audit_control(&control, &provider).await;
    assert_eq!(result.status, ControlStatus::Pass);
}

#[tokio::test]
async fn test_github_2fa_disabled_expression() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("github").with_response(
        "/orgs/acme",
        json!({
            "login": "acme",
            "two_factor_requirement_enabled": false
        }),
    );

    let control = make_test_control(
        "gh-2fa",
        1,
        "/orgs/acme",
        ".two_factor_requirement_enabled == true",
    );

    let result = engine.audit_control(&control, &provider).await;
    assert_eq!(result.status, ControlStatus::Fail);
}

#[tokio::test]
async fn test_github_members_without_2fa_check_passes() {
    let engine = AuditEngine::new();
    // Empty array = no members without 2FA = good
    let provider = MockVendorProvider::new("github")
        .with_response("/orgs/acme/members?filter=2fa_disabled", json!([]));

    let control = make_test_control(
        "gh-2fa-members",
        1,
        "/orgs/acme/members?filter=2fa_disabled",
        ". | length == 0",
    );

    let result = engine.audit_control(&control, &provider).await;
    assert_eq!(result.status, ControlStatus::Pass);
}

#[tokio::test]
async fn test_github_members_without_2fa_check_fails() {
    let engine = AuditEngine::new();
    // Non-empty array = members without 2FA exist = bad
    let provider = MockVendorProvider::new("github").with_response(
        "/orgs/acme/members?filter=2fa_disabled",
        json!([{"login": "baduser", "id": 99}]),
    );

    let control = make_test_control(
        "gh-2fa-members",
        1,
        "/orgs/acme/members?filter=2fa_disabled",
        ". | length == 0",
    );

    let result = engine.audit_control(&control, &provider).await;
    assert_eq!(result.status, ControlStatus::Fail);
}

#[tokio::test]
async fn test_github_default_permissions_check_read() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("github").with_response(
        "/orgs/acme",
        json!({"default_repository_permission": "read"}),
    );

    let control = make_test_control(
        "gh-perms",
        1,
        "/orgs/acme",
        r#".default_repository_permission == "none" or .default_repository_permission == "read""#,
    );

    let result = engine.audit_control(&control, &provider).await;
    assert_eq!(result.status, ControlStatus::Pass);
}

#[tokio::test]
async fn test_github_default_permissions_check_none() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("github").with_response(
        "/orgs/acme",
        json!({"default_repository_permission": "none"}),
    );

    let control = make_test_control(
        "gh-perms",
        1,
        "/orgs/acme",
        r#".default_repository_permission == "none" or .default_repository_permission == "read""#,
    );

    let result = engine.audit_control(&control, &provider).await;
    assert_eq!(result.status, ControlStatus::Pass);
}

#[tokio::test]
async fn test_github_default_permissions_check_write_fails() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("github").with_response(
        "/orgs/acme",
        json!({"default_repository_permission": "write"}),
    );

    let control = make_test_control(
        "gh-perms",
        1,
        "/orgs/acme",
        r#".default_repository_permission == "none" or .default_repository_permission == "read""#,
    );

    let result = engine.audit_control(&control, &provider).await;
    assert_eq!(result.status, ControlStatus::Fail);
}

#[tokio::test]
async fn test_jq_array_filter_with_select() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("okta").with_response(
        "/api/v1/authenticators",
        json!([
            {"key": "webauthn", "status": "ACTIVE"},
            {"key": "totp", "status": "ACTIVE"},
            {"key": "sms", "status": "INACTIVE"}
        ]),
    );

    let control = make_test_control(
        "okta-fido2",
        1,
        "/api/v1/authenticators",
        r#"[.[] | select(.key == "webauthn" and .status == "ACTIVE")] | length > 0"#,
    );

    let result = engine.audit_control(&control, &provider).await;
    assert_eq!(result.status, ControlStatus::Pass);
}

#[tokio::test]
async fn test_jq_array_filter_no_match() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("okta").with_response(
        "/api/v1/authenticators",
        json!([
            {"key": "totp", "status": "ACTIVE"},
            {"key": "sms", "status": "INACTIVE"}
        ]),
    );

    let control = make_test_control(
        "okta-fido2",
        1,
        "/api/v1/authenticators",
        r#"[.[] | select(.key == "webauthn" and .status == "ACTIVE")] | length > 0"#,
    );

    let result = engine.audit_control(&control, &provider).await;
    assert_eq!(result.status, ControlStatus::Fail);
}

// ===========================================================================
// 6. Report Summary Tests
// ===========================================================================

#[tokio::test]
async fn test_scan_report_summary_counts() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test")
        .with_response("/api/pass", json!({"enabled": true}))
        .with_response("/api/fail", json!({"enabled": false}));

    let controls = vec![
        make_test_control("pass-1", 1, "/api/pass", ".enabled == true"),
        make_test_control("pass-2", 1, "/api/pass", ".enabled == true"),
        make_test_control("fail-1", 1, "/api/fail", ".enabled == true"),
        make_test_control("skip-1", 3, "/api/pass", ".enabled == true"), // L3 at L1 scan -> SKIP
    ];

    let report = engine.scan(&controls, &provider, 1).await;

    assert_eq!(report.summary.total, 4);
    assert_eq!(report.summary.passed, 2);
    assert_eq!(report.summary.failed, 1);
    assert_eq!(report.summary.skipped, 1);
    assert_eq!(report.summary.errors, 0);
}

#[tokio::test]
async fn test_scan_report_exit_code_zero_on_all_pass() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test")
        .with_response("/api/ok", json!({"enabled": true}));

    let controls = vec![
        make_test_control("pass-1", 1, "/api/ok", ".enabled == true"),
        make_test_control("pass-2", 1, "/api/ok", ".enabled == true"),
    ];

    let report = engine.scan(&controls, &provider, 1).await;
    assert_eq!(report.exit_code(), 0);
}

#[tokio::test]
async fn test_scan_report_exit_code_zero_with_skips() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test")
        .with_response("/api/ok", json!({"enabled": true}));

    let controls = vec![
        make_test_control("pass-1", 1, "/api/ok", ".enabled == true"),
        make_test_control("skip-1", 3, "/api/ok", ".enabled == true"), // Skipped at L1
    ];

    let report = engine.scan(&controls, &provider, 1).await;
    assert_eq!(report.exit_code(), 0);
}

#[tokio::test]
async fn test_scan_report_exit_code_one_on_any_fail() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test")
        .with_response("/api/ok", json!({"enabled": true}))
        .with_response("/api/bad", json!({"enabled": false}));

    let controls = vec![
        make_test_control("pass-1", 1, "/api/ok", ".enabled == true"),
        make_test_control("fail-1", 1, "/api/bad", ".enabled == true"),
    ];

    let report = engine.scan(&controls, &provider, 1).await;
    assert_eq!(report.exit_code(), 1);
}

#[tokio::test]
async fn test_scan_report_exit_code_one_on_error() {
    let engine = AuditEngine::new();
    // No response registered -> 404 error
    let provider = MockVendorProvider::new("test");

    let controls = vec![
        make_test_control("err-1", 1, "/api/missing", ".enabled == true"),
    ];

    let report = engine.scan(&controls, &provider, 1).await;
    assert_eq!(report.exit_code(), 1);
    assert_eq!(report.summary.errors, 1);
}

#[tokio::test]
async fn test_scan_report_metadata() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("github")
        .with_response("/api/ok", json!({"enabled": true}));

    let controls = vec![
        make_test_control("gh-1", 1, "/api/ok", ".enabled == true"),
    ];

    let report = engine.scan(&controls, &provider, 2).await;

    assert_eq!(report.vendor, "github");
    assert_eq!(report.profile_level, 2);
    assert_eq!(report.controls.len(), 1);
}

// ===========================================================================
// 7. Call Recording Tests
// ===========================================================================

#[tokio::test]
async fn test_audit_makes_correct_api_calls() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("github")
        .with_response("/orgs/acme", json!({"two_factor_requirement_enabled": true}))
        .with_response(
            "/orgs/acme/members?filter=2fa_disabled",
            json!([]),
        );

    let control = make_multi_check_control(
        "gh-2fa",
        1,
        vec![
            ("check-org", "/orgs/acme", ".two_factor_requirement_enabled == true"),
            ("check-members", "/orgs/acme/members?filter=2fa_disabled", ". | length == 0"),
        ],
    );

    let _result = engine.audit_control(&control, &provider).await;

    // Verify the engine made exactly 2 API calls
    assert_eq!(provider.call_count(), 2);

    let calls = provider.calls();
    assert_eq!(calls[0], (HttpMethod::GET, "/orgs/acme".to_string()));
    assert_eq!(
        calls[1],
        (
            HttpMethod::GET,
            "/orgs/acme/members?filter=2fa_disabled".to_string()
        )
    );
}

#[tokio::test]
async fn test_skipped_controls_dont_make_api_calls() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test")
        .with_response("/api/l2", json!({"enabled": true}));

    let controls = vec![
        make_test_control("ctrl-l2", 2, "/api/l2", ".enabled == true"),
    ];

    // Scan at L1: L2 control should be skipped, no API calls
    let report = engine.scan(&controls, &provider, 1).await;

    assert_eq!(report.controls[0].status, ControlStatus::Skip);
    assert_eq!(provider.call_count(), 0, "Skipped controls must not make API calls");
}

#[tokio::test]
async fn test_non_get_methods_dont_execute_api_call() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test")
        .with_response("/api/v1/test", json!({"enabled": true}));

    let control = make_control_with_method("post-ctrl", HttpMethod::POST);
    let _result = engine.audit_control(&control, &provider).await;

    // POST should be rejected before the API call is made
    assert_eq!(
        provider.call_count(),
        0,
        "Non-GET methods should be rejected before making an API call"
    );
}

#[tokio::test]
async fn test_single_api_call_per_check() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test")
        .with_response("/api/endpoint", json!({"status": "active"}));

    let controls = vec![
        make_test_control("ctrl-1", 1, "/api/endpoint", r#".status == "active""#),
        make_test_control("ctrl-2", 1, "/api/endpoint", r#".status == "active""#),
        make_test_control("ctrl-3", 1, "/api/endpoint", r#".status == "active""#),
    ];

    let _report = engine.scan(&controls, &provider, 1).await;

    // Each control has 1 check, and each check calls the endpoint once
    assert_eq!(
        provider.call_count(),
        3,
        "Each check should make exactly one API call"
    );
}

// ===========================================================================
// 8. Edge Cases
// ===========================================================================

#[tokio::test]
async fn test_empty_controls_list() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test");

    let report = engine.scan(&[], &provider, 1).await;

    assert_eq!(report.summary.total, 0);
    assert_eq!(report.summary.passed, 0);
    assert_eq!(report.summary.failed, 0);
    assert_eq!(report.summary.skipped, 0);
    assert_eq!(report.summary.errors, 0);
    assert_eq!(report.exit_code(), 0);
}

#[tokio::test]
async fn test_control_result_preserves_metadata() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("github")
        .with_response("/api/test", json!({"enabled": true}));

    let mut control = make_test_control("gh-meta", 2, "/api/test", ".enabled == true");
    control.severity = Severity::Critical;
    control.compliance = ComplianceMapping {
        soc2: vec!["CC6.1".to_string()],
        nist_800_53: vec!["AC-2".to_string()],
        iso_27001: vec![],
        pci_dss: vec![],
        disa_stig: vec![],
    };

    let result = engine.audit_control(&control, &provider).await;

    assert_eq!(result.control_id, "gh-meta");
    assert_eq!(result.title, "Test Control gh-meta");
    assert_eq!(result.severity, Severity::Critical);
    assert_eq!(result.profile_level, 2);
    assert_eq!(result.compliance.soc2, vec!["CC6.1".to_string()]);
    assert_eq!(result.compliance.nist_800_53, vec!["AC-2".to_string()]);
}

#[tokio::test]
async fn test_check_result_has_duration() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test")
        .with_response("/api/test", json!({"enabled": true}));

    let control = make_test_control("dur-1", 1, "/api/test", ".enabled == true");
    let result = engine.audit_control(&control, &provider).await;

    // Duration should be a non-negative value (the mock is instant, so likely 0-1ms)
    assert!(result.checks[0].duration_ms < 1000, "Check should complete quickly with mock");
}

#[tokio::test]
async fn test_error_takes_precedence_over_failure() {
    let engine = AuditEngine::new();
    // First endpoint returns data that causes a fail, second endpoint is missing (error)
    let provider = MockVendorProvider::new("test")
        .with_response("/api/fail", json!({"enabled": false}));

    let control = make_multi_check_control(
        "mixed-1",
        1,
        vec![
            ("fail-check", "/api/fail", ".enabled == true"),
            ("error-check", "/api/missing", ".enabled == true"),
        ],
    );

    let result = engine.audit_control(&control, &provider).await;

    // Error status should take precedence over Fail
    assert_eq!(result.status, ControlStatus::Error);
    assert_eq!(result.checks[0].status, CheckStatus::Fail);
    assert_eq!(result.checks[1].status, CheckStatus::Error);
}

#[tokio::test]
async fn test_null_json_response_handling() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test")
        .with_response("/api/null", json!(null));

    let control = make_test_control("null-1", 1, "/api/null", ". == null");
    let result = engine.audit_control(&control, &provider).await;

    assert_eq!(result.status, ControlStatus::Pass);
}

#[tokio::test]
async fn test_nested_json_field_access() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test").with_response(
        "/api/nested",
        json!({
            "settings": {
                "security": {
                    "mfa_required": true,
                    "session_timeout": 3600
                }
            }
        }),
    );

    let control = make_test_control(
        "nested-1",
        1,
        "/api/nested",
        ".settings.security.mfa_required == true",
    );

    let result = engine.audit_control(&control, &provider).await;
    assert_eq!(result.status, ControlStatus::Pass);
}

#[tokio::test]
async fn test_numeric_comparison_in_jq() {
    let engine = AuditEngine::new();
    let provider = MockVendorProvider::new("test").with_response(
        "/api/timeout",
        json!({"session_timeout_minutes": 30}),
    );

    let control = make_test_control(
        "timeout-1",
        1,
        "/api/timeout",
        ".session_timeout_minutes <= 60",
    );

    let result = engine.audit_control(&control, &provider).await;
    assert_eq!(result.status, ControlStatus::Pass);
}
