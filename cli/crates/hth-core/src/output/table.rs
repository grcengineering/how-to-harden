use comfy_table::{Cell, Color, Table, modifiers::UTF8_ROUND_CORNERS, presets::UTF8_FULL};
use console::style;

use crate::models::{CheckStatus, ControlStatus, ScanReport, Severity};

/// Render a scan report as a colored terminal table.
pub fn render_scan_report(report: &ScanReport) -> String {
    let mut output = String::new();

    // Header
    output.push_str(&format!(
        "\n{}\n",
        style(format!(
            "  How to Harden — {} Scan Results",
            report.vendor.to_uppercase()
        ))
        .bold()
        .cyan()
    ));
    output.push_str(&format!(
        "  Profile Level: L{} | {}\n\n",
        report.profile_level,
        report.timestamp.format("%Y-%m-%d %H:%M:%S UTC")
    ));

    // Controls table
    let mut table = Table::new();
    table
        .load_preset(UTF8_FULL)
        .apply_modifier(UTF8_ROUND_CORNERS)
        .set_header(vec![
            Cell::new("Status").fg(Color::White),
            Cell::new("ID").fg(Color::White),
            Cell::new("Severity").fg(Color::White),
            Cell::new("Level").fg(Color::White),
            Cell::new("Control").fg(Color::White),
            Cell::new("Checks").fg(Color::White),
        ]);

    for control in &report.controls {
        let status_color = match control.status {
            ControlStatus::Pass => Color::Green,
            ControlStatus::Fail => Color::Red,
            ControlStatus::Skip => Color::Yellow,
            ControlStatus::Error => Color::Magenta,
        };

        let severity_color = match control.severity {
            Severity::Critical => Color::Red,
            Severity::High => Color::Yellow,
            Severity::Medium => Color::Cyan,
            Severity::Low => Color::White,
        };

        let checks_summary = format_checks_summary(&control.checks);

        table.add_row(vec![
            Cell::new(control.status.to_string()).fg(status_color),
            Cell::new(&control.control_id),
            Cell::new(control.severity.as_str()).fg(severity_color),
            Cell::new(format!("L{}", control.profile_level)),
            Cell::new(&control.title),
            Cell::new(checks_summary),
        ]);
    }

    output.push_str(&table.to_string());
    output.push('\n');

    // Summary
    output.push_str(&format!(
        "\n  {} {} passed  {} {} failed  {} {} skipped  {} {} errors\n",
        style("●").green(),
        report.summary.passed,
        style("●").red(),
        report.summary.failed,
        style("●").yellow(),
        report.summary.skipped,
        style("●").magenta(),
        report.summary.errors,
    ));

    let checked = report.summary.passed + report.summary.failed;
    output.push_str(&format!(
        "  {}/{} controls passing at L{}\n\n",
        report.summary.passed, checked, report.profile_level
    ));

    output
}

fn format_checks_summary(checks: &[crate::models::CheckResult]) -> String {
    if checks.is_empty() {
        return "—".to_string();
    }
    let pass = checks
        .iter()
        .filter(|c| c.status == CheckStatus::Pass)
        .count();
    let total = checks.len();
    format!("{}/{}", pass, total)
}
