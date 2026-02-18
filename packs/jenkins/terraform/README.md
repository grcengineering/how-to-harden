# Jenkins Hardening Code Pack - Terraform

Terraform configuration for hardening Jenkins following the [How to Harden Jenkins Guide](https://howtoharden.com/guides/jenkins/).

## Provider

This pack uses the [taiidani/jenkins](https://registry.terraform.io/providers/taiidani/jenkins/latest/docs) Terraform provider (`~> 0.10`) for managing Jenkins resources (folders, jobs, views, credentials) and generates [Jenkins Configuration as Code (JCasC)](https://www.jenkins.io/projects/jcasc/) YAML files and Groovy init scripts for system-level security settings.

## Architecture

The Jenkins Terraform provider manages **resource-level** configuration (folders, jobs, credentials, views). System-level security settings (authentication realm, authorization strategy, CSRF, agent protocols) are not exposed as provider resources. For those controls, this pack generates:

- **JCasC YAML files** in `generated/` -- deploy to `$JENKINS_HOME/casc_configs/`
- **Groovy init scripts** in `generated/init.groovy.d/` -- deploy to `$JENKINS_HOME/init.groovy.d/`

## Prerequisites

- Terraform >= 1.0
- Jenkins server with API access (username + password/API token)
- Required Jenkins plugins:
  - [Configuration as Code Plugin](https://plugins.jenkins.io/configuration-as-code/) (for JCasC YAML)
  - [Folders Plugin](https://plugins.jenkins.io/cloudbees-folder/) (for credential scoping)
  - [Matrix Authorization Strategy Plugin](https://plugins.jenkins.io/matrix-auth/) (for folder permissions)
  - [Audit Trail Plugin](https://plugins.jenkins.io/audit-trail/) (for Section 5.1)
- L2+ additional plugins:
  - [SAML Plugin](https://plugins.jenkins.io/saml/) or LDAP Plugin (for Section 1.2)
  - [Role-based Authorization Strategy Plugin](https://plugins.jenkins.io/role-strategy/) (for Section 2.3)
  - [Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/) or [Docker Plugin](https://plugins.jenkins.io/docker-plugin/) (for Section 3.3)

## Quick Start

```bash
# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your Jenkins server details
vi terraform.tfvars

# Initialize and apply
terraform init
terraform plan
terraform apply

# Deploy generated JCasC files to Jenkins
cp generated/*.yaml $JENKINS_HOME/casc_configs/
cp generated/init.groovy.d/*.groovy $JENKINS_HOME/init.groovy.d/

# Reload JCasC configuration
curl -X POST "${JENKINS_URL}/reload-configuration-as-code/" \
  -u "${JENKINS_USER}:${JENKINS_TOKEN}"
```

## Profile Levels

| Level | Name | Description |
|-------|------|-------------|
| 1 | Baseline | Essential controls for all organizations |
| 2 | Hardened | Adds SSO, RBAC, ephemeral agents, secure pipeline templates |
| 3 | Maximum Security | Strictest controls for regulated industries |

Levels are cumulative: L2 includes all L1 controls, L3 includes L1+L2.

```bash
# Apply L1 Baseline
terraform apply -var="profile_level=1"

# Apply L2 Hardened
terraform apply -var="profile_level=2"
```

## Controls

| File | Control | Level | Frameworks |
|------|---------|-------|------------|
| `hth-jenkins-1.01-enable-authentication.tf` | Enable Authentication | L1 | CIS 6.3, NIST IA-2 |
| `hth-jenkins-1.02-configure-sso.tf` | Configure LDAP or SAML SSO | L2 | CIS 6.3/12.5, NIST IA-2/IA-8 |
| `hth-jenkins-1.03-disable-remember-me.tf` | Disable Remember Me | L2 | CIS 6.2, NIST AC-12 |
| `hth-jenkins-2.01-configure-matrix-security.tf` | Matrix-Based Security | L1 | CIS 5.4, NIST AC-6 |
| `hth-jenkins-2.02-configure-project-matrix.tf` | Project-Based Matrix Auth | L2 | CIS 5.4, NIST AC-6(1) |
| `hth-jenkins-2.03-configure-rbac.tf` | Role-Based Access Control | L2 | CIS 5.4, NIST AC-6(1) |
| `hth-jenkins-2.04-restrict-script-console.tf` | Restrict Script Console | L1 | CIS 5.4, NIST AC-6(1) |
| `hth-jenkins-3.01-agent-controller-access.tf` | Agent-Controller Access Control | L1 | CIS 13.5, NIST AC-4 |
| `hth-jenkins-3.02-disable-builds-on-controller.tf` | Disable Builds on Controller | L1 | CIS 4.1, NIST CM-7 |
| `hth-jenkins-3.03-ephemeral-agents.tf` | Ephemeral Agents | L2 | CIS 4.1, NIST CM-6 |
| `hth-jenkins-3.04-secure-agent-communication.tf` | Secure Agent Communication | L1 | CIS 3.10, NIST SC-8 |
| `hth-jenkins-4.01-enable-csrf-protection.tf` | CSRF Protection | L1 | CIS 16.13, NIST SC-8 |
| `hth-jenkins-4.02-secure-credentials.tf` | Secure Credentials Management | L1 | CIS 3.11, NIST SC-12 |
| `hth-jenkins-4.03-pipeline-sandbox.tf` | Pipeline Sandbox | L1 | CIS 16.1, NIST CM-7 |
| `hth-jenkins-4.04-secure-jenkinsfile.tf` | Secure Jenkinsfile Configuration | L2 | CIS 16.9, NIST CM-3 |
| `hth-jenkins-5.01-enable-audit-logging.tf` | Audit Logging | L1 | CIS 8.2, NIST AU-2 |
| `hth-jenkins-5.02-keep-jenkins-updated.tf` | Keep Jenkins Updated | L1 | CIS 7.3, NIST SI-2 |

## Outputs

After applying, review the hardening summary:

```bash
terraform output hardening_summary
terraform output generated_casc_files
terraform output generated_groovy_scripts
```

## Security Note

The `terraform.tfvars` file contains sensitive values (Jenkins password/API token, LDAP credentials). Never commit it to version control. Use environment variables in production:

```bash
export TF_VAR_jenkins_password="your-api-token"
export TF_VAR_ldap_manager_password="your-ldap-password"
```
