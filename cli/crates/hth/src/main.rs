mod commands;

use std::path::Path;

use clap::Parser;
use tracing_subscriber::EnvFilter;

/// How to Harden — Security hardening audit and remediation CLI
#[derive(Parser)]
#[command(
    name = "hth",
    version,
    about = "Audit and harden cloud platforms against security best practices",
    long_about = "How to Harden (hth) audits cloud platform configurations against \
                  community-developed hardening guides and can remediate failing controls \
                  via API or Terraform.\n\n\
                  https://howtoharden.com"
)]
struct Cli {
    /// Path to configuration file
    #[arg(long, global = true, default_value = ".hth.toml")]
    config: String,

    /// Vendor to operate on (e.g., github, okta)
    #[arg(long, global = true)]
    vendor: Option<String>,

    /// Profile level: 1 (baseline), 2 (hardened), 3 (maximum)
    #[arg(long, short, global = true, default_value = "1")]
    profile: u8,

    /// Path to packs directory [env: HTH_PACKS_DIR]
    #[arg(long, global = true, env = "HTH_PACKS_DIR")]
    packs_dir: Option<String>,

    /// Output format: table, json, sarif, csv
    #[arg(long, short, global = true, default_value = "table")]
    output: String,

    /// Disable colored output
    #[arg(long, global = true)]
    no_color: bool,

    /// Enable verbose logging
    #[arg(long, short = 'v', global = true)]
    verbose: bool,

    /// Suppress non-essential output
    #[arg(long, short, global = true)]
    quiet: bool,

    #[command(subcommand)]
    command: Commands,
}

#[derive(clap::Subcommand)]
enum Commands {
    /// Audit controls against a live environment
    Scan(commands::scan::ScanArgs),

    /// Fix failing controls via API or generate Terraform
    Remediate(commands::remediate::RemediateArgs),

    /// Validate YAML control definitions against schema
    Validate(commands::validate::ValidateArgs),

    /// Generate compliance reports
    Report(commands::report::ReportArgs),

    /// Analyze SaaS stack and produce recommendations
    Analyze(commands::analyze::AnalyzeArgs),

    /// Initialize configuration
    Init(commands::init::InitArgs),

    /// List available vendors, controls, and frameworks
    List(commands::list::ListArgs),
}

/// Resolve the packs directory using a search order:
/// 1. Explicit --packs-dir flag or HTH_PACKS_DIR env var
/// 2. ./packs relative to current working directory
/// 3. packs/ relative to binary location (walking up parent dirs)
fn resolve_packs_dir(explicit: Option<&str>) -> String {
    if let Some(dir) = explicit {
        return dir.to_string();
    }

    // Try ./packs relative to CWD
    let cwd_packs = Path::new("./packs");
    if cwd_packs.exists() && cwd_packs.is_dir() {
        return "./packs".to_string();
    }

    // Try relative to the binary location — walk up parent directories
    // This handles layouts like:
    //   cli/target/release/hth         → ../../packs
    //   cli/target/x86_64-*/release/hth → ../../../packs
    //   /usr/local/bin/hth             → /usr/local/share/hth/packs (won't match, falls through)
    if let Ok(exe_path) = std::env::current_exe() {
        let mut dir = exe_path.as_path();
        // Walk up to 5 levels from the binary
        for _ in 0..5 {
            if let Some(parent) = dir.parent() {
                let candidate = parent.join("packs");
                if candidate.exists() && candidate.is_dir() {
                    return candidate.display().to_string();
                }
                dir = parent;
            } else {
                break;
            }
        }
    }

    // Fallback — will produce a clear "not found" error
    "./packs".to_string()
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();

    // Initialize logging
    let filter = if cli.verbose {
        "hth=debug,hth_core=debug,hth_github=debug,hth_okta=debug"
    } else {
        "hth=info"
    };

    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| {
            EnvFilter::new(filter)
        }))
        .with_target(false)
        .init();

    // Disable colors if requested
    if cli.no_color {
        console::set_colors_enabled(false);
    }

    // Resolve packs directory
    let packs_dir = resolve_packs_dir(cli.packs_dir.as_deref());

    // Build vendor registry
    let registry = build_vendor_registry();

    match cli.command {
        Commands::Scan(args) => {
            commands::scan::run(args, &cli.vendor, cli.profile, &packs_dir, &cli.output, &registry).await
        }
        Commands::Remediate(args) => {
            commands::remediate::run(args, &cli.vendor, cli.profile, &packs_dir, &registry).await
        }
        Commands::Validate(args) => {
            commands::validate::run(args, &packs_dir).await
        }
        Commands::Report(args) => {
            commands::report::run(args, &cli.vendor, cli.profile, &packs_dir, &cli.output, &registry).await
        }
        Commands::Analyze(args) => {
            commands::analyze::run(args, &packs_dir, &registry).await
        }
        Commands::Init(args) => {
            commands::init::run(args).await
        }
        Commands::List(args) => {
            commands::list::run(args, &packs_dir, &registry).await
        }
    }
}

fn build_vendor_registry() -> hth_core::vendor::VendorRegistry {
    let mut registry = hth_core::vendor::VendorRegistry::new();

    #[cfg(feature = "vendor-github")]
    if let Ok(provider) = hth_github::GitHubProvider::from_env() {
        registry.register(Box::new(provider));
    }

    #[cfg(feature = "vendor-okta")]
    if let Ok(provider) = hth_okta::OktaProvider::from_env() {
        registry.register(Box::new(provider));
    }

    registry
}
