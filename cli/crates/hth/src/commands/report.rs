use std::path::Path;

use anyhow::{Context, Result};
use clap::Args;
use comfy_table::{Cell, Color, Table, presets::UTF8_FULL, modifiers::UTF8_ROUND_CORNERS};
use console::style;

use hth_core::engine::AuditEngine;
use hth_core::loader;
use hth_core::models::{ControlStatus, Framework};
use hth_core::output::{self, OutputFormat};
use hth_core::vendor::VendorRegistry;

#[derive(Args)]
pub struct ReportArgs {
    /// Compliance frameworks: soc2, nist-800-53, iso-27001, pci-dss, disa-stig, all
    #[arg(long, value_delimiter = ',')]
    framework: Option<Vec<String>>,

    /// Use cached scan results instead of live scan
    #[arg(long)]
    scan_file: Option<String>,

    /// Write report to file
    #[arg(long)]
    output_file: Option<String>,

    /// Include passing controls in report
    #[arg(long)]
    include_passing: bool,
}

pub async fn run(
    args: ReportArgs,
    vendor: &Option<String>,
    profile: u8,
    packs_dir: &str,
    output_format: &str,
    registry: &VendorRegistry,
) -> Result<()> {
    let vendor = vendor
        .as_deref()
        .context("--vendor is required for report")?;

    // Determine which frameworks to report on
    let frameworks: Vec<Framework> = if let Some(fw_args) = &args.framework {
        if fw_args.iter().any(|f| f == "all") {
            Framework::all().to_vec()
        } else {
            fw_args
                .iter()
                .filter_map(|f| Framework::from_slug(f))
                .collect()
        }
    } else {
        vec![Framework::Soc2, Framework::Nist80053]
    };

    // Run scan or load cached results
    let report = if let Some(scan_file) = &args.scan_file {
        let content = std::fs::read_to_string(scan_file)?;
        serde_json::from_str(&content)?
    } else {
        let pack = loader::load_pack(Path::new(packs_dir), vendor)?;
        let provider = registry.get(vendor).context(format!(
            "Vendor '{vendor}' is not configured"
        ))?;

        eprintln!(
            "{}",
            style(format!("  Running scan for {} at L{}...", vendor, profile)).cyan()
        );

        let engine = AuditEngine::new();
        engine.scan(&pack.controls, provider, profile).await
    };

    // If JSON/SARIF output is requested, use the standard formatters
    if let Some(format) = OutputFormat::from_str(output_format) {
        if format != OutputFormat::Table {
            let rendered = output::render_report(&report, format);
            if let Some(output_file) = &args.output_file {
                std::fs::write(output_file, &rendered)?;
                eprintln!("  Report written to {}", style(output_file).green());
            } else {
                print!("{rendered}");
            }
            return Ok(());
        }
    }

    // Table-based compliance report
    for framework in &frameworks {
        eprintln!(
            "\n{}",
            style(format!("  {} Compliance Report", framework.display_name()))
                .bold()
                .cyan()
        );

        let mut table = Table::new();
        table
            .load_preset(UTF8_FULL)
            .apply_modifier(UTF8_ROUND_CORNERS)
            .set_header(vec![
                Cell::new("Framework ID").fg(Color::White),
                Cell::new("Status").fg(Color::White),
                Cell::new("Control").fg(Color::White),
                Cell::new("HTH Control").fg(Color::White),
            ]);

        for control in &report.controls {
            if !args.include_passing && control.status == ControlStatus::Pass {
                continue;
            }

            let mappings = match framework {
                Framework::Soc2 => &control.compliance.soc2,
                Framework::Nist80053 => &control.compliance.nist_800_53,
                Framework::Iso27001 => &control.compliance.iso_27001,
                Framework::PciDss => &control.compliance.pci_dss,
                Framework::DisaStig => &control.compliance.disa_stig,
            };

            if mappings.is_empty() {
                continue;
            }

            let status_color = match control.status {
                ControlStatus::Pass => Color::Green,
                ControlStatus::Fail => Color::Red,
                ControlStatus::Skip => Color::Yellow,
                ControlStatus::Error => Color::Magenta,
            };

            for mapping_id in mappings {
                table.add_row(vec![
                    Cell::new(mapping_id),
                    Cell::new(control.status.to_string()).fg(status_color),
                    Cell::new(&control.title),
                    Cell::new(&control.control_id),
                ]);
            }
        }

        println!("{table}");
    }

    Ok(())
}
