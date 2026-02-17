use anyhow::Result;
use clap::Args;
use console::style;

#[derive(Args)]
pub struct InitArgs {
    /// Initialize for a specific vendor
    #[arg(long)]
    vendor: Option<String>,

    /// Interactive setup wizard
    #[arg(long)]
    interactive: bool,
}

pub async fn run(args: InitArgs) -> Result<()> {
    let config_path = ".hth.toml";

    if std::path::Path::new(config_path).exists() {
        eprintln!("  {} already exists", style(config_path).yellow());
        return Ok(());
    }

    let mut config = String::new();
    config.push_str("# How to Harden CLI Configuration\n");
    config.push_str("# https://howtoharden.com\n\n");
    config.push_str("[global]\n");
    config.push_str("packs_dir = \"./packs\"\n");
    config.push_str("profile_level = 1\n");
    config.push_str("output = \"table\"\n");
    config.push_str("parallel = 4\n\n");

    if let Some(vendor) = &args.vendor {
        match vendor.as_str() {
            "github" => {
                config.push_str("[vendors.github]\n");
                config.push_str("# Set GITHUB_TOKEN and GITHUB_ORG environment variables\n");
                config.push_str("# org = \"your-org-name\"\n\n");
            }
            "okta" => {
                config.push_str("[vendors.okta]\n");
                config.push_str("# Set OKTA_API_TOKEN and OKTA_DOMAIN environment variables\n");
                config.push_str("# domain = \"yourorg.okta.com\"\n\n");
            }
            _ => {
                config.push_str(&format!("[vendors.{vendor}]\n"));
                config.push_str("# Configure vendor credentials via environment variables\n\n");
            }
        }
    }

    config.push_str("[scan]\n");
    config.push_str("fail_on = \"low\"\n");
    config.push_str("timeout = 30\n\n");
    config.push_str("[report]\n");
    config.push_str("frameworks = [\"soc2\", \"nist-800-53\"]\n");
    config.push_str("include_passing = false\n");

    std::fs::write(config_path, &config)?;

    // Set restrictive permissions on Unix
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        std::fs::set_permissions(config_path, std::fs::Permissions::from_mode(0o600))?;
    }

    eprintln!(
        "  {} Created {}",
        style("✓").green(),
        style(config_path).bold()
    );
    eprintln!("  {} Add .hth.toml to your .gitignore", style("→").cyan());

    Ok(())
}
