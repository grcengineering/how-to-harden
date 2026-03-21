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

    // Plan remediation steps for all failing controls
    if args.mode == "api" || args.mode == "both" {
        let remediation_engine = RemediationEngine::new();

        // Collect all org repos for multi-repo remediation
        let org_repos = if args.apply {
            match provider
                .execute_request(
                    hth_core::models::HttpMethod::GET,
                    "/orgs/{org}/repos?per_page=100&type=all",
                    None,
                )
                .await
            {
                Ok(repos) => repos
                    .as_array()
                    .map(|arr| {
                        arr.iter()
                            .filter_map(|r| r.get("name").and_then(|n| n.as_str()).map(String::from))
                            .collect::<Vec<_>>()
                    })
                    .unwrap_or_default(),
                Err(_) => Vec::new(),
            }
        } else {
            Vec::new()
        };

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

                // Check if any step targets a repo-level endpoint
                let has_repo_endpoint = steps.iter().any(|s| s.endpoint.contains("{repo}"));
                let repo_count = if has_repo_endpoint && !org_repos.is_empty() {
                    org_repos.len()
                } else {
                    1
                };

                if args.apply {
                    eprintln!(
                        "  {} {} — {} step(s){}",
                        style("→").cyan(),
                        control.id,
                        steps.len(),
                        if repo_count > 1 {
                            format!(" × {} repos", repo_count)
                        } else {
                            String::new()
                        }
                    );

                    if has_repo_endpoint && !org_repos.is_empty() {
                        // Execute repo-level steps against ALL repos in the org
                        for repo in &org_repos {
                            let results = remediation_engine
                                .execute_for_repo(&steps, provider, repo)
                                .await?;

                            let any_fail = results.iter().any(|r| !r.success);
                            if any_fail {
                                for result in &results {
                                    if !result.success {
                                        eprintln!(
                                            "    {} {}/{} — {}",
                                            style("✗").red(),
                                            repo,
                                            result.description,
                                            result.error.as_deref().unwrap_or("unknown error")
                                        );
                                    }
                                }
                            } else {
                                eprintln!(
                                    "    {} {}",
                                    style("✓").green(),
                                    repo
                                );
                            }
                        }
                    } else {
                        // Org-level steps: execute once
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
                } else {
                    // Dry-run: show what would happen
                    eprintln!(
                        "  {} {} — {} step(s) planned{}",
                        style("▸").cyan(),
                        control.id,
                        steps.len(),
                        if has_repo_endpoint {
                            " (per-repo)"
                        } else {
                            ""
                        }
                    );
                    for step in &steps {
                        eprintln!(
                            "    {} {} {}",
                            style("→").dim(),
                            style(format!("{}", step.method)).yellow(),
                            provider.resolve_url(&step.endpoint)
                        );
                        eprintln!(
                            "      {}",
                            style(&step.description).dim()
                        );
                    }
                }
            }
        }

        if !args.apply {
            eprintln!(
                "\n{}",
                style("  [DRY RUN] Use --apply to execute remediation").yellow()
            );
        }
    }

    Ok(())
}
