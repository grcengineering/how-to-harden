use std::path::{Path, PathBuf};

use crate::error::{HthError, HthResult};
use crate::models::Control;

use super::yaml::load_controls_from_dir;

/// Represents a loaded vendor pack.
#[derive(Debug)]
pub struct Pack {
    pub vendor: String,
    pub controls: Vec<Control>,
    pub path: PathBuf,
}

/// Discover and load a vendor pack from the packs directory.
pub fn load_pack(packs_dir: &Path, vendor: &str) -> HthResult<Pack> {
    let vendor_dir = packs_dir.join(vendor);
    let controls_dir = vendor_dir.join("controls");

    if !controls_dir.exists() {
        return Err(HthError::PackNotFound {
            vendor: vendor.to_string(),
            packs_dir: packs_dir.display().to_string(),
        });
    }

    let controls = load_controls_from_dir(&controls_dir)?;

    Ok(Pack {
        vendor: vendor.to_string(),
        controls,
        path: vendor_dir,
    })
}

/// Discover all available vendor packs in the packs directory.
pub fn discover_packs(packs_dir: &Path) -> HthResult<Vec<String>> {
    let mut vendors = Vec::new();

    if !packs_dir.exists() {
        return Ok(vendors);
    }

    for entry in std::fs::read_dir(packs_dir).map_err(|e| HthError::Io(e))? {
        let entry = entry.map_err(|e| HthError::Io(e))?;
        let path = entry.path();

        if path.is_dir() {
            let controls_dir = path.join("controls");
            if controls_dir.exists() {
                if let Some(name) = path.file_name().and_then(|n| n.to_str()) {
                    // Skip schema and other non-vendor directories
                    if name != "schema" {
                        vendors.push(name.to_string());
                    }
                }
            }
        }
    }

    vendors.sort();
    Ok(vendors)
}
