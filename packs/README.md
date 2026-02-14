# How to Harden -- Code Packs

Machine-readable security controls and executable automation bundles that complement the hardening guides on [howtoharden.com](https://howtoharden.com). Each pack converts guide controls into runnable code: Terraform, API scripts, Sigma detection rules, and incident response runbooks.

## What Are Code Packs?

Hardening guides tell you _what_ to configure and _why_. Code Packs give you the _how_ in a form machines can execute. Every control from a guide is represented twice:

1. **As a YAML definition** -- structured metadata a CLI tool can consume for scanning and remediation.
2. **As runnable code** -- shell scripts, Terraform files, and Sigma detection rules you can use today.

Code Packs are profile-level gated. Set `HTH_PROFILE_LEVEL=1` for baseline controls, `2` for hardened, or `3` for maximum security. Every script and Terraform file respects this variable, so you apply exactly the controls appropriate for your environment.

## Architecture

Two-layer design:

**Layer 1 -- Controls (`controls/`).**
Machine-readable YAML definitions with audit checks (jq assertions against API responses), remediation steps (API calls and Terraform resources), and compliance mappings (SOC 2, NIST 800-53, ISO 27001, PCI DSS, DISA STIG). Designed for the `hth` CLI tool (`hth scan`, `hth harden`).

**Layer 2 -- Automation (`terraform/`, `api/`, `siem/`, `scripts/`).**
Immediately usable code organized by function. Each file maps to a single control, so you can selectively implement one control at a time, several, or all of them at once.

```
packs/
  schema/                                            # JSON Schema for control definitions
    control.schema.json
  {vendor}/
    README.md                                        # Vendor-specific docs and quick start
    controls/                                        # Machine-readable YAML control definitions
      hth-{vendor}-{section}-{name}.yaml
    terraform/                                       # Per-control Terraform files
      providers.tf                                   # Shared provider configuration
      variables.tf                                   # Shared input variables
      outputs.tf                                     # Shared output values
      hth-{vendor}-{section}-{name}.tf               # One file per control
    api/                                             # Per-control API scripts
      common.sh                                      # Shared utilities
      hth-{vendor}-validate.sh                       # Read-only audit
      hth-{vendor}-{section}-{name}.sh               # One script per control
    siem/sigma/                                      # Per-control Sigma detection rules
      hth-{vendor}-{section}-{name}.yml              # One rule per control
    scripts/                                         # Operational utilities and IR runbooks
      hth-{vendor}-{utility}.sh
      incident-response/
        hth-{vendor}-ir-{scenario}.sh
```

## Naming Convention

All files follow: `hth-{vendor}-{section}-{control-title}.{ext}`

| Type | Example |
|------|---------|
| Control | `hth-okta-1.01-enforce-phishing-resistant-mfa.yaml` |
| Terraform | `hth-okta-1.01-enforce-phishing-resistant-mfa.tf` |
| API Script | `hth-okta-1.01-enforce-phishing-resistant-mfa.sh` |
| Sigma Rule | `hth-okta-1.01-enforce-phishing-resistant-mfa.yml` |
| IR Runbook | `hth-okta-ir-compromised-admin.sh` |

Multi-rule controls use letter suffixes: `-b`, `-c`, `-d`, `-e`.

## Available Packs

| Vendor | Controls | Terraform | API Scripts | Sigma Rules | IR Runbooks |
|--------|----------|-----------|-------------|-------------|-------------|
| [Okta](okta/) | 34 | 11 files | 22 scripts | 24 rules | 3 runbooks |
| [GitHub](github/) | 25 | -- | -- | -- | -- |

## Quick Start

### Prerequisites

- `bash`, `curl`, `jq` (for API scripts and validation)
- [Terraform](https://www.terraform.io/) >= 1.0 (for Terraform files)
- [sigma-cli](https://github.com/SigmaHQ/sigma-cli) (for Sigma rule conversion)
- Vendor API token with administrative permissions

### API Scripts

```bash
export OKTA_DOMAIN="yourorg.okta.com"
export OKTA_API_TOKEN="your-api-token"
export HTH_PROFILE_LEVEL=1  # 1=Baseline, 2=Hardened, 3=Maximum

# Audit your tenant (read-only)
bash packs/okta/api/hth-okta-validate.sh

# Apply a single control
bash packs/okta/api/hth-okta-1.01-enforce-phishing-resistant-mfa.sh

# Apply all controls at once
for f in packs/okta/api/hth-okta-[0-9]*.sh; do bash "$f"; done
```

### Terraform

```bash
cd packs/okta/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set okta_domain and okta_api_token

terraform init
terraform plan -var="profile_level=1"   # Preview L1 changes
terraform apply -var="profile_level=1"  # Apply L1 (Baseline)
```

### Sigma Rules

```bash
# Convert all rules to Splunk SPL
sigma convert -t splunk packs/okta/siem/sigma/

# Convert a single control's detection rule
sigma convert -t elastic_lucene packs/okta/siem/sigma/hth-okta-1.01-enforce-phishing-resistant-mfa.yml
```

## Profile Levels

Controls are tagged with profile levels that are cumulative:

| Level | Name | Description |
|-------|------|-------------|
| L1 | Baseline | Essential controls for all organizations |
| L2 | Hardened | Enhanced controls for security-sensitive environments |
| L3 | Maximum Security | Strictest controls for regulated industries |

L2 includes all L1 controls. L3 includes all L1 + L2 controls. Set the level once via environment variable or Terraform variable and every script respects it.

## Control Schema

Controls follow the JSON Schema defined in [`schema/control.schema.json`](schema/control.schema.json). Key fields:

| Field | Purpose |
|-------|---------|
| `id` | Unique identifier (e.g., `okta-1.1`) |
| `title` | Human-readable control name |
| `profile_level` | Minimum level: `1` (Baseline), `2` (Hardened), `3` (Maximum Security) |
| `severity` | Impact rating: `critical`, `high`, `medium`, `low` |
| `audit` | jq-based API checks returning `true`/`false` |
| `remediate` | API calls and Terraform resources to fix non-compliant state |
| `compliance` | SOC 2, NIST 800-53, ISO 27001, PCI DSS, DISA STIG mappings |

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines. To add a new vendor pack:

1. Create the directory structure: `packs/{vendor}/` with `controls/`, `terraform/`, `api/`, `siem/sigma/`, `scripts/` subdirectories.
2. Create YAML controls following `schema/control.schema.json`.
3. Implement per-control API scripts that source `common.sh`.
4. Add per-control Terraform files with shared `providers.tf`/`variables.tf`/`outputs.tf`.
5. Write Sigma detection rules with MITRE ATT&CK mappings.
6. Submit a PR with the vendor name in the title.

## License

MIT -- See [LICENSE](../LICENSE) in the repository root.
