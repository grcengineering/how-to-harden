use thiserror::Error;

/// Core error type for the HTH engine.
#[derive(Error, Debug)]
pub enum HthError {
    #[error("YAML parse error in {path}: {source}")]
    YamlParse {
        path: String,
        source: serde_yaml::Error,
    },

    #[error("Schema validation failed for {control_id}: {message}")]
    SchemaValidation { control_id: String, message: String },

    #[error("HTTP request failed: {method} {url}: {source}")]
    Http {
        method: String,
        url: String,
        source: reqwest::Error,
    },

    #[error("HTTP {status} from {method} {url}: {body}")]
    HttpStatus {
        method: String,
        url: String,
        status: u16,
        body: String,
    },

    #[error("Rate limited by {vendor} (retry after {retry_after_secs}s)")]
    RateLimit {
        vendor: String,
        retry_after_secs: u64,
    },

    #[error("jq evaluation error on expression '{expression}': {message}")]
    JqEvaluation { expression: String, message: String },

    #[error("jq parse error on expression '{expression}': {message}")]
    JqParse { expression: String, message: String },

    #[error("Vendor '{vendor}' not found. Available: {}", available.join(", "))]
    VendorNotFound {
        vendor: String,
        available: Vec<String>,
    },

    #[error("No packs found for vendor '{vendor}' in {packs_dir}")]
    PackNotFound { vendor: String, packs_dir: String },

    #[error("Configuration error: {0}")]
    Config(String),

    #[error("Credential error for {vendor}: {message}")]
    Credential { vendor: String, message: String },

    #[error("Terraform generation error: {0}")]
    TerraformGen(String),

    #[error("Audit check '{check_id}' in control '{control_id}' uses non-GET method {method} — scan mode requires GET only")]
    ScanWriteViolation {
        control_id: String,
        check_id: String,
        method: String,
    },

    #[error(transparent)]
    Io(#[from] std::io::Error),

    #[error(transparent)]
    Reqwest(#[from] reqwest::Error),
}

/// Result type alias using HthError.
pub type HthResult<T> = std::result::Result<T, HthError>;
