# Azure DevOps Hardening Code Pack - Terraform

> **Source Guide:** [How to Harden Azure DevOps](https://howtoharden.com/guides/azure-devops/)
> **Provider:** [microsoft/azuredevops](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs) `~> 1.0`

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Profile Levels

Controls are gated by `profile_level`. Each level is cumulative.

| Level | Name | Controls Applied |
|-------|------|-----------------|
| **L1** | Baseline | Project features, security groups, pipeline scope restrictions, workload identity federation, branch policies (1 reviewer), credential scanning, variable groups, environments, agent pools |
| **L2** | Hardened | + Service connection approval gates, branch control checks, exclusive deploy locks, classic pipeline restrictions, auto-reviewers for YAML/Terraform, merge type restrictions, path/file size limits, security agent pool, variable group approval |
| **L3** | Maximum Security | + Business hours restrictions on production deployments and service connections |

```bash
# Apply L1 baseline
terraform apply -var="profile_level=1"

# Apply L2 hardened
terraform apply -var="profile_level=2"

# Apply L3 maximum security
terraform apply -var="profile_level=3"
```

## Controls Implemented

| File | Control | Level | Description |
|------|---------|-------|-------------|
| `hth-azure-devops-1.1-enforce-azure-ad-authentication.tf` | 1.1 | L1 | Project feature toggles to reduce attack surface |
| `hth-azure-devops-1.2-implement-project-level-security-groups.tf` | 1.2 | L1 | Security Reviewers group for approval workflows |
| `hth-azure-devops-1.3-configure-personal-access-token-policies.tf` | 1.3 | L1 | Pipeline job scope restrictions and settable var controls |
| `hth-azure-devops-2.1-migrate-to-workload-identity-federation.tf` | 2.1 | L1 | Azure RM service connection with OIDC (no stored secrets) |
| `hth-azure-devops-2.2-audit-and-rotate-legacy-service-connections.tf` | 2.2 | L1 | Data source for auditing legacy credential-based connections |
| `hth-azure-devops-2.3-implement-service-connection-approval-gates.tf` | 2.3 | L2 | Approval, branch control, and business hours checks |
| `hth-azure-devops-3.1-implement-yaml-pipeline-security.tf` | 3.1 | L1 | Pipeline settings: job scope, referenced repo tokens |
| `hth-azure-devops-3.2-configure-pipeline-permissions-and-approvals.tf` | 3.2 | L1 | Environments with approval gates, branch control, deploy locks |
| `hth-azure-devops-3.3-secure-agent-pool-configuration.tf` | 3.3 | L1 | Tiered agent pools with restricted pipeline authorization |
| `hth-azure-devops-4.1-configure-branch-policies.tf` | 4.1 | L1 | Min reviewers, comment resolution, work items, build validation, auto-reviewers |
| `hth-azure-devops-4.2-enable-credential-scanning.tf` | 4.2 | L1 | Credential check policy, path length, file size, reserved names |
| `hth-azure-devops-5.1-secure-variable-groups.tf` | 5.1 | L1 | Key Vault linked variable groups with pipeline authorization |
| `hth-azure-devops-5.2-use-runtime-parameters-for-secrets.tf` | 5.2 | L2 | Approval gate for variable group access |
| `hth-azure-devops-6.1-enable-audit-logging.tf` | 6.1 | L1 | Service hook permissions for audit integration |

## Prerequisites

1. **Azure DevOps Organization** with an existing project
2. **Personal Access Token** with Full Access scope (scope down after initial setup)
3. **Azure subscription** (optional, for workload identity federation)
4. **Azure Key Vault** (optional, for linked variable groups)

## Provider Authentication

```bash
# Option 1: Environment variables (recommended)
export AZDO_ORG_SERVICE_URL="https://dev.azure.com/your-org"
export AZDO_PERSONAL_ACCESS_TOKEN="your-pat"

# Option 2: terraform.tfvars (do not commit)
org_service_url       = "https://dev.azure.com/your-org"
personal_access_token = "your-pat"
```

## What This Pack Does NOT Manage

Some Azure DevOps security controls require the Azure Portal or REST API:

- **Azure AD tenant connection** -- configured in Organization Settings
- **Conditional Access policies** -- configured in Entra ID (Azure AD)
- **PAT lifetime organization policies** -- configured via REST API or UI
- **Classic pipeline disable** -- organization-level toggle in UI
- **Audit log export/streaming** -- configured via REST API
- **Microsoft Security DevOps scanning** -- configured in YAML pipelines

These controls are documented in the [guide](https://howtoharden.com/guides/azure-devops/) with ClickOps instructions.

## File Structure

```text
packs/azure-devops/terraform/
├── providers.tf                    # Provider configuration
├── variables.tf                    # All variable declarations
├── outputs.tf                      # Output values for verification
├── terraform.tfvars.example        # Example variable values
├── README.md                       # This file
├── hth-azure-devops-1.1-*.tf       # Authentication controls
├── hth-azure-devops-1.2-*.tf       # Security groups
├── hth-azure-devops-1.3-*.tf       # PAT restrictions
├── hth-azure-devops-2.1-*.tf       # Workload identity federation
├── hth-azure-devops-2.2-*.tf       # Legacy connection audit
├── hth-azure-devops-2.3-*.tf       # Service connection approvals
├── hth-azure-devops-3.1-*.tf       # YAML pipeline security
├── hth-azure-devops-3.2-*.tf       # Pipeline environments
├── hth-azure-devops-3.3-*.tf       # Agent pool configuration
├── hth-azure-devops-4.1-*.tf       # Branch policies
├── hth-azure-devops-4.2-*.tf       # Credential scanning
├── hth-azure-devops-5.1-*.tf       # Variable groups
├── hth-azure-devops-5.2-*.tf       # Runtime parameter approvals
└── hth-azure-devops-6.1-*.tf       # Audit logging
```
