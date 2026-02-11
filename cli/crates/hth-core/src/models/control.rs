use serde::{Deserialize, Serialize};

/// A security hardening control definition, deserialized from YAML.
/// Mirrors `packs/schema/control.schema.json`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Control {
    /// Unique control identifier (e.g., "github-1.1").
    pub id: String,

    /// Vendor slug matching the pack directory name (e.g., "github").
    pub vendor: String,

    /// Human-readable control title.
    pub title: String,

    /// Section number in the hardening guide (e.g., "1.1").
    pub section: String,

    /// Minimum profile level required: 1=Baseline, 2=Hardened, 3=Maximum.
    pub profile_level: u8,

    /// Control severity.
    pub severity: Severity,

    /// URL to the control in the published guide.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub guide_url: Option<String>,

    /// What this control configures and why.
    pub description: String,

    /// Compliance framework mappings.
    pub compliance: ComplianceMapping,

    /// Audit checks to verify the control is in place.
    pub audit: Vec<AuditCheck>,

    /// Remediation actions to bring the control into compliance.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub remediate: Option<Remediation>,

    /// Searchable tags.
    #[serde(default)]
    pub tags: Vec<String>,
}

impl Control {
    /// Returns true if this control applies at the given profile level.
    /// Controls are cumulative: L2 includes L1, L3 includes L1+L2.
    pub fn applies_at_level(&self, level: u8) -> bool {
        self.profile_level <= level
    }

    /// Returns the profile level label (L1, L2, L3).
    pub fn level_label(&self) -> &'static str {
        match self.profile_level {
            1 => "L1 (Baseline)",
            2 => "L2 (Hardened)",
            3 => "L3 (Maximum)",
            _ => "Unknown",
        }
    }
}

/// Control severity levels.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Severity {
    Critical,
    High,
    Medium,
    Low,
}

impl Severity {
    pub fn as_str(&self) -> &'static str {
        match self {
            Severity::Critical => "critical",
            Severity::High => "high",
            Severity::Medium => "medium",
            Severity::Low => "low",
        }
    }
}

impl std::fmt::Display for Severity {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.as_str())
    }
}

/// Compliance framework mappings.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ComplianceMapping {
    #[serde(default)]
    pub soc2: Vec<String>,
    #[serde(default)]
    pub nist_800_53: Vec<String>,
    #[serde(default)]
    pub iso_27001: Vec<String>,
    #[serde(default)]
    pub pci_dss: Vec<String>,
    #[serde(default)]
    pub disa_stig: Vec<String>,
}

impl ComplianceMapping {
    /// Returns all framework mappings as (framework_name, control_ids) pairs.
    pub fn all_mappings(&self) -> Vec<(&'static str, &[String])> {
        let mut mappings = Vec::new();
        if !self.soc2.is_empty() {
            mappings.push(("SOC 2", self.soc2.as_slice()));
        }
        if !self.nist_800_53.is_empty() {
            mappings.push(("NIST 800-53", self.nist_800_53.as_slice()));
        }
        if !self.iso_27001.is_empty() {
            mappings.push(("ISO 27001", self.iso_27001.as_slice()));
        }
        if !self.pci_dss.is_empty() {
            mappings.push(("PCI DSS", self.pci_dss.as_slice()));
        }
        if !self.disa_stig.is_empty() {
            mappings.push(("DISA STIG", self.disa_stig.as_slice()));
        }
        mappings
    }
}

/// A single audit check within a control.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuditCheck {
    /// Unique check identifier within this control (e.g., "fido2-authenticator-active").
    pub id: String,

    /// What this check verifies.
    pub description: String,

    /// API call specification.
    pub api: ApiCall,

    /// Expected result of the jq check expression.
    pub expected: bool,
}

/// API call specification for audit checks and remediation steps.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ApiCall {
    /// HTTP method.
    pub method: HttpMethod,

    /// API endpoint path relative to vendor base URL (e.g., "/api/v1/authenticators").
    pub endpoint: String,

    /// jq expression that evaluates to a boolean.
    pub check: String,

    /// Optional request body (used for remediation, not audit).
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub body: Option<serde_json::Value>,
}

/// HTTP methods supported by control definitions.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[allow(clippy::upper_case_acronyms)]
pub enum HttpMethod {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
}

impl std::fmt::Display for HttpMethod {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            HttpMethod::GET => write!(f, "GET"),
            HttpMethod::POST => write!(f, "POST"),
            HttpMethod::PUT => write!(f, "PUT"),
            HttpMethod::DELETE => write!(f, "DELETE"),
            HttpMethod::PATCH => write!(f, "PATCH"),
        }
    }
}

/// Remediation specification for a control.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Remediation {
    /// API-based remediation steps.
    #[serde(default)]
    pub api: Vec<RemediationStep>,

    /// Terraform resource definitions.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub terraform: Option<TerraformRemediation>,

    /// Advisory note for process-based controls that can't be automated.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
}

/// A single remediation step (API call).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RemediationStep {
    /// What this step does.
    pub description: String,

    /// HTTP method.
    pub method: HttpMethod,

    /// API endpoint path.
    pub endpoint: String,

    /// Request body.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub body: Option<serde_json::Value>,

    /// Condition referencing an audit check ID.
    /// Prefix with `!` for negation (e.g., "!mfa-policy-exists" means
    /// "run this step only if the mfa-policy-exists check failed").
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub condition: Option<String>,
}

/// Terraform remediation specification.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TerraformRemediation {
    pub resources: Vec<TerraformResource>,
}

/// A Terraform resource to create/manage.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TerraformResource {
    /// Terraform resource type (e.g., "github_branch_protection").
    #[serde(rename = "type")]
    pub resource_type: String,

    /// Terraform resource name (e.g., "main_protection").
    pub name: String,

    /// Resource configuration attributes.
    pub config: serde_json::Value,
}
