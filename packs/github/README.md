# GitHub Hardening Code Pack

Runnable security hardening artifacts for [GitHub](https://howtoharden.com/guides/github/). Implements 25 controls from the GitHub hardening guide across authentication, secret management, pipeline security, dependency management, and operational security.

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| YAML Controls | 25 | Machine-readable definitions with audit checks, remediation, and compliance mappings |
| Terraform Resources | -- | Coming soon |
| API Scripts | -- | Coming soon |
| SIEM/Sigma Rules | -- | Coming soon |

## Prerequisites

- GitHub organization with **Owner** access
- Personal access token or GitHub App with appropriate permissions
- [GitHub CLI](https://cli.github.com/) (`gh`) installed
- `bash`, `curl`, `jq` (for API scripts)

## Quick Start

### 1. HTH CLI (Audit)

```bash
hth scan github --org your-org --token $GITHUB_TOKEN --level 1
```

### 2. Individual Controls

Each control is a standalone YAML definition in `controls/`:

```bash
ls controls/
# hth-github-1.01-enforce-2fa-for-org-members.yaml
# hth-github-1.02-restrict-default-repository-permissions.yaml
# ...
```

## Profile Levels

| Level | Variable Value | What Gets Applied |
|-------|---------------|-------------------|
| L1 -- Baseline | `1` | 2FA enforcement, repository permissions, secret scanning, branch protection, vulnerability alerts, wiki controls |
| L2 -- Hardened | `2` | L1 + action restrictions, SHA pinning, signed commits, code scanning, deploy key audits, environment protection |
| L3 -- Maximum Security | `3` | L1 + L2 + advanced controls |

## Directory Structure

```
github/
├── README.md
├── controls/                        # 25 YAML control definitions
│   ├── hth-github-1.01-enforce-2fa-for-org-members.yaml
│   ├── hth-github-1.02-restrict-default-repository-permissions.yaml
│   ├── ...
│   └── hth-github-5.05-protect-deployment-environments.yaml
├── terraform/                       # Coming soon
├── api/                             # Coming soon
├── siem/sigma/                      # Coming soon
└── scripts/                         # Coming soon
```

## Controls

### Section 1 -- Authentication & Access (6 controls)

| # | Control | Level |
|---|---------|-------|
| 1.1 | Enforce 2FA for Org Members | L1 |
| 1.2 | Restrict Default Repository Permissions | L1 |
| 1.3 | Restrict Repository Creation | L1 |
| 1.4 | Disable Private Fork Creation | L1 |
| 1.5 | Require Commit Signoff | L2 |
| 1.6 | Restrict Org Member Repository Deletion | L1 |

### Section 2 -- Secret Management (4 controls)

| # | Control | Level |
|---|---------|-------|
| 2.1 | Enable Secret Scanning | L1 |
| 2.2 | Enable Dependabot Security Updates | L1 |
| 2.3 | Enable Secret Scanning Non-Provider Patterns | L2 |
| 2.4 | Enable Secret Scanning Validity Checks | L2 |

### Section 3 -- Pipeline Security (7 controls)

| # | Control | Level |
|---|---------|-------|
| 3.1 | Enable Branch Protection on Default Branch | L1 |
| 3.2 | Restrict Actions to Verified Creators | L2 |
| 3.3 | Pin Actions to SHA | L2 |
| 3.4 | Restrict Org Actions Permissions | L2 |
| 3.5 | Enable Code Scanning Default Setup | L2 |
| 3.6 | Require CODEOWNERS File | L2 |
| 3.7 | Require Signed Commits | L3 |

### Section 4 -- Dependency Management (3 controls)

| # | Control | Level |
|---|---------|-------|
| 4.1 | Enable Vulnerability Alerts | L1 |
| 4.2 | Review Open Dependabot Alerts | L1 |
| 4.3 | Audit Deploy Keys | L2 |

### Section 5 -- Operational Security (5 controls)

| # | Control | Level |
|---|---------|-------|
| 5.1 | Disable Wiki on Non-Documentation Repos | L1 |
| 5.2 | Enable Delete Branch on Merge | L1 |
| 5.3 | Audit Org Webhooks | L2 |
| 5.4 | Audit Outside Collaborators | L1 |
| 5.5 | Protect Deployment Environments | L2 |

## Related

- [GitHub Hardening Guide](https://howtoharden.com/guides/github/) -- Full guide with ClickOps + Code implementations
- [How to Harden](https://howtoharden.com) -- All vendor hardening guides
- [Code Packs Overview](../README.md) -- Architecture and schema documentation
