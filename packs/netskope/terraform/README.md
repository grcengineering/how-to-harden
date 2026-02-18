# Netskope Hardening Code Pack -- Terraform

> Part of the [How to Harden](https://howtoharden.com) project by [GRC Engineering](https://grc.engineering)

Terraform configuration for hardening Netskope SSE (Security Service Edge) deployments including CASB, SWG, and ZTNA. Implements controls from the [Netskope Hardening Guide](https://howtoharden.com/guides/netskope/).

## Provider

| Provider | Registry | Purpose |
|----------|----------|---------|
| `netskopeoss/netskope` | [Registry](https://registry.terraform.io/providers/netskopeoss/netskope/latest) | NPA private apps, publishers, access policies, tunnels |

The Netskope Terraform provider manages NPA (Network Private Access) resources. Controls for CASB policies, DLP, threat protection, and steering use `null_resource` with `local-exec` provisioners calling the Netskope REST API v2.

## Quick Start

```bash
# 1. Copy example variables
cp terraform.tfvars.example terraform.tfvars

# 2. Edit with your values (API credentials, tenant URL, etc.)
#    For sensitive values, use environment variables instead:
#    export TF_VAR_netskope_api_key="..."

# 3. Initialize and plan
terraform init
terraform plan

# 4. Apply at your chosen profile level
terraform apply -var="profile_level=1"   # Baseline
terraform apply -var="profile_level=2"   # Hardened
terraform apply -var="profile_level=3"   # Maximum Security
```

## Profile Levels

Levels are cumulative -- L2 includes all L1 controls, L3 includes L1+L2.

| Level | Name | Controls Added |
|-------|------|----------------|
| **L1** | Baseline | Admin SSO, tenant hardening, app visibility, real-time protection, DLP profiles (alert mode), malware protection, client steering, logging/alerts |
| **L2** | Hardened | Admin IP allowlisting, API protection, advanced DLP (EDM/OCR/ML, coach mode), threat policies (newly registered domains, behavior analytics) |
| **L3** | Maximum Security | DLP block mode, fail-close client, strictest enforcement |

## Controls

| File | Control | Level |
|------|---------|-------|
| `hth-netskope-1.01-secure-admin-console-access.tf` | Secure Admin Console Access (SSO/MFA) | L1 |
| `hth-netskope-1.02-configure-tenant-hardening.tf` | Configure Tenant Hardening | L1/L2 |
| `hth-netskope-2.01-configure-application-visibility.tf` | Configure Application Visibility | L1 |
| `hth-netskope-2.02-configure-realtime-protection-policies.tf` | Configure Real-Time Protection Policies | L1 |
| `hth-netskope-2.03-configure-api-protection.tf` | Configure API Protection | L2 |
| `hth-netskope-3.01-configure-dlp-profiles.tf` | Configure DLP Profiles | L1/L2 |
| `hth-netskope-3.02-apply-dlp-to-policies.tf` | Apply DLP to Policies | L1/L2/L3 |
| `hth-netskope-4.01-configure-malware-protection.tf` | Configure Malware Protection | L1 |
| `hth-netskope-4.02-configure-threat-protection-policies.tf` | Configure Threat Protection Policies | L2 |
| `hth-netskope-5.01-configure-client-steering.tf` | Configure Netskope Client Steering | L1 |
| `hth-netskope-5.02-deploy-netskope-client.tf` | Deploy Netskope Client | L1/L3 |
| `hth-netskope-6.01-configure-logging-and-alerts.tf` | Configure Logging and Alerts | L1 |

## REST API Controls

Most Netskope security controls (CASB, DLP, threat protection, steering) are not exposed through the Terraform provider and are configured via the Netskope REST API v2 using `null_resource` with `local-exec` provisioners:

- **1.x** Admin SSO, session timeout, IP allowlisting
- **2.x** App discovery, real-time protection policies, API protection
- **3.x** DLP profiles and policy enforcement
- **4.x** Malware protection, sandboxing, behavior analytics
- **5.x** Traffic steering and client configuration
- **6.x** Alerting and SIEM integration

## License Requirements

Some controls require specific Netskope SSE license tiers:

| Feature | SSE Starter | SSE Professional | SSE Enterprise |
|---------|-------------|------------------|----------------|
| CASB Inline | Yes | Yes | Yes |
| CASB API | No | Yes | Yes |
| DLP (Full) | Basic | Full | Full |
| Cloud Sandbox | No | Yes | Yes |
| Behavior Analytics | No | Yes | Yes |

## Authentication

Generate a REST API v2 token in the Netskope Admin Console under **Settings > Tools > REST API v2**.

```bash
export TF_VAR_netskope_server_url="https://your-tenant.goskope.com/api/v2"
export TF_VAR_netskope_api_key="your-rest-api-v2-token"
export TF_VAR_netskope_tenant_url="https://your-tenant.goskope.com"
```

## License

MIT -- see [LICENSE](../../../LICENSE) in the repository root.
