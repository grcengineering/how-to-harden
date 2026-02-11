use std::path::Path;

use anyhow::{bail, Context, Result};
use clap::Args;
use console::style;

use hth_core::engine::AuditEngine;
use hth_core::loader;
use hth_core::output::{self, OutputFormat};
use hth_core::vendor::VendorRegistry;

#[derive(Args)]
pub struct ScanArgs {
    /// Filter by severity: critical, high, medium, low
    #[arg(long, value_delimiter = ',')]
    severity: Option<Vec<String>>,

    /// Filter by tags
    #[arg(long, value_delimiter = ',')]
    tags: Option<Vec<String>>,

    /// Run specific controls (e.g., github-1.1, github-2.1)
    #[arg(long, value_delimiter = ',')]
    controls: Option<Vec<String>>,

    /// Show what would be checked without calling APIs
    #[arg(long)]
    dry_run: bool,

    /// Max concurrent API requests
    #[arg(long, default_value = "4")]
    parallel: usize,

    /// Per-request timeout in seconds
    #[arg(long, default_value = "30")]
    timeout: u64,
}

pub async fn run(
    args: ScanArgs,
    vendor: &Option<String>,
    profile: u8,
    packs_dir: &str,
    output_format: &str,
    registry: &VendorRegistry,
) -> Result<()> {
    let vendor = vendor
        .as_deref()
        .context("--vendor is required for scan. Use --vendor github or --vendor okta")?;

    let format = OutputFormat::from_str(output_format)
        .context(format!("Unknown output format: {output_format}"))?;

    // Load the vendor pack
    let pack = loader::load_pack(Path::new(packs_dir), vendor)
        .context(format!("Failed to load pack for vendor '{vendor}'"))?;

    if pack.controls.is_empty() {
        bail!("No controls found for vendor '{vendor}' in {packs_dir}/{vendor}/controls/");
    }

    eprintln!(
        "{}",
        style(format!(
            "  Scanning {} controls for {} at L{} ...",
            pack.controls.len(),
            vendor,
            profile
        ))
        .cyan()
    );

    if args.dry_run {
        eprintln!("{}", style("  [DRY RUN] No API calls will be made").yellow());
        // In dry-run mode, list controls that would be checked
        for control in &pack.controls {
            if control.applies_at_level(profile) {
                eprintln!(
                    "  {} {} — {} ({} checks)",
                    style("○").dim(),
                    control.id,
                    control.title,
                    control.audit.len()
                );
            } else {
                eprintln!(
                    "  {} {} — {} (skip, requires L{})",
                    style("–").dim(),
                    control.id,
                    control.title,
                    control.profile_level
                );
            }
        }
        return Ok(());
    }

    // Get the vendor provider
    let provider = registry.get(vendor).context(format!(
        "Vendor '{vendor}' is not configured. Set the required environment variables:\n\
         GitHub: GITHUB_TOKEN + GITHUB_ORG\n\
         Okta:   OKTA_API_TOKEN + OKTA_DOMAIN"
    ))?;

    // Run the scan
    let engine = AuditEngine::new();
    let report = engine.scan(&pack.controls, provider, profile).await;

    // Render output
    let rendered = output::render_report(&report, format);
    print!("{rendered}");

    // Exit with appropriate code
    std::process::exit(report.exit_code());
}
