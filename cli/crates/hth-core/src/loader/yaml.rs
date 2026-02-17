use std::path::Path;

use crate::error::{HthError, HthResult};
use crate::models::Control;

/// Load a single control from a YAML file.
pub fn load_control(path: &Path) -> HthResult<Control> {
    let content = std::fs::read_to_string(path).map_err(HthError::Io)?;
    let control: Control = serde_yaml::from_str(&content).map_err(|e| HthError::YamlParse {
        path: path.display().to_string(),
        source: e,
    })?;
    Ok(control)
}

/// Load all controls from a directory of YAML files.
pub fn load_controls_from_dir(dir: &Path) -> HthResult<Vec<Control>> {
    let mut controls = Vec::new();

    if !dir.exists() {
        return Ok(controls);
    }

    let mut entries: Vec<_> = std::fs::read_dir(dir)
        .map_err(HthError::Io)?
        .filter_map(|entry| entry.ok())
        .filter(|entry| {
            entry
                .path()
                .extension()
                .is_some_and(|ext| ext == "yaml" || ext == "yml")
        })
        .collect();

    // Sort by filename for deterministic ordering
    entries.sort_by_key(|e| e.file_name());

    for entry in entries {
        let path = entry.path();
        match load_control(&path) {
            Ok(control) => controls.push(control),
            Err(e) => {
                tracing::warn!("Failed to load control from {}: {}", path.display(), e);
            }
        }
    }

    Ok(controls)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    #[test]
    fn test_load_okta_controls() {
        // Test loading real Okta controls from the packs directory
        let packs_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .parent()
            .unwrap()
            .parent()
            .unwrap()
            .parent()
            .unwrap()
            .join("packs")
            .join("okta")
            .join("controls");

        if packs_dir.exists() {
            let controls = load_controls_from_dir(&packs_dir).unwrap();
            assert!(
                !controls.is_empty(),
                "Should load at least one Okta control"
            );

            // Verify first control has expected structure
            for control in &controls {
                assert!(!control.id.is_empty());
                assert_eq!(control.vendor, "okta");
                assert!(!control.title.is_empty());
                assert!(!control.audit.is_empty());
                assert!(control.profile_level >= 1 && control.profile_level <= 3);
            }
        }
    }
}
