# Zscaler Hardening Code Pack -- Terraform

> Part of the [How to Harden](https://howtoharden.com) project by [GRC Engineering](https://grc.engineering)

Terraform configuration for hardening Zscaler ZIA (Internet Access) and ZPA (Private Access) deployments. Implements controls from the [Zscaler Hardening Guide](https://howtoharden.com/guides/zscaler/).

## Providers

This pack uses two Zscaler Terraform providers:

| Provider | Registry | Purpose |
|----------|----------|---------|
| `zscaler/zpa` | [Registry](https://registry.terraform.io/providers/zscaler/zpa/latest) | Zero Trust application access, segments, policies |
| `zscaler/zia` | [Registry](https://registry.terraform.io/providers/zscaler/zia/latest) | Web security, URL filtering, SSL inspection, firewall |

## Quick Start

```bash
# 1. Copy example variables
cp terraform.tfvars.example terraform.tfvars

# 2. Edit with your values (API credentials, app segments, etc.)
#    For sensitive values, use environment variables instead:
#    export TF_VAR_zpa_client_id="..."
#    export TF_VAR_zpa_client_secret="..."
#    export TF_VAR_zia_client_id="..."
#    export TF_VAR_zia_client_secret="..."

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
| **L1** | Baseline | URL filtering, threat protection, app segments, access policies, SSL inspection |
| **L2** | Hardened | Cloud firewall policies, device posture checks, Client Connector lock |
| **L3** | Maximum Security | Admin override removal, strictest bypass restrictions |

## Controls

| File | Control | Level | Provider |
|------|---------|-------|----------|
| `hth-zscaler-1.01-configure-saml-sso.tf` | Configure SAML SSO Authentication | L1 | ZPA |
| `hth-zscaler-1.02-role-based-admin-access.tf` | Implement Role-Based Admin Access | L1 | ZIA |
| `hth-zscaler-2.01-url-filtering.tf` | Configure URL Filtering Policies | L1 | ZIA |
| `hth-zscaler-2.02-advanced-threat-protection.tf` | Enable Advanced Threat Protection | L1 | ZIA |
| `hth-zscaler-2.03-firewall-policies.tf` | Configure Firewall Policies | L2 | ZIA |
| `hth-zscaler-3.01-application-segments.tf` | Configure Application Segments | L1 | ZPA |
| `hth-zscaler-3.02-access-policies.tf` | Create Access Policies | L1 | ZPA |
| `hth-zscaler-3.03-device-posture.tf` | Enable Device Posture Checks | L2 | ZPA |
| `hth-zscaler-4.01-client-connector-deploy.tf` | Deploy Client Connector Securely | L1 | Portal |
| `hth-zscaler-4.02-ssl-certificate-deploy.tf` | Install SSL Certificate | L1 | Portal |
| `hth-zscaler-4.03-lock-client-connector.tf` | Lock Client Connector Settings | L2 | Portal |
| `hth-zscaler-5.01-enable-ssl-inspection.tf` | Enable SSL Inspection | L1 | ZIA |
| `hth-zscaler-5.02-test-ssl-inspection.tf` | Test SSL Inspection | L1 | Manual |
| `hth-zscaler-6.01-logging-and-reporting.tf` | Configure Logging and Reporting | L1 | Portal |

**Portal** = Configured through ZIA/ZPA Admin Portal (documented as comments in the `.tf` file).
**Manual** = Operational procedure documented as comments.

## Portal-Managed Controls

Some Zscaler controls are not exposed through the Terraform providers and must be configured through the Admin Portal. These are documented as structured comments in their respective `.tf` files:

- **4.1** Client Connector deployment (tunnel mode, always-on, split tunnel)
- **4.2** SSL certificate deployment to endpoints (MDM/GPO)
- **4.3** Client Connector app profile locking
- **5.2** SSL inspection testing (operational procedure)
- **6.1** Nanolog Streaming Service SIEM integration

## Authentication

Both providers require API client credentials:

**ZPA:** Generate at ZPA Admin Portal > Administration > API Keys
**ZIA:** Generate at ZIA Admin Portal > Administration > API Key Management

```bash
export TF_VAR_zpa_client_id="your-zpa-client-id"
export TF_VAR_zpa_client_secret="your-zpa-client-secret"
export TF_VAR_zpa_customer_id="your-zpa-customer-id"
export TF_VAR_zia_client_id="your-zia-client-id"
export TF_VAR_zia_client_secret="your-zia-client-secret"
export TF_VAR_zia_customer_id="your-zia-customer-id"
```

## License

MIT -- see [LICENSE](../../../LICENSE) in the repository root.
