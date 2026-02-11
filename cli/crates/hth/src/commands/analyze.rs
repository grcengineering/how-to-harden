use anyhow::Result;
use clap::Args;
use console::style;

use hth_core::vendor::VendorRegistry;

#[derive(Args)]
pub struct AnalyzeArgs {
    /// Vendors in the stack (e.g., github,slack,salesforce)
    #[arg(long, value_delimiter = ',')]
    stack: Vec<String>,

    /// Include cross-platform recommendations
    #[arg(long)]
    cross_platform: bool,

    /// Focus on supply-chain/integration risk
    #[arg(long)]
    supply_chain: bool,
}

pub async fn run(
    args: AnalyzeArgs,
    packs_dir: &str,
    _registry: &VendorRegistry,
) -> Result<()> {
    eprintln!(
        "\n{}",
        style("  Stack Analysis").bold().cyan()
    );

    if args.stack.is_empty() {
        eprintln!("  Specify vendors with --stack (e.g., --stack github,slack,salesforce)");
        return Ok(());
    }

    eprintln!("  Analyzing stack: {}", args.stack.join(", "));

    // Check which vendors have packs
    let packs_path = std::path::Path::new(packs_dir);
    for vendor in &args.stack {
        let vendor_dir = packs_path.join(vendor).join("controls");
        if vendor_dir.exists() {
            eprintln!("  {} {} — pack available", style("●").green(), vendor);
        } else {
            eprintln!(
                "  {} {} — no pack available (guide-only)",
                style("○").yellow(),
                vendor
            );
        }
    }

    if args.cross_platform || args.supply_chain {
        eprintln!(
            "\n  {}",
            style("Toxic Combinations analysis coming soon — see roadmap").dim()
        );
    }

    Ok(())
}
