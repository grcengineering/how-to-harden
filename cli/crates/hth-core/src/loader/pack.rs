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

#[cfg(test)]
mod tests {
    use super::*;

    /// Resolve the real packs directory from the crate manifest dir.
    fn packs_dir() -> PathBuf {
        PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .parent()
            .unwrap() // crates/
            .parent()
            .unwrap() // cli/
            .parent()
            .unwrap() // repo root
            .join("packs")
    }

    #[test]
    fn load_pack_loads_github_controls() {
        let dir = packs_dir();
        let pack = load_pack(&dir, "github").expect("should load github pack");
        assert_eq!(pack.vendor, "github");
        assert!(!pack.controls.is_empty(), "github pack should have controls");
    }

    #[test]
    fn load_pack_returns_pack_not_found_for_nonexistent_vendor() {
        let dir = packs_dir();
        let result = load_pack(&dir, "nonexistent-vendor-xyz");
        assert!(result.is_err());
        let err = result.unwrap_err();
        let msg = format!("{err}");
        assert!(msg.contains("nonexistent-vendor-xyz"));
    }

    #[test]
    fn discover_packs_finds_github_and_okta() {
        let dir = packs_dir();
        let vendors = discover_packs(&dir).expect("should discover packs");
        assert!(vendors.contains(&"github".to_string()), "should find github");
        assert!(vendors.contains(&"okta".to_string()), "should find okta");
    }

    #[test]
    fn discover_packs_skips_schema_directory() {
        let dir = packs_dir();
        let vendors = discover_packs(&dir).expect("should discover packs");
        assert!(
            !vendors.contains(&"schema".to_string()),
            "schema should not be in vendor list"
        );
    }

    #[test]
    fn discover_packs_returns_empty_for_nonexistent_dir() {
        let dir = PathBuf::from("/tmp/nonexistent-hth-packs-dir-xyz");
        let vendors = discover_packs(&dir).expect("should return Ok for missing dir");
        assert!(vendors.is_empty());
    }
}
