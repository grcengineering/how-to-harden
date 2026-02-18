# SendGrid Hardening Code Pack — Terraform

Terraform configuration for the [How to Harden SendGrid Guide](https://howtoharden.com/guides/sendgrid/).

## Provider

| Name | Source | Version |
|------|--------|---------|
| sendgrid | [kenzo0107/sendgrid](https://registry.terraform.io/providers/kenzo0107/sendgrid/latest) | ~> 1.0 |

## Prerequisites

- Terraform >= 1.0
- SendGrid API key with full access (for provider authentication)
- SendGrid Pro or Premier plan (for SSO and IP Access Management)

## Quick Start

```bash
cd packs/sendgrid/terraform/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Profile Levels

Controls are applied cumulatively based on the `profile_level` variable:

| Level | Name | Controls |
|-------|------|----------|
| 1 | Baseline | API keys, teammate permissions, sender authentication, monitoring guidance |
| 2 | Hardened | Adds SSO, SSO teammates, event webhooks, API key alerts |
| 3 | Maximum Security | All L2 controls with strictest configuration |

```bash
# Apply L1 baseline controls
terraform apply -var="profile_level=1"

# Apply L2 hardened controls (includes L1)
terraform apply -var="profile_level=2"
```

## Controls

| File | Control | Level | Terraform Resources |
|------|---------|-------|---------------------|
| `hth-sendgrid-1.01-enable-two-factor-authentication.tf` | 1.1 Enable 2FA | L1 | Documentation only (SendGrid-enforced) |
| `hth-sendgrid-1.02-configure-saml-single-sign-on.tf` | 1.2 Configure SAML SSO | L2 | `sendgrid_sso_integration`, `sendgrid_sso_certificate` |
| `hth-sendgrid-1.03-configure-sso-teammates.tf` | 1.3 Configure SSO Teammates | L2 | `sendgrid_sso_teammate` |
| `hth-sendgrid-1.04-configure-ip-access-management.tf` | 1.4 IP Access Management | L2 | Documentation only (API/UI required) |
| `hth-sendgrid-2.01-use-api-keys-instead-of-passwords.tf` | 2.1 Use API Keys | L1 | `sendgrid_api_key` |
| `hth-sendgrid-2.02-implement-api-key-best-practices.tf` | 2.2 API Key Best Practices | L1 | Documentation only (operational) |
| `hth-sendgrid-2.03-implement-least-privilege-api-access.tf` | 2.3 Least Privilege API | L1 | Documentation only (enforced via 2.1 scopes) |
| `hth-sendgrid-2.04-configure-api-key-alerts.tf` | 2.4 API Key Alerts | L2 | Documentation only (external tooling) |
| `hth-sendgrid-3.01-secure-administrator-access.tf` | 3.1 Secure Admin Access | L1 | Documentation only (operational) |
| `hth-sendgrid-3.02-configure-teammate-permissions.tf` | 3.2 Teammate Permissions | L1 | `sendgrid_teammate` |
| `hth-sendgrid-3.03-configure-sender-authentication.tf` | 3.3 Sender Authentication | L1 | `sendgrid_sender_authentication`, `sendgrid_link_branding` |
| `hth-sendgrid-4.01-monitor-email-activity.tf` | 4.1 Monitor Email Activity | L1 | Documentation only (operational) |
| `hth-sendgrid-4.02-configure-event-webhooks.tf` | 4.2 Event Webhooks | L2 | `sendgrid_event_webhook` |
| `hth-sendgrid-4.03-monitor-for-compromised-accounts.tf` | 4.3 Monitor Compromised Accounts | L1 | Documentation only (operational) |

## Provider Limitations

The following controls require manual configuration via the SendGrid UI or API because the Terraform provider does not yet support them:

- **1.1 Two-Factor Authentication** — Enforced by SendGrid since Q4 2020; per-user phone/app setup required
- **1.4 IP Access Management** — Use the SendGrid UI or `POST /v3/access_settings/whitelist` API
- **2.4 API Key Alerts** — Requires external SIEM integration via event webhooks
- **4.1 Email Activity Monitoring** — Operational practice using Stats API and Activity Feed
- **4.3 Account Compromise Monitoring** — Operational practice; Terraform supports response (key rotation, drift detection)

## Outputs

After applying, key outputs include:

- `sso_audience_url` / `sso_single_signon_url` — Configure these in your IdP
- `api_key_values` — Sensitive; store in your secret manager
- `sender_authentication_dns` — DNS records to add to your domain
- `link_branding_dns` — DNS records for branded click tracking
- `event_webhook_public_key` — Use to verify webhook signatures
- `hardening_summary` — Overview of all controls applied

## Security Notes

- Never commit `terraform.tfvars` or `*.tfstate` files to version control
- Use environment variables for sensitive values in CI/CD:
  ```bash
  export TF_VAR_sendgrid_api_key="SG.xxxx..."
  export TF_VAR_sso_certificate="$(cat idp-cert.pem)"
  ```
- API key values are only available at creation time; store them immediately
- Rotate API keys by tainting the resource: `terraform taint 'sendgrid_api_key.managed["key"]'`
