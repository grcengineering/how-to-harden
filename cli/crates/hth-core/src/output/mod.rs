pub mod csv;
pub mod json;
pub mod sarif;
pub mod table;

use crate::models::ScanReport;

/// Output format enum.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum OutputFormat {
    Table,
    Json,
    Sarif,
    Csv,
}

impl OutputFormat {
    pub fn from_str(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "table" => Some(OutputFormat::Table),
            "json" => Some(OutputFormat::Json),
            "sarif" => Some(OutputFormat::Sarif),
            "csv" => Some(OutputFormat::Csv),
            _ => None,
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
