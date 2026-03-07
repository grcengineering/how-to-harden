//! End-to-end integration tests for the `hth` CLI binary.
//!
//! These tests exercise the compiled binary via `std::process::Command`,
//! validating exit codes and output content for every subcommand.
//! No live API access is required -- scan tests use `--dry-run`.

use std::path::PathBuf;
use std::process::Command;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns the path to the compiled `hth` binary.
///
/// `CARGO_BIN_EXE_hth` is set by Cargo when running tests for a package
/// that declares `[[bin]] name = "hth"`.
fn hth_bin() -> PathBuf {
    PathBuf::from(env!("CARGO_BIN_EXE_hth"))
}

/// Returns the absolute path to the `packs/` directory at the repository root.
///
/// CARGO_MANIFEST_DIR for this crate is `cli/crates/hth/`, so we walk up
/// three levels to reach the repo root and then append `packs`.
fn packs_dir() -> String {
    let mut dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    dir.pop(); // -> cli/crates/
    dir.pop(); // -> cli/
    dir.pop(); // -> repo root
    dir.push("packs");
    dir.display().to_string()
}

/// Shorthand: run `hth` with the given args, returning the `Output`.
fn run(args: &[&str]) -> std::process::Output {
    Command::new(hth_bin())
        .args(args)
        .env("NO_COLOR", "1")
        .output()
        .expect("failed to execute hth binary")
}

/// Shorthand: run `hth` with the given args from a specific working directory.
fn run_in(dir: &std::path::Path, args: &[&str]) -> std::process::Output {
    Command::new(hth_bin())
        .args(args)
        .current_dir(dir)
        .env("NO_COLOR", "1")
        .output()
        .expect("failed to execute hth binary")
}

/// Combine stdout + stderr into a single string for pattern matching.
fn full_output(output: &std::process::Output) -> String {
    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    format!("{stdout}{stderr}")
}

// ===========================================================================
// 1. Version & Help Tests
// ===========================================================================

#[test]
fn test_version_output() {
    let output = run(&["--version"]);
    assert!(output.status.success(), "hth --version should exit 0");
    let text = full_output(&output);
    assert!(
        text.contains("hth") && text.contains("0.1.0"),
        "expected 'hth 0.1.0' in version output, got: {text}"
    );
}

#[test]
fn test_help_output() {
    let output = run(&["--help"]);
    assert!(output.status.success(), "hth --help should exit 0");
    let text = full_output(&output);
    // Must mention the core subcommands
    for keyword in &[
        "scan",
        "validate",
        "list",
        "init",
        "report",
        "analyze",
        "remediate",
    ] {
        assert!(
            text.contains(keyword),
            "help output should mention '{keyword}', got: {text}"
        );
    }
}

#[test]
fn test_scan_help() {
    let output = run(&["scan", "--help"]);
    assert!(output.status.success(), "hth scan --help should exit 0");
    let text = full_output(&output);
    // Scan-specific options
    for keyword in &["dry-run", "severity", "tags", "parallel", "timeout"] {
        assert!(
            text.contains(keyword),
            "scan help should mention '{keyword}', got: {text}"
        );
    }
}

#[test]
fn test_validate_help() {
    let output = run(&["validate", "--help"]);
    assert!(output.status.success(), "hth validate --help should exit 0");
    let text = full_output(&output);
    assert!(
        text.contains("strict"),
        "validate help should mention 'strict', got: {text}"
    );
}

#[test]
fn test_list_help() {
    let output = run(&["list", "--help"]);
    assert!(output.status.success(), "hth list --help should exit 0");
    let text = full_output(&output);
    for keyword in &["vendors", "controls", "frameworks", "tags"] {
        assert!(
            text.contains(keyword),
            "list help should mention '{keyword}', got: {text}"
        );
    }
}

#[test]
fn test_init_help() {
    let output = run(&["init", "--help"]);
    assert!(output.status.success(), "hth init --help should exit 0");
    let text = full_output(&output);
    assert!(
        text.contains("vendor"),
        "init help should mention 'vendor', got: {text}"
    );
}

// ===========================================================================
// 2. Validate Command Tests
// ===========================================================================

#[test]
fn test_validate_all_packs() {
    let output = run(&["validate", "--packs-dir", &packs_dir()]);
    assert!(
        output.status.success(),
        "validate should exit 0; stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let text = full_output(&output);
    assert!(
        text.contains("59 controls validated"),
        "expected '59 controls validated' in output, got: {text}"
    );
    assert!(
        text.contains("All controls valid"),
        "expected 'All controls valid' in output, got: {text}"
    );
}

#[test]
fn test_validate_strict() {
    let output = run(&["validate", "--strict", "--packs-dir", &packs_dir()]);
    assert!(
        output.status.success(),
        "validate --strict should exit 0; stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let text = full_output(&output);
    assert!(
        text.contains("All controls valid"),
        "strict validate should still pass, got: {text}"
    );
}

#[test]
fn test_validate_bad_packs_dir() {
    let output = run(&["validate", "--packs-dir", "/nonexistent/path"]);
    let text = full_output(&output);
    // The implementation returns Ok(()) with a "No vendor packs found" warning
    // when the packs directory doesn't exist or contains no packs.
    // This is graceful degradation, not a hard error.
    assert!(
        text.contains("No vendor packs found") || text.contains("Failed") || text.contains("error"),
        "expected a meaningful message about missing packs, got: {text}"
    );
}

#[test]
fn test_validate_mentions_vendors() {
    let output = run(&["validate", "--packs-dir", &packs_dir()]);
    let text = full_output(&output);
    assert!(
        text.contains("github") && text.contains("okta"),
        "validate output should mention both vendors, got: {text}"
    );
}

#[test]
fn test_validate_mentions_two_vendors() {
    let output = run(&["validate", "--packs-dir", &packs_dir()]);
    let text = full_output(&output);
    assert!(
        text.contains("2 vendor(s)"),
        "validate should report '2 vendor(s)', got: {text}"
    );
}

// ===========================================================================
// 3. List Command Tests
// ===========================================================================

#[test]
fn test_list_vendors_default() {
    // `hth list` with no flags defaults to listing vendors
    let output = run(&["list", "--packs-dir", &packs_dir()]);
    assert!(
        output.status.success(),
        "list should exit 0; stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let text = full_output(&output);
    assert!(
        text.contains("github"),
        "list output should contain 'github', got: {text}"
    );
    assert!(
        text.contains("okta"),
        "list output should contain 'okta', got: {text}"
    );
}

#[test]
fn test_list_vendors_explicit() {
    let output = run(&["list", "--vendors", "--packs-dir", &packs_dir()]);
    assert!(output.status.success());
    let text = full_output(&output);
    assert!(text.contains("github") && text.contains("okta"));
}

#[test]
fn test_list_controls() {
    let output = run(&["list", "--controls", "--packs-dir", &packs_dir()]);
    assert!(
        output.status.success(),
        "list --controls should exit 0; stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let text = full_output(&output);
    // Should contain control IDs from both vendors
    assert!(
        text.contains("github-1.1"),
        "controls list should contain 'github-1.1', got: {text}"
    );
    assert!(
        text.contains("okta-1.1"),
        "controls list should contain 'okta-1.1', got: {text}"
    );
    // Should contain level indicators
    assert!(
        text.contains("L1"),
        "controls list should contain 'L1', got: {text}"
    );
}

#[test]
fn test_list_frameworks() {
    let output = run(&["list", "--frameworks", "--packs-dir", &packs_dir()]);
    assert!(
        output.status.success(),
        "list --frameworks should exit 0; stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let text = full_output(&output);
    for framework in &["SOC 2", "NIST 800-53", "ISO 27001", "PCI DSS", "DISA STIG"] {
        assert!(
            text.contains(framework),
            "frameworks list should contain '{framework}', got: {text}"
        );
    }
}

#[test]
fn test_list_frameworks_shows_slugs() {
    let output = run(&["list", "--frameworks", "--packs-dir", &packs_dir()]);
    let text = full_output(&output);
    for slug in &["soc2", "nist-800-53", "iso-27001", "pci-dss", "disa-stig"] {
        assert!(
            text.contains(slug),
            "frameworks list should contain slug '{slug}', got: {text}"
        );
    }
}

#[test]
fn test_list_tags() {
    let output = run(&["list", "--tags", "--packs-dir", &packs_dir()]);
    assert!(
        output.status.success(),
        "list --tags should exit 0; stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let text = full_output(&output);
    assert!(
        text.contains("Available tags"),
        "tags output should contain 'Available tags', got: {text}"
    );
    // Check for some known tags from the packs
    for tag in &["authentication", "supply-chain", "oauth"] {
        assert!(
            text.contains(tag),
            "tags list should contain '{tag}', got: {text}"
        );
    }
}

#[test]
fn test_list_tags_sorted() {
    let output = run(&["list", "--tags", "--packs-dir", &packs_dir()]);
    let text = full_output(&output);
    // Tags should be alphabetically sorted (BTreeSet in implementation).
    // Verify that "2fa" appears before "access-control" (lexicographic order)
    let pos_2fa = text.find("2fa");
    let pos_access = text.find("access-control");
    if let (Some(a), Some(b)) = (pos_2fa, pos_access) {
        assert!(
            a < b,
            "tags should be sorted: '2fa' at {a} should come before 'access-control' at {b}"
        );
    }
}

// ===========================================================================
// 4. Scan Command Tests (dry-run only -- no live API)
// ===========================================================================

#[test]
fn test_scan_dry_run_github_l1() {
    let output = run(&[
        "scan",
        "--vendor",
        "github",
        "--dry-run",
        "--packs-dir",
        &packs_dir(),
    ]);
    assert!(
        output.status.success(),
        "scan --dry-run should exit 0; stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let text = full_output(&output);
    assert!(
        text.contains("DRY RUN"),
        "dry-run output should mention 'DRY RUN', got: {text}"
    );
    assert!(
        text.contains("github-1.1"),
        "dry-run should list control github-1.1, got: {text}"
    );
}

#[test]
fn test_scan_dry_run_github_l2_includes_more_controls() {
    let l1_output = run(&[
        "scan",
        "--vendor",
        "github",
        "--profile",
        "1",
        "--dry-run",
        "--packs-dir",
        &packs_dir(),
    ]);
    let l2_output = run(&[
        "scan",
        "--vendor",
        "github",
        "--profile",
        "2",
        "--dry-run",
        "--packs-dir",
        &packs_dir(),
    ]);

    let l1_text = full_output(&l1_output);
    let l2_text = full_output(&l2_output);

    // L1 scan header says "Scanning N controls" where N = 25 (total loaded),
    // but the per-control lines differ: L2 controls show "skip" at L1 but active at L2.
    // Count the lines that do NOT contain "skip" in each output
    let l1_active = l1_text
        .lines()
        .filter(|l| !l.contains("skip") && l.contains("checks"))
        .count();
    let l2_active = l2_text
        .lines()
        .filter(|l| !l.contains("skip") && l.contains("checks"))
        .count();
    assert!(
        l2_active > l1_active,
        "L2 should have more active controls ({l2_active}) than L1 ({l1_active})"
    );
}

#[test]
fn test_scan_dry_run_github_l3_includes_all_controls() {
    let output = run(&[
        "scan",
        "--vendor",
        "github",
        "--profile",
        "3",
        "--dry-run",
        "--packs-dir",
        &packs_dir(),
    ]);
    assert!(output.status.success());
    let text = full_output(&output);

    // At L3, no controls should be skipped
    let skip_count = text
        .lines()
        .filter(|l| l.contains("skip, requires L"))
        .count();
    assert_eq!(
        skip_count, 0,
        "L3 should not skip any controls, but found {skip_count} skipped lines"
    );
}

#[test]
fn test_scan_dry_run_okta() {
    let output = run(&[
        "scan",
        "--vendor",
        "okta",
        "--dry-run",
        "--packs-dir",
        &packs_dir(),
    ]);
    assert!(
        output.status.success(),
        "scan --dry-run for okta should exit 0; stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let text = full_output(&output);
    assert!(
        text.contains("okta-1.1"),
        "dry-run for okta should list okta-1.1, got: {text}"
    );
}

#[test]
fn test_scan_dry_run_shows_control_count() {
    let output = run(&[
        "scan",
        "--vendor",
        "github",
        "--dry-run",
        "--packs-dir",
        &packs_dir(),
    ]);
    let text = full_output(&output);
    assert!(
        text.contains("Scanning 25 controls"),
        "dry-run should report 'Scanning 25 controls' for github, got: {text}"
    );
}

#[test]
fn test_scan_missing_vendor_flag() {
    let output = run(&["scan", "--dry-run", "--packs-dir", &packs_dir()]);
    assert!(
        !output.status.success(),
        "scan without --vendor should fail"
    );
    let text = full_output(&output);
    assert!(
        text.contains("--vendor") || text.contains("vendor"),
        "error should mention --vendor flag, got: {text}"
    );
}

#[test]
fn test_scan_unknown_vendor() {
    let output = run(&[
        "scan",
        "--vendor",
        "nonexistent",
        "--dry-run",
        "--packs-dir",
        &packs_dir(),
    ]);
    assert!(
        !output.status.success(),
        "scan with unknown vendor should fail"
    );
    let text = full_output(&output);
    assert!(
        text.contains("nonexistent") || text.contains("Failed"),
        "error should mention the unknown vendor, got: {text}"
    );
}

// ===========================================================================
// 5. Init Command Tests
// ===========================================================================

#[test]
fn test_init_creates_config() {
    let tmp = tempfile::tempdir().expect("failed to create temp dir");
    let output = run_in(tmp.path(), &["init"]);
    assert!(
        output.status.success(),
        "init should exit 0; stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let config_path = tmp.path().join(".hth.toml");
    assert!(
        config_path.exists(),
        ".hth.toml should be created in working directory"
    );
    let content = std::fs::read_to_string(&config_path).expect("failed to read .hth.toml");
    assert!(
        content.contains("[global]"),
        "config should contain [global] section, got: {content}"
    );
    assert!(
        content.contains("packs_dir"),
        "config should contain packs_dir, got: {content}"
    );
}

#[test]
fn test_init_with_vendor_github() {
    let tmp = tempfile::tempdir().expect("failed to create temp dir");
    let output = run_in(tmp.path(), &["init", "--vendor", "github"]);
    assert!(output.status.success());
    let content =
        std::fs::read_to_string(tmp.path().join(".hth.toml")).expect("failed to read .hth.toml");
    assert!(
        content.contains("[vendors.github]"),
        "config should contain [vendors.github] section, got: {content}"
    );
    assert!(
        content.contains("GITHUB_TOKEN"),
        "github vendor section should mention GITHUB_TOKEN, got: {content}"
    );
}

#[test]
fn test_init_with_vendor_okta() {
    let tmp = tempfile::tempdir().expect("failed to create temp dir");
    let output = run_in(tmp.path(), &["init", "--vendor", "okta"]);
    assert!(output.status.success());
    let content =
        std::fs::read_to_string(tmp.path().join(".hth.toml")).expect("failed to read .hth.toml");
    assert!(
        content.contains("[vendors.okta]"),
        "config should contain [vendors.okta] section, got: {content}"
    );
    assert!(
        content.contains("OKTA_API_TOKEN"),
        "okta vendor section should mention OKTA_API_TOKEN, got: {content}"
    );
}

#[test]
fn test_init_does_not_overwrite_existing() {
    let tmp = tempfile::tempdir().expect("failed to create temp dir");
    // Create an existing config
    std::fs::write(tmp.path().join(".hth.toml"), "# existing config\n")
        .expect("failed to write existing config");

    let output = run_in(tmp.path(), &["init"]);
    assert!(
        output.status.success(),
        "init should exit 0 even if config exists"
    );
    let text = full_output(&output);
    assert!(
        text.contains("already exists"),
        "init should warn about existing config, got: {text}"
    );
    // Verify the original content is preserved
    let content =
        std::fs::read_to_string(tmp.path().join(".hth.toml")).expect("failed to read .hth.toml");
    assert_eq!(
        content, "# existing config\n",
        "existing config should not be overwritten"
    );
}

#[test]
fn test_init_config_has_scan_section() {
    let tmp = tempfile::tempdir().expect("failed to create temp dir");
    run_in(tmp.path(), &["init"]);
    let content =
        std::fs::read_to_string(tmp.path().join(".hth.toml")).expect("failed to read .hth.toml");
    assert!(
        content.contains("[scan]"),
        "config should contain [scan] section, got: {content}"
    );
    assert!(
        content.contains("[report]"),
        "config should contain [report] section, got: {content}"
    );
}

#[cfg(unix)]
#[test]
fn test_init_config_has_restrictive_permissions() {
    use std::os::unix::fs::PermissionsExt;
    let tmp = tempfile::tempdir().expect("failed to create temp dir");
    run_in(tmp.path(), &["init"]);
    let metadata =
        std::fs::metadata(tmp.path().join(".hth.toml")).expect("failed to read .hth.toml metadata");
    let mode = metadata.permissions().mode() & 0o777;
    assert_eq!(
        mode, 0o600,
        "config file should have mode 0600, got: {mode:o}"
    );
}

// ===========================================================================
// 6. Analyze Command Tests
// ===========================================================================

#[test]
fn test_analyze_single_vendor() {
    let output = run(&["analyze", "--stack", "github", "--packs-dir", &packs_dir()]);
    assert!(
        output.status.success(),
        "analyze --stack github should exit 0; stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let text = full_output(&output);
    assert!(
        text.contains("github"),
        "analyze output should mention 'github', got: {text}"
    );
    assert!(
        text.contains("pack available"),
        "analyze should report github pack is available, got: {text}"
    );
}

#[test]
fn test_analyze_multi_vendor() {
    let output = run(&[
        "analyze",
        "--stack",
        "github,okta",
        "--packs-dir",
        &packs_dir(),
    ]);
    assert!(output.status.success());
    let text = full_output(&output);
    assert!(
        text.contains("github") && text.contains("okta"),
        "analyze should mention both vendors, got: {text}"
    );
}

#[test]
fn test_analyze_unknown_vendor_in_stack() {
    let output = run(&[
        "analyze",
        "--stack",
        "github,slack",
        "--packs-dir",
        &packs_dir(),
    ]);
    assert!(output.status.success());
    let text = full_output(&output);
    // slack has no pack, should be flagged as guide-only
    assert!(
        text.contains("no pack available") || text.contains("guide-only"),
        "slack should be reported as no pack available, got: {text}"
    );
}

#[test]
fn test_analyze_empty_stack() {
    let output = run(&["analyze", "--packs-dir", &packs_dir()]);
    assert!(output.status.success());
    let text = full_output(&output);
    assert!(
        text.contains("--stack"),
        "empty stack should prompt user to specify --stack, got: {text}"
    );
}

// ===========================================================================
// 7. Report Command Tests (no live API -- test error paths gracefully)
// ===========================================================================

#[test]
fn test_report_missing_vendor() {
    let output = run(&["report", "--packs-dir", &packs_dir()]);
    assert!(
        !output.status.success(),
        "report without --vendor should fail"
    );
    let text = full_output(&output);
    assert!(
        text.contains("vendor") || text.contains("--vendor"),
        "error should mention --vendor, got: {text}"
    );
}

#[test]
fn test_remediate_missing_vendor() {
    let output = run(&["remediate", "--packs-dir", &packs_dir()]);
    assert!(
        !output.status.success(),
        "remediate without --vendor should fail"
    );
    let text = full_output(&output);
    assert!(
        text.contains("vendor") || text.contains("--vendor"),
        "error should mention --vendor, got: {text}"
    );
}

// ===========================================================================
// 8. Global Flags Tests
// ===========================================================================

#[test]
fn test_verbose_flag_accepted() {
    let output = run(&[
        "--verbose",
        "list",
        "--frameworks",
        "--packs-dir",
        &packs_dir(),
    ]);
    assert!(
        output.status.success(),
        "--verbose should be accepted; stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

#[test]
fn test_no_color_flag_accepted() {
    let output = run(&[
        "--no-color",
        "list",
        "--frameworks",
        "--packs-dir",
        &packs_dir(),
    ]);
    assert!(output.status.success(), "--no-color should be accepted");
}

#[test]
fn test_quiet_flag_accepted() {
    let output = run(&[
        "--quiet",
        "list",
        "--frameworks",
        "--packs-dir",
        &packs_dir(),
    ]);
    assert!(output.status.success(), "--quiet should be accepted");
}

#[test]
fn test_output_json_flag_accepted() {
    // The list command renders its own tables, but the flag should still parse
    let output = run(&[
        "--output",
        "json",
        "list",
        "--frameworks",
        "--packs-dir",
        &packs_dir(),
    ]);
    assert!(
        output.status.success(),
        "--output json should be accepted with list"
    );
}

#[test]
fn test_no_subcommand_shows_error() {
    let output = run(&[]);
    assert!(
        !output.status.success(),
        "hth with no subcommand should fail"
    );
    let text = full_output(&output);
    assert!(
        text.contains("Usage") || text.contains("subcommand"),
        "no-subcommand should show usage, got: {text}"
    );
}

// ===========================================================================
// 9. Regression Tests
// ===========================================================================

#[test]
fn test_packs_resolution_from_non_repo_dir() {
    // Regression: running from outside repo should still work
    // via explicit --packs-dir absolute path
    let tmp = tempfile::tempdir().expect("failed to create temp dir");
    let output = run_in(tmp.path(), &["validate", "--packs-dir", &packs_dir()]);
    assert!(
        output.status.success(),
        "validate should work from non-repo dir with explicit --packs-dir; stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let text = full_output(&output);
    assert!(
        text.contains("59 controls validated"),
        "should validate all 59 controls from non-repo dir, got: {text}"
    );
}

#[test]
fn test_validate_output_shows_control_ids() {
    // Regression: validate output should show individual control IDs
    let output = run(&["validate", "--packs-dir", &packs_dir()]);
    let text = full_output(&output);
    assert!(
        text.contains("github-1.1"),
        "validate should show individual control IDs like 'github-1.1', got: {text}"
    );
    assert!(
        text.contains("okta-1.1"),
        "validate should show individual control IDs like 'okta-1.1', got: {text}"
    );
}

#[test]
fn test_validate_output_shows_check_counts() {
    // Regression: validate output should show audit check counts per control
    let output = run(&["validate", "--packs-dir", &packs_dir()]);
    let text = full_output(&output);
    assert!(
        text.contains("checks"),
        "validate should show check counts, got: {text}"
    );
}

#[test]
fn test_scan_dry_run_from_temp_dir() {
    // Regression: scan should work from any directory with explicit --packs-dir
    let tmp = tempfile::tempdir().expect("failed to create temp dir");
    let output = run_in(
        tmp.path(),
        &[
            "scan",
            "--vendor",
            "github",
            "--dry-run",
            "--packs-dir",
            &packs_dir(),
        ],
    );
    assert!(
        output.status.success(),
        "scan --dry-run should work from temp dir; stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

#[test]
fn test_list_controls_shows_severity() {
    // Regression: controls list should show severity levels
    let output = run(&["list", "--controls", "--packs-dir", &packs_dir()]);
    let text = full_output(&output);
    // Should contain severity values from the packs
    let has_severity = text.contains("critical")
        || text.contains("Critical")
        || text.contains("high")
        || text.contains("High")
        || text.contains("medium")
        || text.contains("Medium");
    assert!(
        has_severity,
        "controls list should show severity levels, got: {text}"
    );
}

#[test]
fn test_scan_dry_run_l1_skips_higher_controls() {
    let output = run(&[
        "scan",
        "--vendor",
        "github",
        "--profile",
        "1",
        "--dry-run",
        "--packs-dir",
        &packs_dir(),
    ]);
    let text = full_output(&output);
    // At L1, L2 and L3 controls should show "skip, requires L2" or "skip, requires L3"
    assert!(
        text.contains("skip, requires L2") || text.contains("skip, requires L3"),
        "L1 scan should skip higher-level controls, got: {text}"
    );
}

#[test]
fn test_env_packs_dir_variable() {
    // Test that HTH_PACKS_DIR environment variable works
    let output = Command::new(hth_bin())
        .args(["validate"])
        .env("HTH_PACKS_DIR", packs_dir())
        .env("NO_COLOR", "1")
        .output()
        .expect("failed to execute hth binary");
    assert!(
        output.status.success(),
        "validate should work with HTH_PACKS_DIR env var; stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let text = full_output(&output);
    assert!(
        text.contains("59 controls validated"),
        "should validate all 59 controls via env var, got: {text}"
    );
}
