use std::collections::HashMap;
use std::path::PathBuf;

use serde::{Deserialize, Serialize};

/// Top-level HTH configuration, loaded from `.hth.toml`.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct HthConfig {
    #[serde(default)]
    pub global: GlobalConfig,

    #[serde(default)]
    pub vendors: HashMap<String, VendorConfig>,

    #[serde(default)]
    pub report: ReportConfig,

    #[serde(default)]
    pub scan: ScanConfig,
}

/// Global configuration settings.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GlobalConfig {
    /// Path to packs directory.
    #[serde(default = "default_packs_dir")]
    pub packs_dir: String,

    /// Default profile level (1, 2, or 3).
    #[serde(default = "default_profile_level")]
    pub profile_level: u8,

    /// Default output format.
    #[serde(default = "default_output")]
    pub output: String,

    /// Max concurrent API requests.
    #[serde(default = "default_parallel")]
    pub parallel: usize,
}

impl Default for GlobalConfig {
    fn default() -> Self {
        Self {
            packs_dir: default_packs_dir(),
            profile_level: default_profile_level(),
            output: default_output(),
            parallel: default_parallel(),
        }
    }
}

/// Vendor-specific configuration.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct VendorConfig {
    #[serde(default)]
    pub enabled: Option<bool>,

    /// Vendor-specific connection parameters (domain, org, etc.).
    #[serde(flatten)]
    pub params: HashMap<String, String>,

    /// Credential configuration.
    #[serde(default)]
    pub credentials: CredentialConfig,
}

/// Credential resolution configuration.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct CredentialConfig {
    /// Environment variable name containing the API token.
    #[serde(default)]
    pub token_env: Option<String>,

    /// Credential helper command (git-credential-style).
    #[serde(default)]
    pub credential_helper: Option<String>,
}

/// Report configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReportConfig {
    /// Default compliance frameworks to include.
    #[serde(default)]
    pub frameworks: Vec<String>,

    /// Whether to include passing controls in reports.
    #[serde(default)]
    pub include_passing: bool,
}

impl Default for ReportConfig {
    fn default() -> Self {
        Self {
            frameworks: vec![
                "soc2".to_string(),
                "nist-800-53".to_string(),
            ],
            include_passing: false,
        }
    }
}

/// Scan-specific configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScanConfig {
    /// Minimum severity level to fail on.
    #[serde(default = "default_fail_on")]
    pub fail_on: String,

    /// Per-request timeout in seconds.
    #[serde(default = "default_timeout")]
    pub timeout: u64,
}

impl Default for ScanConfig {
    fn default() -> Self {
        Self {
            fail_on: default_fail_on(),
            timeout: default_timeout(),
        }
    }
}

impl HthConfig {
    /// Load configuration from the standard search path.
    /// Searches: --config flag, ./.hth.toml, ~/.config/hth/config.toml
    pub fn load(config_path: Option<&str>) -> Self {
        let paths_to_try = if let Some(path) = config_path {
            vec![PathBuf::from(path)]
        } else {
            let mut paths = vec![PathBuf::from(".hth.toml")];
            if let Some(config_dir) = dirs::config_dir() {
                paths.push(config_dir.join("hth").join("config.toml"));
            }
            paths
        };

        for path in paths_to_try {
            if path.exists() {
                if let Ok(content) = std::fs::read_to_string(&path) {
                    if let Ok(config) = toml::from_str::<HthConfig>(&content) {
                        tracing::info!("Loaded config from {}", path.display());
                        return config;
                    }
                }
            }
        }

        Self::default()
    }
}

fn default_packs_dir() -> String {
    "./packs".to_string()
}
fn default_profile_level() -> u8 {
    1
}
fn default_output() -> String {
    "table".to_string()
}
fn default_parallel() -> usize {
    4
}
fn default_fail_on() -> String {
    "low".to_string()
}
fn default_timeout() -> u64 {
    30
}
