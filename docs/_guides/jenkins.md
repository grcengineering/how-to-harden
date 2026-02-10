---
layout: guide
title: "Jenkins Hardening Guide"
vendor: "Jenkins"
slug: "jenkins"
tier: "2"
category: "DevOps & Engineering"
description: "CI/CD security hardening for Jenkins including authorization, agent security, and pipeline protection"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Jenkins is the most widely used open-source CI/CD automation server, powering build pipelines for **millions of projects** across enterprises worldwide. As a critical component deeply integrated into software delivery processes, Jenkins has access to source code, deployment credentials, and production systems. A single misconfiguration can compromise the entire build environment and supply chain.

### Intended Audience
- Security engineers managing CI/CD infrastructure
- DevOps administrators configuring Jenkins
- GRC professionals assessing build security
- Platform engineers implementing secure pipelines

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Jenkins security configurations including authentication, authorization, agent security, and pipeline hardening for both Jenkins Controller and Jenkins Cloud deployments.

---

## Table of Contents

1. [Authentication & Access Control](#1-authentication--access-control)
2. [Authorization & Permissions](#2-authorization--permissions)
3. [Controller & Agent Security](#3-controller--agent-security)
4. [Pipeline Security](#4-pipeline-security)
5. [Monitoring & Compliance](#5-monitoring--compliance)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Control

### 1.1 Enable Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Enable authentication to prevent anonymous access to Jenkins. By default, older Jenkins installations may allow anonymous access.

#### Rationale
**Why This Matters:**
- Anonymous access allows anyone to view jobs, credentials, and configurations
- Attackers can trigger builds or modify pipelines without authentication
- Authentication is the foundation for authorization controls

#### ClickOps Implementation

**Step 1: Enable Security**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Check **Enable security** (if not already enabled)
3. Configure security realm (authentication method)

**Step 2: Configure Security Realm**
1. Select appropriate security realm:
   - **Jenkins' own user database:** For small deployments
   - **LDAP:** For enterprise directory integration
   - **SAML 2.0:** For SSO with identity providers (recommended)
2. Configure realm settings

**Step 3: Disable Anonymous Access**
1. Under Authorization, ensure anonymous users have no permissions
2. Do not select "Anyone can do anything"
3. Do not select "Logged-in users can do anything" (see 2.1)

**Time to Complete:** ~30 minutes

---

### 1.2 Configure LDAP or SAML SSO

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure centralized authentication using LDAP or SAML SSO for enterprise identity management.

#### Prerequisites
- [ ] LDAP directory or SAML IdP available
- [ ] LDAP Plugin or SAML Plugin installed

#### ClickOps Implementation (SAML)

**Step 1: Install SAML Plugin**
1. Navigate to: **Manage Jenkins** → **Plugins** → **Available plugins**
2. Search for "SAML"
3. Install **SAML Single Sign On(SSO)** plugin
4. Restart Jenkins

**Step 2: Configure SAML**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Select **SAML 2.0** as Security Realm
3. Configure:
   - IdP Metadata URL or XML
   - Username attribute
   - Email attribute
   - Group attribute (for role mapping)
4. Configure SP settings and download metadata

**Step 3: Configure IdP**
1. Create application in IdP
2. Upload Jenkins SP metadata
3. Configure attribute mappings
4. Assign users/groups

**ClickOps Implementation (LDAP)

**Step 1: Configure LDAP**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Select **LDAP** as Security Realm
3. Configure:
   - Server: `ldaps://ldap.example.com:636`
   - Root DN: `dc=example,dc=com`
   - User search base: `ou=users`
   - User search filter: `uid={0}`
   - Group search base: `ou=groups`
4. Test LDAP connection

---

### 1.3 Disable Remember Me

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Disable the "Remember me" feature to prevent persistent authentication tokens.

#### ClickOps Implementation

**Step 1: Disable Remember Me**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Uncheck **Allow users to sign up** (if using Jenkins user database)
3. Configure session timeout

**Step 2: Configure Session Settings**
1. Edit `jenkins.xml` or use System Properties:
```groovy
// In init.groovy.d/disable-remember-me.groovy
import jenkins.model.Jenkins
Jenkins.instance.setDisableRememberMe(true)
Jenkins.instance.save()
```

---

## 2. Authorization & Permissions

### 2.1 Configure Matrix-Based Security

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure Matrix-based security for fine-grained permission control. This is recommended over "Logged-in users can do anything."

#### Rationale
**Why This Matters:**
- "Logged-in users can do anything" gives all authenticated users admin access
- Combined with open signup, anyone can become an admin
- Matrix security enables granular permission control

#### ClickOps Implementation

**Step 1: Enable Matrix Authorization**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Under Authorization, select **Matrix-based security**

**Step 2: Configure Permissions**
1. Add users and groups to the matrix
2. Assign minimum necessary permissions:

| Permission | Admins | Developers | Viewers |
|-----------|--------|------------|---------|
| Overall/Administer | ✅ | ❌ | ❌ |
| Overall/Read | ✅ | ✅ | ✅ |
| Job/Build | ✅ | ✅ | ❌ |
| Job/Configure | ✅ | ❌ | ❌ |
| Job/Read | ✅ | ✅ | ✅ |
| Credentials/View | ✅ | ❌ | ❌ |

**Step 3: Remove Default Authenticated Group**
1. Remove or restrict the `authenticated` group permissions
2. Grant permissions to specific groups/users only

---

### 2.2 Configure Project-Based Matrix Authorization

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Enable project-based authorization for per-project access control.

#### Prerequisites
- [ ] Matrix Authorization Strategy Plugin installed

#### ClickOps Implementation

**Step 1: Enable Project-Based Matrix**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Select **Project-based Matrix Authorization Strategy**

**Step 2: Configure Global Permissions**
1. Set minimal global permissions
2. Most permissions will be set at project level

**Step 3: Configure Project Permissions**
1. Navigate to: **Job** → **Configure** → **Enable project-based security**
2. Add users/groups with project-specific permissions
3. Example: "Joe can access projects A, B, and C, but not D"

---

### 2.3 Configure Role-Based Access Control

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Implement role-based access control for scalable permission management.

#### Prerequisites
- [ ] Role-based Authorization Strategy Plugin installed

#### ClickOps Implementation

**Step 1: Enable Role-Based Strategy**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Select **Role-Based Strategy**

**Step 2: Define Roles**
1. Navigate to: **Manage Jenkins** → **Manage and Assign Roles** → **Manage Roles**
2. Create global roles:
   - `admin`: Full permissions
   - `developer`: Build and read permissions
   - `viewer`: Read-only permissions

**Step 3: Create Project Roles**
1. Create item roles with patterns:
   - Role: `team-a-dev`, Pattern: `team-a-.*`
   - Role: `team-b-dev`, Pattern: `team-b-.*`
2. Assign item-specific permissions

**Step 4: Assign Roles**
1. Navigate to: **Manage and Assign Roles** → **Assign Roles**
2. Assign global roles to users/groups
3. Assign item roles to users/groups

---

### 2.4 Restrict Script Console Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Restrict access to the Script Console to administrators only.

#### Rationale
**Why This Matters:**
- Script Console provides Groovy script execution
- Can access all Jenkins internals, credentials, and system
- Unlimited code execution capability

#### ClickOps Implementation

**Step 1: Verify Script Console Permissions**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. In authorization matrix, ensure only admins have `Overall/Administer`
3. Script Console requires `Overall/Administer` permission

**Step 2: Audit Script Console Access**
1. Review who has admin access
2. Consider separate admin accounts for privileged operations
3. Log and alert on Script Console usage

---

## 3. Controller & Agent Security

### 3.1 Enable Agent to Controller Access Control

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-4 |

#### Description
Enable Agent → Controller Access Control to prevent compromised agents from attacking the controller.

#### Rationale
**Why This Matters:**
- Agent processes could be taken over by malicious users
- Without controls, agents can send commands to controller
- This prevents agents from accessing sensitive controller data

#### ClickOps Implementation

**Step 1: Enable Access Control**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Under **Agent → Controller Security**, enable access control
3. Configure allowed/denied commands

**Step 2: Review Allowed Commands**
1. Navigate to: **Manage Jenkins** → **Security** → **Agent → Controller Security**
2. Review whitelisted file path rules
3. Review whitelisted commands
4. Remove unnecessary allowances

---

### 3.2 Disable Builds on Controller

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-7 |

#### Description
Configure Jenkins to run builds only on agents, not on the controller node.

#### Rationale
**Why This Matters:**
- Controller has access to all configurations, credentials, and secrets
- Builds running on controller can access sensitive data
- Compromised builds can attack Jenkins internals

#### ClickOps Implementation

**Step 1: Configure Controller Executors**
1. Navigate to: **Manage Jenkins** → **Nodes** → **Built-In Node** → **Configure**
2. Set **Number of executors** to **0**
3. Save configuration

**Step 2: Configure Labels**
1. Ensure jobs are configured to run on specific agent labels
2. Never use "any" or empty label restrictions

---

### 3.3 Use Ephemeral Agents

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-6 |

#### Description
Use ephemeral (disposable) agents that are created fresh for each build.

#### ClickOps Implementation

**Step 1: Configure Cloud Agents**
1. Navigate to: **Manage Jenkins** → **Clouds**
2. Configure cloud provider:
   - Kubernetes
   - Amazon EC2
   - Docker
3. Configure agent templates

**Step 2: Kubernetes Pod Template Example**
1. Install Kubernetes Plugin
2. Configure pod template:
```yaml
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    resources:
      limits:
        memory: "512Mi"
        cpu: "500m"
```

**Step 3: Configure Auto-Scaling**
1. Set minimum instances to 0
2. Configure scale-up triggers
3. Set idle timeout for termination

---

### 3.4 Secure Agent Communication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | SC-8 |

#### Description
Secure communication between agents and controller using JNLP over TLS.

#### ClickOps Implementation

**Step 1: Configure Agent Protocols**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Under **Agent protocols**, disable insecure protocols
3. Enable only **Inbound TCP Agent Protocol/4 (TLS encryption)**

**Step 2: Configure HTTPS**
1. Configure Jenkins to run behind HTTPS reverse proxy
2. Or configure HTTPS directly in Jenkins:
```bash
java -jar jenkins.war --httpsPort=8443 \
  --httpsKeyStore=/path/to/keystore.jks \
  --httpsKeyStorePassword=changeit
```

---

## 4. Pipeline Security

### 4.1 Enable CSRF Protection

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.13 |
| NIST 800-53 | SC-8 |

#### Description
Enable CSRF protection to prevent cross-site request forgery attacks.

#### ClickOps Implementation

**Step 1: Enable CSRF Protection**
1. Navigate to: **Manage Jenkins** → **Security** → **Configure Global Security**
2. Under **CSRF Protection**, select **Default Crumb Issuer**
3. Optionally enable **Enable proxy compatibility** if behind a reverse proxy

---

### 4.2 Secure Credentials Management

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Securely manage credentials using Jenkins Credentials Plugin with appropriate scoping.

#### ClickOps Implementation

**Step 1: Organize Credentials by Scope**
1. Navigate to: **Manage Jenkins** → **Credentials**
2. Create credential domains for different purposes:
   - `production-deployments`
   - `testing-resources`
   - `third-party-integrations`

**Step 2: Use Folder-Scoped Credentials**
1. Create folders for different teams/projects
2. Store credentials at folder level (not global)
3. Only jobs in folder can access credentials

**Step 3: Configure Credential Types**
1. Prefer:
   - SSH Username with private key
   - Secret file
   - Certificates
2. Avoid:
   - Username with password (when possible)

**Step 4: Audit Credential Usage**
1. Install Credentials Binding Plugin
2. Use `withCredentials` in pipelines for explicit binding
3. Audit which jobs use which credentials

---

### 4.3 Implement Pipeline Sandbox

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.1 |
| NIST 800-53 | CM-7 |

#### Description
Use Pipeline Groovy Sandbox to restrict what pipeline scripts can do.

#### Rationale
**Why This Matters:**
- Unrestricted pipelines can execute arbitrary Groovy code
- Can access Jenkins internals, file system, network
- Sandbox restricts to approved methods only

#### ClickOps Implementation

**Step 1: Configure Script Security**
1. Navigate to: **Manage Jenkins** → **In-process Script Approval**
2. Review and approve only necessary script signatures
3. Do not approve requests without review

**Step 2: Use Declarative Pipelines**
1. Prefer declarative pipelines over scripted:
```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'make build'
            }
        }
    }
}
```

**Step 3: Restrict Script Approval**
1. Limit who can approve scripts
2. Review all approval requests carefully
3. Consider security implications of each approval

---

### 4.4 Secure Jenkinsfile Configuration

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 16.9 |
| NIST 800-53 | CM-3 |

#### Description
Implement secure Jenkinsfile practices to prevent pipeline attacks.

#### Code Implementation

**Secure Jenkinsfile Template:**
```groovy
pipeline {
    agent {
        label 'secure-agent'
    }

    options {
        // Limit build time
        timeout(time: 1, unit: 'HOURS')
        // Discard old builds
        buildDiscarder(logRotator(numToKeepStr: '10'))
        // Prevent concurrent builds
        disableConcurrentBuilds()
    }

    environment {
        // Use credentials binding
        AWS_CREDENTIALS = credentials('aws-deploy-creds')
    }

    stages {
        stage('Build') {
            steps {
                // Use approved methods only
                sh 'make build'
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                // Use credentials securely
                withCredentials([usernamePassword(
                    credentialsId: 'deploy-creds',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh './deploy.sh'
                }
            }
        }
    }

    post {
        always {
            // Clean up workspace
            cleanWs()
        }
    }
}
```

---

## 5. Monitoring & Compliance

### 5.1 Enable Audit Logging

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable comprehensive audit logging for security monitoring.

#### Prerequisites
- [ ] Audit Trail Plugin installed

#### ClickOps Implementation

**Step 1: Install Audit Trail Plugin**
1. Navigate to: **Manage Jenkins** → **Plugins** → **Available plugins**
2. Install **Audit Trail** plugin
3. Restart Jenkins

**Step 2: Configure Audit Trail**
1. Navigate to: **Manage Jenkins** → **System** → **Audit Trail**
2. Add logger:
   - **Log file:** `/var/log/jenkins/audit.log`
   - Or **Syslog server** for SIEM integration
3. Configure log pattern and events

**Key Events to Monitor:**
- Login/logout events
- Configuration changes
- Job creation/deletion
- Credential access
- Build triggers

---

### 5.2 Keep Jenkins Updated

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 7.3 |
| NIST 800-53 | SI-2 |

#### Description
Keep Jenkins and all plugins updated with security patches.

#### ClickOps Implementation

**Step 1: Check for Updates**
1. Navigate to: **Manage Jenkins** → **Manage Plugins** → **Updates**
2. Review available updates
3. Prioritize security updates

**Step 2: Configure Update Center**
1. Navigate to: **Manage Jenkins** → **Manage Plugins** → **Advanced**
2. Verify update site URL
3. Consider using LTS release line for stability

**Best Practices:**
- Follow biweekly update cadence
- Stay on latest supported hot-patch release
- Test updates in non-production first
- Subscribe to Jenkins security advisories

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Jenkins Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | Authentication | [1.1](#11-enable-authentication) |
| CC6.1 | SSO | [1.2](#12-configure-ldap-or-saml-sso) |
| CC6.2 | Authorization | [2.1](#21-configure-matrix-based-security) |
| CC6.6 | Agent security | [3.1](#31-enable-agent-to-controller-access-control) |
| CC7.2 | Audit logging | [5.1](#51-enable-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Jenkins Control | Guide Section |
|---------|-----------------|---------------|
| IA-2 | Authentication | [1.1](#11-enable-authentication) |
| AC-6 | Least privilege | [2.1](#21-configure-matrix-based-security) |
| AC-6(1) | RBAC | [2.3](#23-configure-role-based-access-control) |
| CM-7 | Minimize function | [3.2](#32-disable-builds-on-controller) |
| AU-2 | Audit logging | [5.1](#51-enable-audit-logging) |

---

## Appendix A: Essential Security Plugins

| Plugin | Purpose | Priority |
|--------|---------|----------|
| SAML Plugin | SSO authentication | High |
| Role-based Authorization Strategy | Fine-grained RBAC | High |
| Audit Trail | Security logging | High |
| Credentials Binding | Secure credential usage | High |
| Folders | Credential scoping | Medium |
| Configuration as Code | Automated security config | Medium |

---

## Appendix B: References

**Official Jenkins Documentation:**
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Managing Security](https://www.jenkins.io/doc/book/security/managing-security/)
- [Securing Jenkins](https://www.jenkins.io/doc/book/security/securing-jenkins/)
- [Jenkins Security Advisories](https://www.jenkins.io/security/advisories/)
- [Jenkins Security Page](https://www.jenkins.io/security/)

**API & Developer Resources:**
- [Remote Access API](https://www.jenkins.io/doc/book/using/remote-access-api/)
- [Jenkins CLI](https://www.jenkins.io/doc/book/managing/cli/)

**Plugins:**
- [SAML Plugin](https://plugins.jenkins.io/saml/)
- [Role-Based Authorization Strategy](https://plugins.jenkins.io/role-strategy/)
- [Microsoft Entra ID Plugin](https://plugins.jenkins.io/azure-ad/)
- [Audit Trail Plugin](https://plugins.jenkins.io/audit-trail/)

**Compliance Frameworks:**
- Jenkins is an open-source project and does not hold SOC 2, ISO 27001, or similar certifications as a product. Organizations self-hosting Jenkins are responsible for their own compliance posture. CloudBees, the commercial Jenkins vendor, maintains its own compliance certifications for CloudBees CI.

**Security Incidents:**
- **CVE-2024-23897 (CVSS 9.8):** Critical path traversal flaw in Jenkins CLI allowing unauthenticated arbitrary file read; actively exploited in ransomware attacks and added to CISA KEV catalog. Fixed in Jenkins 2.442 and LTS 2.426.3.
- Jenkins regularly publishes security advisories at [jenkins.io/security/advisories](https://www.jenkins.io/security/advisories/) covering core and plugin vulnerabilities.

**Third-Party Resources:**
- [Jenkins Security Best Practices - Wiz](https://www.wiz.io/lp/jenkins-security-best-practices-cheat-sheet)
- [Jenkins Security Best Practices - Cycode](https://cycode.com/blog/jenkins-security-best-practices/)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with authentication, authorization, and pipeline security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
