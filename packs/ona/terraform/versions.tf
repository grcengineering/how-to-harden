# Shared setup for Ona pack examples. Copy once into the approved root module.
# Official registry lists stable0.5.1 on2026-11-05; Linux amd64/arm64 only.
# Commit the reviewed lockfile; never store ONA_TOKEN or state in the repo.
terraform {
  required_version = ">= 1.14"
  required_providers {
    ona = {
      source  = "gitpod-io/ona"
      version = "= 0.5.1"
    }
  }
}
# Same-origin custom management plane only; ONA_HOST if actually required.
provider "ona" {}
