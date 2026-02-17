pub mod csv;
pub mod json;
pub mod sarif;
pub mod table;

use std::fmt;
use std::str::FromStr;

use crate::models::ScanReport;

/// Output format enum.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum OutputFormat {
    Table,
    Json,
    Sarif,
    Csv,
}

/// Error returned when parsing an unknown output format string.
#[derive(Debug, Clone)]
pub struct ParseOutputFormatError(pub String);

impl fmt::Display for ParseOutputFormatError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "unknown output format: '{}'", self.0)
    }
}

impl std::error::Error for ParseOutputFormatError {}

impl FromStr for OutputFormat {
    type Err = ParseOutputFormatError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "table" => Ok(OutputFormat::Table),
            "json" => Ok(OutputFormat::Json),
            "sarif" => Ok(OutputFormat::Sarif),
            "csv" => Ok(OutputFormat::Csv),
            _ => Err(ParseOutputFormatError(s.to_string())),
        }
    }
}

/// Render a scan report in the specified format.
pub fn render_report(report: &ScanReport, format: OutputFormat) -> String {
    match format {
        OutputFormat::Table => table::render_scan_report(report),
        OutputFormat::Json => json::render_scan_report(report),
        OutputFormat::Sarif => sarif::render_scan_report(report),
        OutputFormat::Csv => csv::render_scan_report(report),
    }
}
