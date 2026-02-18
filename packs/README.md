# How to Harden -- Code Packs

Machine-readable security controls and executable automation bundles that complement the hardening guides on [howtoharden.com](https://howtoharden.com). Each pack converts guide controls into runnable code across multiple language types -- API scripts, CLI scripts, SDK scripts, Config-as-Code (Terraform), DB queries, and Sigma detection rules.

## What Are Code Packs?

Hardening guides tell you _what_ to configure and _why_. Code Packs give you the _how_ in a form machines can execute. Every control from a guide is represented twice:

1. **As a YAML definition** -- structured metadata a CLI tool can consume for scanning and remediation.
2. **As runnable code** -- scripts, modules, queries, and detection rules you can use today.

Code Packs are profile-level gated. Set `HTH_PROFILE_LEVEL=1` for baseline controls, `2` for hardened, or `3` for maximum security. Every script and module respects this variable, so you apply exactly the controls appropriate for your environment.

## Code Pack Ontology

Code Packs are classified along two axes: **what the code does** (Functional Type) and **how it's written** (Language Type).

### Functional Types

| Functional Type | Purpose | Verb | Example |
|-----------------|---------|------|---------|
| **Enforcement** | Remediate or implement a control | Configure, create, enable, restrict | Terraform resource creating an MFA policy |
| **Verification** | Scan or audit current state (read-only) | Check, list, get, validate | API call asserting MFA is enabled for all users |
| **Drift Detection** | Alert when configuration changes from hardened state | Detect config change | Sigma rule firing on `policy.lifecycle.update` |
| **Threat Detection** | Alert on attack patterns or anomalous behavior | Detect attack/anomaly | Sigma rule firing on `user.session.impersonation` |

### Language Types

| Language Type | Directory | Extensions | Example Tools |
|---------------|-----------|------------|---------------|
| **API Scripts** | `api/` | `.sh` | bash + curl + jq against vendor REST APIs |
| **CLI Scripts** | `cli/` | `.sh` | Vendor-native CLIs (`gh`, `op`, `gcloud`, `az`, `okta`) |
| **SDK Scripts** | `sdk/` | `.py`, `.ps1`, `.go` | Python, PowerShell, Go vendor SDKs |
| **Config-as-Code** | `terraform/` | `.tf` | Terraform, Pulumi, CloudFormation |
| **DB Queries** | `db/` | `.sql`, `.js` | SQL (Snowflake, Databricks), NoSQL (MongoDB) |
| **Detection Rules** | `siem/sigma/` | `.yml` | Sigma (converts to Splunk, Elastic, Sentinel, etc.) |

### The Matrix

Not every cell is populated for every vendor -- the matrix shows what is _possible_. A well-developed vendor pack fills all applicable cells.

```
                  ┌──────────┬──────────┬──────────┬───────────────┬────────┬───────────┐
                  │ API      │ CLI      │ SDK      │ Config-as-    │ DB     │ Detection │
                  │ Scripts  │ Scripts  │ Scripts  │ Code (TF)     │ Queries│ Rules     │
┌─────────────────┼──────────┼──────────┼──────────┼───────────────┼────────┼───────────┤
│ Enforcement     │    ✓     │    ✓     │    ✓     │      ✓        │   ✓    │           │
│ (remediate)     │          │          │          │               │        │           │
├─────────────────┼──────────┼──────────┼──────────┼───────────────┼────────┼───────────┤
│ Verification    │    ✓     │    ✓     │    ✓     │               │   ✓    │           │
│ (audit)         │          │          │          │               │        │           │
├─────────────────┼──────────┼──────────┼──────────┼───────────────┼────────┼───────────┤
│ Drift Detection │          │          │          │               │   ✓    │     ✓     │
│ (config change) │          │          │          │               │        │           │
├─────────────────┼──────────┼──────────┼──────────┼───────────────┼────────┼───────────┤
│ Threat Detection│          │          │          │               │   ✓    │     ✓     │
│ (attack/anomaly)│          │          │          │               │        │           │
└─────────────────┴──────────┴──────────┴──────────┴───────────────┴────────┴───────────┘
```

**Reading the matrix:** A `✓` means this combination is valid. For example, Enforcement can be implemented via API scripts, CLI scripts, SDK scripts, Config-as-Code, or DB queries -- but not via detection rules (which are read-only by nature). Drift and Threat Detection use detection rules (Sigma) and DB queries (SIEM/warehouse queries), but not enforcement tools.

### Examples by Cell

| Function | Language | Example |
|----------|----------|---------|
| Enforcement x API | `curl -X PUT "$OKTA_DOMAIN/api/v1/policies/$ID" -d '{"status":"ACTIVE"}'` |
| Enforcement x CLI | `gh api orgs/{org}/actions/permissions -X PUT -f allowed_actions=selected` |
| Enforcement x SDK | `Set-MgIdentityConditionalAccessPolicy -State "enabled"` (PowerShell) |
| Enforcement x Config-as-Code | `resource "okta_authenticator" "fido2" { status = "ACTIVE" }` |
| Enforcement x DB | `ALTER ACCOUNT SET NETWORK_POLICY = 'restrict_access';` (Snowflake SQL) |
| Verification x API | `curl -s "$OKTA_DOMAIN/api/v1/policies" \| jq '.[] \| select(.status=="ACTIVE")'` |
| Verification x CLI | `gh api orgs/{org}/actions/permissions \| jq '.allowed_actions'` |
| Verification x SDK | `Get-MgIdentityConditionalAccessPolicy \| Where-Object {$_.State -eq "enabled"}` |
| Verification x DB | `SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.NETWORK_POLICIES;` |
| Drift Detection x Sigma | `detection: selection: eventType: policy.lifecycle.update` |
| Drift Detection x DB | `SELECT * FROM okta_system_log WHERE eventType = 'policy.lifecycle.update'` |
| Threat Detection x Sigma | `detection: selection: eventType: user.session.impersonation` |
| Threat Detection x DB | `SELECT * FROM okta_system_log WHERE eventType LIKE 'user.account.lock%'` |

## Architecture

Two-layer design:

**Layer 1 -- Controls (`controls/`).**
Machine-readable YAML definitions with audit checks (jq assertions against API responses), remediation steps (API calls and Terraform resources), and compliance mappings (SOC 2, NIST 800-53, ISO 27001, PCI DSS, DISA STIG). Designed for the `hth` CLI tool (`hth scan`, `hth harden`).

**Layer 2 -- Automation (`terraform/`, `api/`, `cli/`, `sdk/`, `db/`, `siem/`, `scripts/`).**
Immediately usable code organized by language type. Each file maps to a single control, so you can selectively implement one control at a time, several, or all of them at once.

```
packs/
  schema/                                            # JSON Schema for control definitions
    control.schema.json
  {vendor}/
    README.md                                        # Vendor-specific docs and quick start
    controls/                                        # Machine-readable YAML control definitions
      hth-{vendor}-{section}-{name}.yaml
    terraform/                                       # Config-as-Code (Enforcement)
      providers.tf                                   # Shared provider configuration
      variables.tf                                   # Shared input variables
      outputs.tf                                     # Shared output values
      hth-{vendor}-{section}-{name}.tf               # One file per control
    api/                                             # API scripts (Enforcement + Verification)
      common.sh                                      # Shared utilities
      hth-{vendor}-validate.sh                       # Read-only audit (Verification)
      hth-{vendor}-{section}-{name}.sh               # One script per control (Enforcement)
    cli/                                             # CLI scripts (Enforcement + Verification)
      hth-{vendor}-{section}-{name}.sh               # Vendor-native CLI commands
    sdk/                                             # SDK scripts (Enforcement + Verification)
      hth-{vendor}-{section}-{name}.py               # Python SDK
      hth-{vendor}-{section}-{name}.ps1              # PowerShell SDK
    db/                                              # DB queries (Enforcement + Verification + Detection)
      hth-{vendor}-{section}-{name}.sql              # SQL/NoSQL queries
    siem/sigma/                                      # Detection rules (Drift + Threat Detection)
      hth-{vendor}-{section}-{name}.yml              # One rule per control
    scripts/                                         # Operational utilities and IR runbooks
      hth-{vendor}-{utility}.sh
      incident-response/
        hth-{vendor}-ir-{scenario}.sh
```

## Naming Convention

All files follow: `hth-{vendor}-{section}-{control-title}.{ext}`

| Type | Directory | Example |
|------|-----------|---------|
| Control | `controls/` | `hth-okta-1.01-enforce-phishing-resistant-mfa.yaml` |
| Terraform | `terraform/` | `hth-okta-1.01-enforce-phishing-resistant-mfa.tf` |
| API Script | `api/` | `hth-okta-1.01-enforce-phishing-resistant-mfa.sh` |
| CLI Script | `cli/` | `hth-github-1.01-enforce-2fa-for-org-members.sh` |
| SDK Script | `sdk/` | `hth-entra-1.01-enforce-phishing-resistant-mfa.ps1` |
| DB Query | `db/` | `hth-snowflake-2.01-enforce-network-policy.sql` |
| Sigma Rule | `siem/sigma/` | `hth-okta-1.01-enforce-phishing-resistant-mfa.yml` |
| IR Runbook | `scripts/incident-response/` | `hth-okta-ir-compromised-admin.sh` |

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

1. Create the directory structure: `packs/{vendor}/` with subdirectories for each applicable language type (see Architecture above).
2. Create YAML controls following `schema/control.schema.json`.
3. Implement **enforcement** code in one or more language types (API, CLI, SDK, Terraform, DB) -- more is better.
4. Implement **verification** code to audit current state (read-only checks).
5. Write **detection rules** (Sigma for SIEM, DB queries for data warehouses) for drift and threat detection.
6. Not every language type applies to every vendor. Use the ontology matrix to determine which cells are relevant.
7. Submit a PR with the vendor name in the title.

## License

MIT -- See [LICENSE](../LICENSE) in the repository root.
