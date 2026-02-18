# Sentry Hardening Code Pack - Terraform

Terraform implementation of the [Sentry Hardening Guide](https://howtoharden.com/guides/sentry/) from How to Harden.

## Provider

| Name | Source | Version |
|------|--------|---------|
| sentry | [jianyuan/sentry](https://registry.terraform.io/providers/jianyuan/sentry/latest/docs) | ~> 0.12 |

## Prerequisites

- Terraform >= 1.0
- Sentry Business or Enterprise plan (required for SSO and audit logs)
- Sentry internal integration auth token with permissions: `org:admin`, `project:admin`, `team:admin`, `alerts:write`

## Quick Start

```bash
cd packs/sentry/terraform/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Profile Levels

Profiles are cumulative -- L2 includes all L1 controls, L3 includes all L1+L2 controls.

| Level | Name | Description |
|-------|------|-------------|
| 1 | Baseline | Teams, admin member management, security alerting |
| 2 | Hardened | + Project isolation, DSN rate limiting, inbound data filters, legacy browser blocking |
| 3 | Maximum Security | + All L2 controls with strictest parameters |

## Controls Implemented

| File | Control | Level | Provider Resource |
|------|---------|-------|-------------------|
| `hth-sentry-1.01-configure-saml-sso.tf` | 1.1 Configure SAML SSO | L1 | `data.sentry_organization` (manual SSO config) |
| `hth-sentry-1.02-enforce-two-factor-authentication.tf` | 1.2 Enforce 2FA | L1 | Manual (API/UI documented) |
| `hth-sentry-2.01-configure-team-access.tf` | 2.1 Configure Team Access | L1 | `sentry_team` |
| `hth-sentry-2.02-configure-project-access.tf` | 2.2 Configure Project Access | L2 | `sentry_project` |
| `hth-sentry-2.03-limit-admin-access.tf` | 2.3 Limit Admin Access | L1 | `sentry_organization_member` |
| `hth-sentry-3.01-configure-data-scrubbing.tf` | 3.1 Configure Data Scrubbing | L1 | Manual (API documented) |
| `hth-sentry-3.02-configure-dsn-security.tf` | 3.2 Configure DSN Security | L1 | `sentry_key` |
| `hth-sentry-3.03-configure-ip-filtering.tf` | 3.3 Configure IP Filtering | L2 | `sentry_project_inbound_data_filter` |
| `hth-sentry-4.01-configure-audit-logs.tf` | 4.1 Configure Audit Logs | L1 | `sentry_issue_alert` (monitoring) |

## Manual Steps Required

The Sentry Terraform provider does not cover all hardening controls natively. The following must be configured via the Sentry UI or API:

1. **SAML SSO** (Control 1.1) -- Configure via Settings > Auth > SAML2
2. **2FA Enforcement** (Control 1.2) -- Enable via Settings > Security
3. **Data Scrubbing** (Control 3.1) -- Configure sensitive fields via project settings API

Each control file documents the exact API calls and UI steps needed.

## Authentication

Create an internal integration in Sentry:

1. Navigate to **Settings > Developer Settings > Internal Integrations**
2. Create a new integration with required permissions
3. Copy the auth token

```bash
# Option 1: Environment variable (recommended)
export TF_VAR_sentry_token="sntrys_..."

# Option 2: In terraform.tfvars (never commit this file)
sentry_token = "sntrys_..."
```

## Outputs

After applying, key outputs include:

- `organization_id` -- Sentry organization internal ID
- `team_ids` -- Map of team slugs to IDs
- `project_ids` -- Map of project slugs to IDs (L2+)
- `admin_member_ids` -- Map of admin emails to member IDs
- `rate_limited_key_ids` -- Map of project slugs to DSN key IDs (L2+)
- `hardening_summary` -- Complete summary of applied controls
