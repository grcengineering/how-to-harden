# How to Harden — Code Packs

Machine-readable security controls and executable automation bundles that complement the hardening guides on [howtoharden.com](https://howtoharden.com). Each pack converts guide controls into runnable code: Terraform modules, API scripts, SIEM queries, and incident response runbooks.

## What Are Code Packs?

Hardening guides tell you _what_ to configure and _why_. Code Packs give you the _how_ in a form machines can execute. Every control from a guide is represented twice:

1. **As a YAML definition** — structured metadata a CLI tool can consume for scanning and remediation.
2. **As runnable code** — shell scripts, Terraform modules, and SIEM queries you can use today without waiting for tooling.

Code Packs are profile-level gated. Set `HTH_PROFILE_LEVEL=1` for baseline controls, `2` for hardened, or `3` for maximum security. Every script and Terraform module respects this variable, so you apply exactly the controls appropriate for your environment.

## Architecture

Two-layer design:

**Layer 1 — Controls (`controls/`).**
Machine-readable YAML definitions with audit checks (jq assertions against API responses), remediation steps (API calls and Terraform resources), and compliance mappings (SOC 2, NIST 800-53, ISO 27001, PCI DSS, DISA STIG). Designed for the future `hth` CLI tool (`hth scan`, `hth harden`).

**Layer 2 — Automation (`terraform/`, `api/`, `siem/`, `scripts/`).**
Immediately usable code organized by function. Terraform modules for declarative infrastructure, shell scripts for API-based hardening, SIEM queries for detection coverage, and operational utilities including incident response runbooks. All gated by profile level.

```
packs/
  schema/                          # JSON Schema for control definitions
    control.schema.json
  {vendor}/
    README.md                      # Vendor-specific docs, prerequisites, quick start
    controls/                      # Machine-readable YAML control definitions
    terraform/                     # Terraform modules with profile_level variable
    api/                           # Shell scripts for API-based hardening
    siem/                          # Detection queries (structured YAML)
    scripts/                       # Operational utilities and IR runbooks
```

## Available Packs

| Vendor | Controls | Terraform | API Scripts | SIEM Queries | IR Runbooks |
|--------|----------|-----------|-------------|--------------|-------------|
| [Okta](okta/) | 34 | 11 resources | 8 sections | 30 queries | 3 runbooks |

## Pack Structure

Each vendor pack follows this layout:

```
packs/{vendor}/
├── README.md                    # Vendor-specific documentation
├── controls/                    # YAML control definitions (machine-readable)
│   └── {section}-{name}.yaml
├── terraform/                   # Terraform modules
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   └── terraform.tfvars.example
├── api/                         # API automation scripts
│   ├── common.sh                # Shared utilities (logging, API helpers, profile gating)
│   ├── validate.sh              # Read-only audit of all controls
│   └── {NN}-{section}.sh        # Section-specific hardening scripts
├── siem/                        # Detection queries
│   └── queries.yaml             # Structured queries with severity and MITRE mappings
└── scripts/                     # Operational utilities
    ├── har-sanitize.sh
    └── incident-response/
        └── {scenario}.sh
```

## Quick Start

### Prerequisites

- `bash`, `curl`, `jq` (for API scripts and validation)
- [Terraform](https://www.terraform.io/) >= 1.0 (for Terraform modules)
- Vendor API token with administrative permissions

### API Scripts

```bash
export OKTA_DOMAIN="yourorg.okta.com"
export OKTA_API_TOKEN="your-api-token"
export HTH_PROFILE_LEVEL=1  # 1=Baseline, 2=Hardened, 3=Maximum

# Audit your tenant (read-only)
bash packs/okta/api/validate.sh

# Apply section-specific hardening
bash packs/okta/api/01-auth-controls.sh
bash packs/okta/api/02-network-controls.sh
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

Example control structure:

```yaml
id: okta-1.1
title: Enforce Phishing-Resistant MFA
profile_level: 1
severity: critical
audit:
  api: GET /api/v1/policies?type=MFA_ENROLL
  check: '.[] | .settings.authenticators[] | select(.key=="okta_verify") | .enroll.self == "REQUIRED"'
remediate:
  api: PUT /api/v1/policies/{id}
  terraform: okta_policy_mfa.require_phishing_resistant
compliance:
  soc2: [CC6.1]
  nist_800_53: [IA-2(6)]
  iso_27001: [A.9.4.2]
  pci_dss: ["8.4.2"]
```

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines. To add a new vendor pack:

1. Create the directory structure: `packs/{vendor}/` with `controls/`, `terraform/`, `api/`, `siem/`, `scripts/` subdirectories.
2. Create YAML controls following `schema/control.schema.json`.
3. Implement API scripts following the `common.sh` pattern for shared utilities.
4. Add Terraform modules with `profile_level` variable gating.
5. Write SIEM queries in structured YAML with severity and MITRE ATT&CK mappings.
6. Submit a PR with the vendor name in the title.

## License

MIT — See [LICENSE](../LICENSE) in the repository root.
