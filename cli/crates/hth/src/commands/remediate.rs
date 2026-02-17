use std::path::Path;

use anyhow::{Context, Result};
use clap::Args;
use console::style;

use hth_core::engine::{AuditEngine, RemediationEngine, TerraformGenerator};
use hth_core::loader;
use hth_core::models::ControlStatus;
use hth_core::vendor::VendorRegistry;

#[derive(Args)]
pub struct RemediateArgs {
    /// Remediation mode: api, terraform, both
    #[arg(long, default_value = "api")]
    mode: String,

    /// Remediate specific controls
    #[arg(long, value_delimiter = ',')]
    controls: Option<Vec<String>>,

    /// Execute remediation (without this flag, only shows what would change)
    #[arg(long)]
    apply: bool,

    /// Output directory for generated Terraform
    #[arg(long, default_value = "./hth-terraform")]
    terraform_dir: String,

    /// Skip interactive confirmation
    #[arg(long)]
    yes: bool,
}

pub async fn run(
    args: RemediateArgs,
    vendor: &Option<String>,
    profile: u8,
    packs_dir: &str,
    registry: &VendorRegistry,
) -> Result<()> {
    let vendor = vendor
        .as_deref()
        .context("--vendor is required for remediate")?;

    let pack = loader::load_pack(Path::new(packs_dir), vendor)?;

    let provider = registry.get(vendor).context(format!(
        "Vendor '{vendor}' is not configured. Set the required environment variables."
    ))?;

    // First, run a scan to find failing controls
    eprintln!(
        "{}",
        style("  Running audit to identify failing controls...").cyan()
    );
    let engine = AuditEngine::new();
    let report = engine.scan(&pack.controls, provider, profile).await;

    let failing: Vec<_> = report
        .controls
        .iter()
        .filter(|c| c.status == ControlStatus::Fail)
        .collect();

    if failing.is_empty() {
        eprintln!(
            "{}",
            style("  All controls passing — nothing to remediate")
                .green()
                .bold()
        );
        return Ok(());
    }

    eprintln!(
        "{}",
        style(format!("  {} control(s) failing", failing.len())).yellow()
    );

    // Generate Terraform if requested
    if args.mode == "terraform" || args.mode == "both" {
        let failing_controls: Vec<_> = pack
            .controls
            .iter()
            .filter(|c| {
                failing.iter().any(|f| f.control_id == c.id)
                    && c.remediate.as_ref().is_some_and(|r| r.terraform.is_some())
            })
            .collect();

        if !failing_controls.is_empty() {
            let hcl = TerraformGenerator::generate(&failing_controls, provider)?;
            eprintln!("\n{}", style("  Generated Terraform:").cyan().bold());
            println!("{hcl}");

            if args.apply {
                let tf_dir = Path::new(&args.terraform_dir);
                std::fs::create_dir_all(tf_dir)?;
                std::fs::write(tf_dir.join("main.tf"), &hcl)?;
                eprintln!("  Terraform written to {}", style(tf_dir.display()).green());
            }
        }
    }

    // Execute API remediation if requested
    if (args.mode == "api" || args.mode == "both") && args.apply {
        let remediation_engine = RemediationEngine::new();

        for failing_result in &failing {
            let control = pack
                .controls
                .iter()
                .find(|c| c.id == failing_result.control_id);

            if let Some(control) = control {
                let steps = remediation_engine.plan_remediation(control, failing_result);

                if steps.is_empty() {
                    eprintln!(
                        "  {} {} — no API remediation available",
                        style("–").dim(),
                        control.id
                    );
                    continue;
                }

                eprintln!(
                    "  {} {} — {} step(s) to execute",
                    style("→").cyan(),
                    control.id,
                    steps.len()
                );

                let results = remediation_engine.execute(&steps, provider).await?;

                for result in &results {
                    if result.success {
                        eprintln!("    {} {}", style("✓").green(), result.description);
                    } else {
                        eprintln!(
                            "    {} {} — {}",
                            style("✗").red(),
                            result.description,
                            result.error.as_deref().unwrap_or("unknown error")
                        );
                    }
                }
            }
        }
    } else if !args.apply {
        eprintln!(
            "\n{}",
            style("  [DRY RUN] Use --apply to execute remediation").yellow()
        );
    }

    Ok(())
}
