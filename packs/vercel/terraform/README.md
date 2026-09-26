# Vercel Hardening Code Pack -- Terraform

> Part of the [How to Harden](https://howtoharden.com) project by [GRC Engineering](https://grc.engineering)

Terraform implementation of the [Vercel Hardening Guide](https://howtoharden.com/guides/vercel/). Applies security controls for authentication, RBAC, deployment protection, WAF, network security, secrets management, and monitoring.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.6 (the 2.1 `import` block builds its id from variables)
- [Vercel Terraform Provider](https://registry.terraform.io/providers/vercel/vercel/latest/docs) ~> 5.17 (validated against 5.17.1)
- Vercel API token with team admin permissions
- Vercel Pro or Enterprise plan (some controls require Enterprise)

## Quick Start

```bash
# 1. Clone and navigate to the code pack
cd packs/vercel/terraform/

# 2. Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# 3. Edit with your values (NEVER commit this file)
# Set at minimum: vercel_api_token, vercel_team_id, project_id, project_name
# (project_name must be that project's CURRENT name)

# 4. Initialize and apply
terraform init
terraform plan
terraform apply
```

## One Resource per Vercel Object

The provider treats each of these as a single object, so the pack declares each **once** and the other controls feed it through `locals`:

| Object | Resource (file) | Fed by |
|--------|-----------------|--------|
| Project | `vercel_project.hardened` (2.01), adopted with an `import` block so apply never creates a second project | 2.02, 2.04, 2.05 |
| Project firewall | `vercel_firewall_config.project` (3.01), created only when the firewall is managed; the provider PUTs the whole config | 3.02 |
| Team settings | `vercel_team_config.hardened` (1.01); updates send every attribute | 6.01 |

## Adopting Existing Objects Safely

The project, its firewall and Attack Challenge Mode already exist before this pack runs, so applying it must never weaken or reset them:

- **Project (2.01).** Only the hardening settings the pack declares are managed. The Git connection, framework, root directory, build commands, environment variables and every other setting are listed in `lifecycle.ignore_changes`. Without that list, the imported project's settings are planned to null, and the provider's update sends those nulls: a null `git_repository` unlinks the repository. The pack reads the current project (`data "vercel_project" "current"`) and stops at a precondition rather than remove Password Protection or Trusted IPs, narrow All Deployments protection, or rename the project. Below L2 it keeps the current skew protection, disabled previews and verified-commit settings.
- **Firewall (3.01/3.2).** Nothing is managed by default. Managing it (`firewall_enabled`, `blocked_ip_addresses` or `rate_limit_rules`) **replaces the whole firewall configuration**, including custom rules and IP blocks added in the dashboard and the `hth-*` rules the 3.3 and 9.1 API packs insert. Export the active config (`GET /v1/security/firewall/config/active`), declare every rule to keep, then set `firewall_replace_existing_config = true`. Use either this module or the 3.3/9.1 API packs for a project's custom rules, not both: the next `terraform apply` removes rules the API packs added.
- **Attack Challenge Mode (4.2).** Managed only while `attack_challenge_mode_enabled = true`, so an apply at the default never switches off a mode someone turned on during an attack.

**Upgrading from the 2.x pack:** the provider pin moved from `~> 2.0` to `~> 5.17`, `project_name` is now required, the `git_repository`/`git_provider`/`production_branch` variables are gone (the pack no longer manages the Git link), and 6.2 uses `vercel_project_deployment_retention` with `retention_*` periods (`1d`..`1y`). The 2.x pack did not pass `terraform validate`, so there is no prior state to migrate.

## Profile Levels

| Level | Name | Description |
|-------|------|-------------|
| L1 | Crawl | SAML SSO, team roles, fork protection, env var security, log drains, attack challenge mode |
| L2 | Walk | Access Groups, WAF with OWASP rulesets, IP blocking, rate limiting, sensitive env policy, deployment retention |
| L3 | Run | Secure Compute, trusted IPs, automation bypass disabled, strictest deployment controls |

```bash
# Apply L1 (default)
terraform apply -var="profile_level=1"

# Apply L2 (includes L1)
terraform apply -var="profile_level=2"

# Apply L3 (includes L1 + L2)
terraform apply -var="profile_level=3"
```

## Controls Implemented

| File | Section | Level | Description |
|------|---------|-------|-------------|
| `hth-vercel-1.01-enforce-sso-with-saml.tf` | 1.1 | L1 | SAML SSO enforcement (Enterprise) |
| `hth-vercel-1.03-enforce-least-privilege-rbac.tf` | 1.3 | L1/L2 | Team RBAC + Access Groups |
| `hth-vercel-2.01-configure-deployment-protection.tf` | 2.1 | L1/L2/L3 | Deployment protection, preview security, trusted IPs |
| `hth-vercel-2.02-harden-git-integration.tf` | 2.2 | L1/L2 | Fork protection, production-only deployments, verified commits |
| `hth-vercel-2.04-private-production-deployments.tf` | 2.4 | L2/L3 | All-deployments protection scope, production-only trusted IPs |
| `hth-vercel-2.05-enable-protected-source-maps.tf` | 2.5 | L1 | Protected Source Maps |
| `hth-vercel-3.01-enable-waf-managed-rulesets.tf` | 3.1 | L2 | WAF with OWASP managed rulesets |
| `hth-vercel-3.02-ip-blocking-rate-limiting.tf` | 3.2 | L1/L2 | IP blocking and rate limiting rules |
| `hth-vercel-4.01-enable-secure-compute.tf` | 4.1 | L3 | Secure Compute private network |
| `hth-vercel-4.02-ddos-attack-challenge-mode.tf` | 4.2 | L1 | Attack Challenge Mode |
| `hth-vercel-6.01-environment-variable-security.tf` | 6.1 | L1/L2 | Env var security, sensitive policy, IP privacy |
| `hth-vercel-6.02-deployment-retention-policy.tf` | 6.2 | L2 | Deployment retention and expiration |
| `hth-vercel-8.01-configure-log-drains-siem.tf` | 8.1 | L1/L2 | Log drains for SIEM integration |
| `hth-vercel-10.04-vcr-repository-private.tf` | 10.4 | L1 | Container Registry repositories kept private |

## API, CLI & Config Packs

Controls not configurable via Terraform have API, CLI, and config implementations. `cli/` holds only scripts that invoke the first-party `vercel` CLI; curl-only scripts are `api/`; repository audits and config emitters are `config/`.

| Directory | Section | Description |
|-----------|---------|-------------|
| `api/hth-vercel-1.02-*` | 1.2 | Directory Sync (SCIM) audit |
| `api/hth-vercel-1.04-*` | 1.4 | API token audit and project OIDC status |
| `api/hth-vercel-1.05-*` | 1.5 | Integrations, Git namespaces, deploy hooks, protection inventory |
| `api/hth-vercel-2.03-*` | 2.3 | Rolling release and skew protection audit |
| `api/hth-vercel-3.03-*` | 3.3 | Persistent-action WAF rules (mutating) |
| `api/hth-vercel-3.04-*` | 3.4 | AI Bots / Bot Protection managed rulesets (mutating) |
| `api/hth-vercel-8.02-*` | 8.2 | Audit events and drain status |
| `api/hth-vercel-8.04-*` | 8.4 | Drain signature receiver and delivery test |
| `api/hth-vercel-9.01-*` | 9.1 | Next.js header-strip WAF rules (mutating) and patch gate |
| `cli/hth-vercel-6.03-*` | 6.3 | Deploy hook rotation (`vercel deploy-hooks`) and leak scan |
| `cli/hth-vercel-7.01-*` | 7.1 | Subdomain takeover detection |
| `cli/hth-vercel-7.02-*` | 7.2 | TLS and certificate verification |
| `cli/hth-vercel-8.03-*` | 8.3 | Cron job secret management |
| `config/hth-vercel-5.01-*` | 5.1 | Security response headers (vercel.json) |
| `config/hth-vercel-6.04-*` | 6.4 | NEXT_PUBLIC_ secret-name scan |
| `config/hth-vercel-10.01-*` | 10.1 | `/_next/image` remotePatterns audit |
| `config/hth-vercel-10.02-*` | 10.2 | Middleware/proxy-only authorization audit |

## Edition Compatibility

| Control | Hobby | Pro | Enterprise |
|---------|-------|-----|------------|
| SAML SSO (1.1) | -- | Add-on | Yes |
| RBAC + Access Groups (1.3) | Basic | Extended | Full |
| Deployment Protection (2.1) | Standard | + Password | + Trusted IPs |
| WAF Managed Rulesets (3.1) | -- | -- | Yes |
| WAF Custom Rules (3.2) | 3 rules | 40 rules | 1,000 rules |
| Secure Compute (4.1) | -- | -- | Yes ($6.5K/yr) |
| Attack Challenge Mode (4.2) | Yes | Yes | Yes |
| Log Drains (8.1) | -- | Yes | Yes |
| Protected Source Maps (2.5) | Yes | Yes | Yes |

## Sensitive Values

Never commit secrets to version control. Use environment variables:

```bash
export TF_VAR_vercel_api_token="your-token-here"
export TF_VAR_preview_password="your-preview-password"
export TF_VAR_log_drain_secret="your-webhook-secret"
```

## File Structure

```text
packs/vercel/
  terraform/        # this module: providers.tf (~> 5.17), variables.tf, outputs.tf,
                    # terraform.tfvars.example, and one hth-vercel-N.NN-*.tf per control
  api/              # curl + jq against documented REST endpoints
  cli/              # first-party vercel CLI scripts
  config/           # vercel.json emitters and repository audits
  sdk/              # BotID application code (3.5)
```
