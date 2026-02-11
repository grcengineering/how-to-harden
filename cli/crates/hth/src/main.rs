mod commands;

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
    #[arg(long, short, global = true)]
    vendor: Option<String>,

    /// Profile level: 1 (baseline), 2 (hardened), 3 (maximum)
    #[arg(long, short, global = true, default_value = "1")]
    profile: u8,

    /// Path to packs directory
    #[arg(long, global = true, default_value = "./packs")]
    packs_dir: String,

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

    // Build vendor registry
    let registry = build_vendor_registry();

    match cli.command {
        Commands::Scan(args) => {
            commands::scan::run(args, &cli.vendor, cli.profile, &cli.packs_dir, &cli.output, &registry).await
        }
        Commands::Remediate(args) => {
            commands::remediate::run(args, &cli.vendor, cli.profile, &cli.packs_dir, &registry).await
        }
        Commands::Validate(args) => {
            commands::validate::run(args, &cli.packs_dir).await
        }
        Commands::Report(args) => {
            commands::report::run(args, &cli.vendor, cli.profile, &cli.packs_dir, &cli.output, &registry).await
        }
        Commands::Analyze(args) => {
            commands::analyze::run(args, &cli.packs_dir, &registry).await
        }
        Commands::Init(args) => {
            commands::init::run(args).await
        }
        Commands::List(args) => {
            commands::list::run(args, &cli.packs_dir, &registry).await
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
