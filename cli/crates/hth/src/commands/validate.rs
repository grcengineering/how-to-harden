use std::path::Path;

use anyhow::{Context, Result};
use clap::Args;
use console::style;

use hth_core::loader;

#[derive(Args)]
pub struct ValidateArgs {
    /// Fail on warnings (not just errors)
    #[arg(long)]
    strict: bool,
}

pub async fn run(args: ValidateArgs, packs_dir: &str) -> Result<()> {
    let packs_path = Path::new(packs_dir);

    let vendors = loader::discover_packs(packs_path).context("Failed to discover packs")?;

    if vendors.is_empty() {
        eprintln!("{}", style("  No vendor packs found").yellow());
        return Ok(());
    }

    let mut total_controls = 0;
    let mut total_errors = 0;
    let mut total_warnings = 0;

    for vendor in &vendors {
        let controls_dir = packs_path.join(vendor).join("controls");

        eprintln!("{}", style(format!("  Validating {vendor} pack...")).cyan());

        let mut entries: Vec<_> = std::fs::read_dir(&controls_dir)
            .context(format!("Failed to read {}", controls_dir.display()))?
            .filter_map(|e| e.ok())
            .filter(|e| {
                e.path()
                    .extension()
                    .is_some_and(|ext| ext == "yaml" || ext == "yml")
            })
            .collect();

        entries.sort_by_key(|e| e.file_name());

        for entry in entries {
            let path = entry.path();
            match loader::load_control(&path) {
                Ok(control) => {
                    total_controls += 1;

                    // Validate control fields
                    let mut warnings = Vec::new();

                    if control.audit.is_empty() {
                        warnings.push("No audit checks defined");
                    }

                    if control.description.is_empty() {
                        warnings.push("Empty description");
                    }

                    // Check audit checks use GET only
                    for check in &control.audit {
                        if check.api.method != hth_core::models::HttpMethod::GET {
                            total_errors += 1;
                            eprintln!(
                                "  {} {} — audit check '{}' uses {} (must be GET)",
                                style("✗").red(),
                                path.file_name().unwrap_or_default().to_string_lossy(),
                                check.id,
                                check.api.method,
                            );
                        }
                    }

                    if warnings.is_empty() {
                        eprintln!(
                            "  {} {} — {} ({})",
                            style("✓").green(),
                            control.id,
                            control.title,
                            style(format!("{} checks", control.audit.len())).dim()
                        );
                    } else {
                        total_warnings += warnings.len();
                        for warning in &warnings {
                            eprintln!("  {} {} — {}", style("⚠").yellow(), control.id, warning);
                        }
                    }
                }
                Err(e) => {
                    total_errors += 1;
                    eprintln!(
                        "  {} {} — {}",
                        style("✗").red(),
                        path.file_name().unwrap_or_default().to_string_lossy(),
                        e
                    );
                }
            }
        }
    }

    // Summary
    eprintln!();
    eprintln!(
        "  {} controls validated across {} vendor(s)",
        total_controls,
        vendors.len()
    );

    if total_errors > 0 {
        eprintln!("  {} error(s)", style(total_errors).red());
    }
    if total_warnings > 0 {
        eprintln!("  {} warning(s)", style(total_warnings).yellow());
    }

    if total_errors > 0 || (args.strict && total_warnings > 0) {
        std::process::exit(1);
    }

    eprintln!("  {}", style("All controls valid").green().bold());
    Ok(())
}
