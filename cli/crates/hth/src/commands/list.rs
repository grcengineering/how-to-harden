use std::path::Path;

use anyhow::Result;
use clap::Args;
use comfy_table::{Cell, Color, Table, presets::UTF8_FULL, modifiers::UTF8_ROUND_CORNERS};

use hth_core::loader;
use hth_core::models::Framework;
use hth_core::vendor::VendorRegistry;

#[derive(Args)]
pub struct ListArgs {
    /// List available vendors
    #[arg(long)]
    vendors: bool,

    /// List all controls
    #[arg(long)]
    controls: bool,

    /// List supported compliance frameworks
    #[arg(long)]
    frameworks: bool,

    /// List all tags across controls
    #[arg(long)]
    tags: bool,
}

pub async fn run(
    args: ListArgs,
    packs_dir: &str,
    registry: &VendorRegistry,
) -> Result<()> {
    let packs_path = Path::new(packs_dir);

    // Default to listing vendors if no specific flag
    if !args.vendors && !args.controls && !args.frameworks && !args.tags {
        return list_vendors(packs_path, registry).await;
    }

    if args.vendors {
        list_vendors(packs_path, registry).await?;
    }
    if args.controls {
        list_controls(packs_path).await?;
    }
    if args.frameworks {
        list_frameworks();
    }
    if args.tags {
        list_tags(packs_path).await?;
    }

    Ok(())
}

async fn list_vendors(packs_path: &Path, registry: &VendorRegistry) -> Result<()> {
    let packs = loader::discover_packs(packs_path)?;

    let mut table = Table::new();
    table
        .load_preset(UTF8_FULL)
        .apply_modifier(UTF8_ROUND_CORNERS)
        .set_header(vec![
            Cell::new("Vendor").fg(Color::White),
            Cell::new("Controls").fg(Color::White),
            Cell::new("Connected").fg(Color::White),
        ]);

    for vendor in &packs {
        let pack = loader::load_pack(packs_path, vendor)?;
        let connected = if registry.get(vendor).is_some() {
            Cell::new("●").fg(Color::Green)
        } else {
            Cell::new("○").fg(Color::DarkGrey)
        };

        table.add_row(vec![
            Cell::new(vendor),
            Cell::new(pack.controls.len().to_string()),
            connected,
        ]);
    }

    println!("\n{table}\n");
    Ok(())
}

async fn list_controls(packs_path: &Path) -> Result<()> {
    let packs = loader::discover_packs(packs_path)?;

    let mut table = Table::new();
    table
        .load_preset(UTF8_FULL)
        .apply_modifier(UTF8_ROUND_CORNERS)
        .set_header(vec![
            Cell::new("ID").fg(Color::White),
            Cell::new("Level").fg(Color::White),
            Cell::new("Severity").fg(Color::White),
            Cell::new("Title").fg(Color::White),
        ]);

    for vendor in &packs {
        let pack = loader::load_pack(packs_path, vendor)?;
        for control in &pack.controls {
            let severity_color = match control.severity {
                hth_core::models::Severity::Critical => Color::Red,
                hth_core::models::Severity::High => Color::Yellow,
                hth_core::models::Severity::Medium => Color::Cyan,
                hth_core::models::Severity::Low => Color::White,
            };

            table.add_row(vec![
                Cell::new(&control.id),
                Cell::new(format!("L{}", control.profile_level)),
                Cell::new(control.severity.as_str()).fg(severity_color),
                Cell::new(&control.title),
            ]);
        }
    }

    println!("\n{table}\n");
    Ok(())
}

fn list_frameworks() {
    let mut table = Table::new();
    table
        .load_preset(UTF8_FULL)
        .apply_modifier(UTF8_ROUND_CORNERS)
        .set_header(vec![
            Cell::new("Slug").fg(Color::White),
            Cell::new("Framework").fg(Color::White),
        ]);

    for fw in Framework::all() {
        table.add_row(vec![Cell::new(fw.slug()), Cell::new(fw.display_name())]);
    }

    println!("\n{table}\n");
}

async fn list_tags(packs_path: &Path) -> Result<()> {
    let packs = loader::discover_packs(packs_path)?;
    let mut all_tags = std::collections::BTreeSet::new();

    for vendor in &packs {
        let pack = loader::load_pack(packs_path, vendor)?;
        for control in &pack.controls {
            for tag in &control.tags {
                all_tags.insert(tag.clone());
            }
        }
    }

    println!("\nAvailable tags:");
    for tag in &all_tags {
        println!("  {tag}");
    }
    println!();

    Ok(())
}
