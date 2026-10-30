# Copy this provider file plus ONE selected hth-*.tf pack into an empty directory.
# Never run the whole source directory as a module: it contains independent examples.
# Inject DEVIN_TOKEN through a secret manager. State/plans contain tenant metadata.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    devin = {
      source  = "cognitionai/devin"
      version = "= 0.5.0"
    }
  }
}
provider "devin" {
  api_url = "https://api.devin.ai"
}
