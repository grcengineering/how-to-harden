use crate::error::{HthError, HthResult};
use crate::models::{Control, TerraformResource};
use crate::vendor::VendorProvider;

/// Generates Terraform HCL from control remediation specs.
pub struct TerraformGenerator;

impl TerraformGenerator {
    /// Generate Terraform HCL for a set of controls.
    pub fn generate(
        controls: &[&Control],
        provider: &dyn VendorProvider,
    ) -> HthResult<String> {
        let mut output = String::new();

        // Provider block
        output.push_str(&provider.terraform_provider_block());
        output.push('\n');

        // Resource blocks
        for control in controls {
            if let Some(ref remediate) = control.remediate {
                if let Some(ref terraform) = remediate.terraform {
                    output.push_str(&format!(
                        "# {} — {}\n",
                        control.id, control.title
                    ));
                    for resource in &terraform.resources {
                        output.push_str(&Self::resource_to_hcl(resource)?);
                        output.push('\n');
                    }
                }
            }
        }

        Ok(output)
    }

    /// Convert a single TerraformResource to HCL.
    fn resource_to_hcl(resource: &TerraformResource) -> HthResult<String> {
        let mut hcl = format!(
            "resource \"{}\" \"{}\" {{\n",
            resource.resource_type, resource.name
        );

        if let serde_json::Value::Object(map) = &resource.config {
            for (key, value) in map {
                hcl.push_str(&Self::value_to_hcl(key, value, 1));
            }
        } else {
            return Err(HthError::TerraformGen(format!(
                "Resource config for {}.{} must be an object",
                resource.resource_type, resource.name
            )));
        }

        hcl.push_str("}\n");
        Ok(hcl)
    }

    /// Convert a JSON key-value pair to HCL syntax.
    fn value_to_hcl(key: &str, value: &serde_json::Value, indent: usize) -> String {
        let pad = "  ".repeat(indent);
        match value {
            serde_json::Value::String(s) => format!("{pad}{key} = \"{s}\"\n"),
            serde_json::Value::Number(n) => format!("{pad}{key} = {n}\n"),
            serde_json::Value::Bool(b) => format!("{pad}{key} = {b}\n"),
            serde_json::Value::Null => format!("{pad}{key} = null\n"),
            serde_json::Value::Object(map) => {
                let mut block = format!("{pad}{key} {{\n");
                for (k, v) in map {
                    block.push_str(&Self::value_to_hcl(k, v, indent + 1));
                }
                block.push_str(&format!("{pad}}}\n"));
                block
            }
            serde_json::Value::Array(arr) => {
                let items: Vec<String> = arr
                    .iter()
                    .map(|v| match v {
                        serde_json::Value::String(s) => format!("\"{s}\""),
                        other => other.to_string(),
                    })
                    .collect();
                format!("{pad}{key} = [{}]\n", items.join(", "))
            }
        }
    }
}
