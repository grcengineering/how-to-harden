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

#[cfg(test)]
mod tests {
    use super::*;

    // --- Framework::from_slug with primary slugs ---

    #[test]
    fn from_slug_soc2() {
        assert_eq!(Framework::from_slug("soc2"), Some(Framework::Soc2));
    }

    #[test]
    fn from_slug_nist_800_53_hyphen() {
        assert_eq!(
            Framework::from_slug("nist-800-53"),
            Some(Framework::Nist80053)
        );
    }

    #[test]
    fn from_slug_nist_800_53_underscore() {
        assert_eq!(
            Framework::from_slug("nist_800_53"),
            Some(Framework::Nist80053)
        );
    }

    #[test]
    fn from_slug_iso_27001_hyphen() {
        assert_eq!(Framework::from_slug("iso-27001"), Some(Framework::Iso27001));
    }

    #[test]
    fn from_slug_iso_27001_underscore() {
        assert_eq!(Framework::from_slug("iso_27001"), Some(Framework::Iso27001));
    }

    #[test]
    fn from_slug_pci_dss_hyphen() {
        assert_eq!(Framework::from_slug("pci-dss"), Some(Framework::PciDss));
    }

    #[test]
    fn from_slug_pci_dss_underscore() {
        assert_eq!(Framework::from_slug("pci_dss"), Some(Framework::PciDss));
    }

    #[test]
    fn from_slug_disa_stig_hyphen() {
        assert_eq!(Framework::from_slug("disa-stig"), Some(Framework::DisaStig));
    }

    #[test]
    fn from_slug_disa_stig_underscore() {
        assert_eq!(Framework::from_slug("disa_stig"), Some(Framework::DisaStig));
    }

    // --- from_slug unknown ---

    #[test]
    fn from_slug_returns_none_for_unknown() {
        assert_eq!(Framework::from_slug("unknown"), None);
        assert_eq!(Framework::from_slug(""), None);
        assert_eq!(Framework::from_slug("SOC2"), None);
    }

    // --- display_name ---

    #[test]
    fn display_name_correct() {
        assert_eq!(Framework::Soc2.display_name(), "SOC 2");
        assert_eq!(Framework::Nist80053.display_name(), "NIST 800-53");
        assert_eq!(Framework::Iso27001.display_name(), "ISO 27001");
        assert_eq!(Framework::PciDss.display_name(), "PCI DSS");
        assert_eq!(Framework::DisaStig.display_name(), "DISA STIG");
    }

    // --- slug ---

    #[test]
    fn slug_correct() {
        assert_eq!(Framework::Soc2.slug(), "soc2");
        assert_eq!(Framework::Nist80053.slug(), "nist-800-53");
        assert_eq!(Framework::Iso27001.slug(), "iso-27001");
        assert_eq!(Framework::PciDss.slug(), "pci-dss");
        assert_eq!(Framework::DisaStig.slug(), "disa-stig");
    }

    // --- all ---

    #[test]
    fn all_returns_five_frameworks() {
        assert_eq!(Framework::all().len(), 5);
    }

    #[test]
    fn all_contains_every_variant() {
        let all = Framework::all();
        assert!(all.contains(&Framework::Soc2));
        assert!(all.contains(&Framework::Nist80053));
        assert!(all.contains(&Framework::Iso27001));
        assert!(all.contains(&Framework::PciDss));
        assert!(all.contains(&Framework::DisaStig));
    }

    // --- Display ---

    #[test]
    fn display_matches_display_name() {
        for fw in Framework::all() {
            assert_eq!(format!("{fw}"), fw.display_name());
        }
    }
}
