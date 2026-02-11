use serde::{Deserialize, Serialize};

/// Supported compliance frameworks.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum Framework {
    #[serde(rename = "soc2")]
    Soc2,
    #[serde(rename = "nist-800-53")]
    Nist80053,
    #[serde(rename = "iso-27001")]
    Iso27001,
    #[serde(rename = "pci-dss")]
    PciDss,
    #[serde(rename = "disa-stig")]
    DisaStig,
}

impl Framework {
    pub fn display_name(&self) -> &'static str {
        match self {
            Framework::Soc2 => "SOC 2",
            Framework::Nist80053 => "NIST 800-53",
            Framework::Iso27001 => "ISO 27001",
            Framework::PciDss => "PCI DSS",
            Framework::DisaStig => "DISA STIG",
        }
    }

    pub fn slug(&self) -> &'static str {
        match self {
            Framework::Soc2 => "soc2",
            Framework::Nist80053 => "nist-800-53",
            Framework::Iso27001 => "iso-27001",
            Framework::PciDss => "pci-dss",
            Framework::DisaStig => "disa-stig",
        }
    }

    /// Parse a framework from a string slug.
    pub fn from_slug(s: &str) -> Option<Self> {
        match s {
            "soc2" => Some(Framework::Soc2),
            "nist-800-53" | "nist_800_53" => Some(Framework::Nist80053),
            "iso-27001" | "iso_27001" => Some(Framework::Iso27001),
            "pci-dss" | "pci_dss" => Some(Framework::PciDss),
            "disa-stig" | "disa_stig" => Some(Framework::DisaStig),
            _ => None,
        }
    }

    /// Returns all supported frameworks.
    pub fn all() -> &'static [Framework] {
        &[
            Framework::Soc2,
            Framework::Nist80053,
            Framework::Iso27001,
            Framework::PciDss,
            Framework::DisaStig,
        ]
    }
}

impl std::fmt::Display for Framework {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.display_name())
    }
}
