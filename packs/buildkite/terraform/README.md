# Buildkite Hardening Code Pack - Terraform

Infrastructure-as-code implementation of the [Buildkite Hardening Guide](https://howtoharden.com/guides/buildkite/) from [How to Harden](https://howtoharden.com).

## Provider

| Name | Source | Version |
|------|--------|---------|
| buildkite | [buildkite/buildkite](https://registry.terraform.io/providers/buildkite/buildkite/latest) | ~> 1.0 |

## Prerequisites

- Terraform >= 1.0
- Buildkite Enterprise or Business plan (required for SSO, teams, clusters)
- Buildkite API token with GraphQL access and `write_pipelines`, `read_pipelines` REST scopes
- SAML IdP configured (for Control 1.1 -- manual step)

## Quick Start

```bash
# Clone and navigate to the pack
cd packs/buildkite/terraform

# Configure your variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize and apply
terraform init
terraform plan
terraform apply
```

## Profile Levels

| Level | Name | Description |
|-------|------|-------------|
| L1 | Baseline | 2FA enforcement, teams, agent tokens, audit logging |
| L2 | Hardened | Adds clusters, pipeline permissions, agent isolation |
| L3 | Maximum Security | Adds API IP restrictions |

Set via: `terraform apply -var="profile_level=2"`

## Controls Implemented

| File | Control | Profile | Terraform Managed |
|------|---------|---------|-------------------|
| `hth-buildkite-1.01-configure-saml-sso.tf` | 1.1 Configure SAML SSO | L1 | No (UI only) |
| `hth-buildkite-1.02-enforce-two-factor-authentication.tf` | 1.2 Enforce 2FA | L1 | Yes |
| `hth-buildkite-2.01-configure-team-permissions.tf` | 2.1 Team Permissions | L1 | Yes |
| `hth-buildkite-2.02-configure-pipeline-permissions.tf` | 2.2 Pipeline Permissions | L2 | Yes |
| `hth-buildkite-2.03-limit-admin-access.tf` | 2.3 Limit Admin Access | L1 | No (UI only) |
| `hth-buildkite-3.01-configure-agent-tokens.tf` | 3.1 Agent Tokens | L1 | Yes |
| `hth-buildkite-3.02-configure-agent-clusters.tf` | 3.2 Agent Clusters | L2 | Yes |
| `hth-buildkite-3.03-secure-agent-infrastructure.tf` | 3.3 Agent Infrastructure | L2 | No (host-level) |
| `hth-buildkite-4.01-configure-audit-logging.tf` | 4.1 Audit Logging | L1/L3 | Partial (API IP restrictions at L3) |

## Controls Requiring Manual Steps

Some controls cannot be fully automated via Terraform:

- **1.1 SAML SSO** -- Configure via Organization Settings > SSO in the Buildkite UI
- **2.3 Admin Access** -- Admin roles assigned via Organization Settings > Members
- **3.3 Agent Infrastructure** -- OS hardening, network restrictions on agent hosts
- **4.1 Audit Logging** -- Enabled by default; review via Organization Settings > Audit Log

## Files

| File | Purpose |
|------|---------|
| `providers.tf` | Buildkite provider configuration |
| `variables.tf` | All input variables with defaults |
| `outputs.tf` | Resource IDs and hardening summary |
| `terraform.tfvars.example` | Example variable values |
| `hth-buildkite-*.tf` | Individual hardening controls |

## Outputs

After applying, review the hardening summary:

```bash
terraform output hardening_summary
```

Key outputs include team IDs, pipeline slugs, agent token values (sensitive), and cluster IDs.

## References

- [Buildkite Terraform Provider](https://registry.terraform.io/providers/buildkite/buildkite/latest/docs)
- [Buildkite Security Controls](https://buildkite.com/docs/pipelines/best-practices/security-controls)
- [Buildkite Team Permissions](https://buildkite.com/docs/team-management/permissions)
- [Buildkite Agent Security](https://buildkite.com/docs/agent/v3/securing)
- [How to Harden - Buildkite Guide](https://howtoharden.com/guides/buildkite/)
