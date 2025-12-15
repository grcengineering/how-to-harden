# Azure DevOps Hardening Guide

**Version:** 1.0
**Last Updated:** 2025-12-14
**Product Editions Covered:** Azure DevOps Services (Cloud), Azure DevOps Server (On-Premises)
**Authors:** How to Harden Community

---

## Overview

Azure DevOps provides deep Microsoft ecosystem integration with enterprise-wide pipeline and repository access. Service connections store long-lived credentials for Azure Resource Manager, AWS, and GCP. OIDC federation (workload identity federation) should replace static secrets, but legacy configurations with stored credentials remain vulnerable to supply chain attacks.

### Intended Audience
- Security engineers hardening DevOps infrastructure
- Platform engineers managing Azure DevOps
- GRC professionals assessing CI/CD compliance
- DevOps teams implementing secure pipelines

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Azure DevOps security configurations including authentication, service connection hardening, pipeline security, and variable group management.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Service Connection Security](#2-service-connection-security)
3. [Pipeline Security](#3-pipeline-security)
4. [Repository Security](#4-repository-security)
5. [Variable & Secret Management](#5-variable--secret-management)
6. [Monitoring & Detection](#6-monitoring--detection)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Azure AD Authentication with Conditional Access

**Profile Level:** L1 (Baseline)
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1)

#### Description
Require Azure AD authentication with Conditional Access policies including MFA, device compliance, and location-based restrictions.

#### Rationale
**Why This Matters:**
- Azure DevOps controls code, pipelines, and deployment secrets
- Service connections store cloud provider credentials
- Compromised access enables code injection and infrastructure access

**Attack Scenario:** Compromised service connection credentials enable infrastructure modification; variable group exposure leaks secrets to unauthorized pipelines.

#### ClickOps Implementation

**Step 1: Configure Azure AD Connection**
1. Navigate to: **Organization Settings → Azure Active Directory**
2. Connect to Azure AD tenant
3. Enable: **Only allow Azure AD users**

**Step 2: Create Conditional Access Policy (Azure AD)**
1. Navigate to: **Azure Portal → Azure AD → Security → Conditional Access**
2. Create policy for Azure DevOps:
   - **Users:** All users
   - **Cloud apps:** Azure DevOps
   - **Conditions:**
     - Sign-in risk: Block high risk
     - Device platforms: Require managed devices (L2)
   - **Grant:** Require MFA

**Step 3: Disable Alternate Authentication**
1. Navigate to: **Organization Settings → Policies**
2. Disable:
   - **Third-party application access via OAuth:** Disable or restrict
   - **SSH authentication:** Restrict to managed keys
   - **Allow public projects:** Disable

#### Compliance Mappings
| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(1) | MFA for network access |

---

### 1.2 Implement Project-Level Security Groups

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure granular project permissions using Azure DevOps security groups.

#### ClickOps Implementation

**Step 1: Define Security Group Strategy**
```
Security Groups:
├── Project Administrators (2-3 users max)
├── Build Administrators
├── Release Administrators
├── Contributors (developers)
├── Readers (stakeholders)
└── Service Accounts (pipelines)
```

**Step 2: Configure Project Permissions**
1. Navigate to: **Project Settings → Permissions**
2. For each group, configure:
   - **Contributors:** Cannot manage service connections
   - **Build Administrators:** Can manage build pipelines only
   - **Release Administrators:** Can manage release pipelines

**Step 3: Restrict Service Account Permissions**
1. Create dedicated service accounts for pipelines
2. Grant minimum permissions needed
3. Do not add to Project Administrators

---

### 1.3 Configure Personal Access Token Policies

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Restrict PAT creation and enforce expiration policies.

#### ClickOps Implementation

**Step 1: Configure Organization PAT Policy**
1. Navigate to: **Organization Settings → Policies**
2. Configure:
   - **Restrict creation of full-scoped PATs:** Enable
   - **Maximum PAT lifetime:** 90 days
   - **Restrict global PATs:** Enable

**Step 2: Audit Existing PATs**
```powershell
# Azure DevOps REST API - List PATs
$org = "your-org"
$pat = $env:AZURE_DEVOPS_PAT

$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
}

Invoke-RestMethod -Uri "https://vssps.dev.azure.com/$org/_apis/tokens/pats?api-version=7.1-preview.1" `
    -Headers $headers | ConvertTo-Json
```

---

## 2. Service Connection Security

### 2.1 Migrate to Workload Identity Federation

**Profile Level:** L1 (Baseline) - CRITICAL
**NIST 800-53:** IA-5

#### Description
Replace service connections with stored credentials with workload identity federation (OIDC), eliminating static secrets.

#### Rationale
**Why This Matters:**
- Service connections store long-lived credentials
- Static credentials don't expire without rotation
- OIDC federation provides short-lived, automatically rotated tokens

#### ClickOps Implementation

**Step 1: Create Workload Identity Federation Service Connection**
1. Navigate to: **Project Settings → Service connections**
2. Click **New service connection → Azure Resource Manager**
3. Select: **Workload Identity federation (automatic)**
4. Configure:
   - **Subscription:** Target subscription
   - **Service connection name:** Descriptive name
   - **Grant access to all pipelines:** Disable

**Step 2: Migrate Existing Service Connections**
1. Identify connections using stored credentials
2. Create new OIDC-based connections
3. Update pipeline references
4. Delete old credential-based connections

**Step 3: Restrict Service Connection Access**
1. Navigate to: **Service connection → Security**
2. Configure:
   - **Pipeline permissions:** Specific pipelines only
   - **User permissions:** Administrators only
   - **Allow all pipelines:** Disable

#### Code Implementation (Pipeline)

```yaml
# azure-pipelines.yml - Using workload identity federation
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

stages:
  - stage: Deploy
    jobs:
      - deployment: DeployToAzure
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: AzureCLI@2
                  inputs:
                    # Uses workload identity federation - no stored credentials
                    azureSubscription: 'production-oidc-connection'
                    scriptType: 'bash'
                    scriptLocation: 'inlineScript'
                    inlineScript: |
                      az account show
                      az webapp deployment source config-zip \
                        --resource-group myRG \
                        --name myApp \
                        --src $(Pipeline.Workspace)/drop/app.zip
```

---

### 2.2 Audit and Rotate Legacy Service Connections

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5(1)

#### Description
Audit service connections with stored credentials and implement rotation schedule.

#### ClickOps Implementation

**Step 1: Audit Service Connections**
1. Navigate to: **Project Settings → Service connections**
2. Review each connection type:
   - Azure Resource Manager (check for stored creds vs OIDC)
   - AWS (check for access keys)
   - Docker Registry (check for passwords)
   - Generic (check for stored secrets)

**Step 2: Document Rotation Schedule**
| Connection Type | Rotation Frequency | Last Rotated |
|-----------------|-------------------|--------------|
| Azure (stored creds) | 90 days | [Date] |
| AWS Access Keys | 90 days | [Date] |
| Docker Registry | 90 days | [Date] |

**Step 3: Implement Rotation**
```powershell
# Rotate service connection credentials
# 1. Generate new credentials in target service
# 2. Update service connection
# 3. Verify pipeline functionality
# 4. Revoke old credentials

# Azure DevOps API - Update service connection
$connectionId = "connection-guid"
$projectId = "project-guid"

$body = @{
    name = "Updated Connection"
    authorization = @{
        parameters = @{
            serviceprincipalkey = "new-secret-value"
        }
    }
} | ConvertTo-Json

Invoke-RestMethod -Method Put `
    -Uri "https://dev.azure.com/$org/$projectId/_apis/serviceendpoint/endpoints/$connectionId?api-version=7.1" `
    -Headers $headers -Body $body -ContentType "application/json"
```

---

### 2.3 Implement Service Connection Approval Gates

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-3

#### Description
Require approval for pipeline use of sensitive service connections.

#### ClickOps Implementation

**Step 1: Configure Approvals and Checks**
1. Navigate to: **Service connection → Approvals and checks**
2. Add checks:
   - **Required approvers:** Security team member
   - **Business hours:** Production deployments only during business hours
   - **Branch control:** Only from protected branches

---

## 3. Pipeline Security

### 3.1 Implement YAML Pipeline Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### Description
Configure secure YAML pipeline practices and restrict classic pipelines.

#### ClickOps Implementation

**Step 1: Disable Classic Pipelines (L2)**
1. Navigate to: **Organization Settings → Pipelines → Settings**
2. Disable:
   - **Disable creation of classic build pipelines:** Enable
   - **Disable creation of classic release pipelines:** Enable

**Step 2: Require YAML Pipeline Reviews**
1. Navigate to: **Project Settings → Repositories → Policies**
2. Configure branch policies for azure-pipelines.yml:
   - **Require approval:** Enable
   - **Minimum reviewers:** 2

**Step 3: Implement Secure Pipeline Template**
```yaml
# templates/secure-pipeline.yml
parameters:
  - name: environment
    type: string
    values:
      - development
      - staging
      - production

stages:
  - stage: Build
    jobs:
      - job: Build
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: UseDotNet@2
            inputs:
              version: '8.x'

          - script: dotnet build --configuration Release
            displayName: 'Build'

          - task: PublishBuildArtifacts@1
            inputs:
              PathtoPublish: '$(Build.ArtifactStagingDirectory)'

  - stage: SecurityScan
    dependsOn: Build
    jobs:
      - job: Scan
        steps:
          - task: CredScan@3
            displayName: 'Credential Scanner'

          - task: SdtReport@2
            displayName: 'Security Report'

  - stage: Deploy
    dependsOn: SecurityScan
    condition: succeeded()
    jobs:
      - deployment: Deploy
        environment: ${{ parameters.environment }}
        strategy:
          runOnce:
            deploy:
              steps:
                - script: echo "Deploying to ${{ parameters.environment }}"
```

---

### 3.2 Configure Pipeline Permissions and Approvals

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3

#### Description
Restrict pipeline access to resources and require approvals for production.

#### ClickOps Implementation

**Step 1: Configure Environment Approvals**
1. Navigate to: **Pipelines → Environments → production**
2. Add approvals and checks:
   - **Approvers:** Required for deployment
   - **Branch control:** Only main branch
   - **Business hours:** Optional restriction

**Step 2: Configure Pipeline Permissions**
1. Navigate to: **Pipeline → Security**
2. Configure:
   - **Pipeline permissions:** Specific users/groups
   - **Queue builds:** Restricted to authorized users

---

### 3.3 Secure Agent Pool Configuration

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-7

#### Description
Configure agent pools with appropriate security controls.

#### ClickOps Implementation

**Step 1: Create Tiered Agent Pools**
```
Agent Pools:
├── Azure Pipelines (Microsoft-hosted, ephemeral)
├── Development-Agents (self-hosted, lower trust)
├── Production-Agents (self-hosted, restricted)
└── Security-Agents (isolated, scanning tools)
```

**Step 2: Configure Pool Permissions**
1. Navigate to: **Organization Settings → Agent pools**
2. For production pool:
   - **Pipeline permissions:** Production pipelines only
   - **User permissions:** Administrators only

**Step 3: Self-Hosted Agent Security**
```powershell
# Agent installation with security
# Run as service account (not admin)
# Limit network access
# Enable audit logging

.\config.cmd --unattended `
    --url https://dev.azure.com/your-org `
    --auth PAT `
    --token $env:AGENT_PAT `
    --pool "Production-Agents" `
    --agent $env:COMPUTERNAME `
    --runAsService `
    --windowsLogonAccount "DOMAIN\svc-agent"
```

---

## 4. Repository Security

### 4.1 Configure Branch Policies

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-3

#### Description
Implement branch policies to enforce code review and prevent direct pushes.

#### ClickOps Implementation

**Step 1: Configure Protected Branches**
1. Navigate to: **Repos → Branches → main → Branch policies**
2. Enable:
   - **Require a minimum number of reviewers:** 2
   - **Check for linked work items:** Required
   - **Check for comment resolution:** Required
   - **Build validation:** Required pipeline must pass
   - **Automatically include reviewers:** Code owners

**Step 2: Configure Path-Based Policies**
1. Add path filters for sensitive directories:
   - `azure-pipelines.yml`: Require security team review
   - `terraform/`: Require platform team review

---

### 4.2 Enable Credential Scanning

**Profile Level:** L1 (Baseline)
**NIST 800-53:** RA-5

#### Description
Enable Microsoft Security DevOps to detect secrets in repositories.

#### Implementation

```yaml
# azure-pipelines.yml - Credential scanning
trigger:
  - main
  - feature/*

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: MicrosoftSecurityDevOps@1
    displayName: 'Microsoft Security DevOps'
    inputs:
      categories: 'secrets,code'

  - task: PublishSecurityAnalysisLogs@3
    condition: always()
```

---

## 5. Variable & Secret Management

### 5.1 Secure Variable Groups

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### Description
Configure variable groups with appropriate security controls.

#### ClickOps Implementation

**Step 1: Create Environment-Specific Variable Groups**
1. Navigate to: **Pipelines → Library → Variable groups**
2. Create groups:
   - `production-secrets` (linked to Key Vault)
   - `staging-secrets`
   - `shared-config`

**Step 2: Link to Azure Key Vault**
1. Create variable group linked to Key Vault
2. Configure:
   - **Azure subscription:** Service connection
   - **Key vault name:** Production vault
   - **Secrets:** Select required secrets

**Step 3: Configure Variable Group Permissions**
1. Navigate to: **Variable group → Security**
2. Configure:
   - **Pipeline permissions:** Specific pipelines only
   - **User permissions:** Administrators only

---

### 5.2 Use Runtime Parameters for Secrets

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-28

#### Description
Pass secrets at runtime rather than storing in pipelines.

```yaml
# azure-pipelines.yml
parameters:
  - name: deploymentKey
    type: string
    default: ''

variables:
  - group: production-config  # Non-secret config
  - name: secretKey
    value: ${{ parameters.deploymentKey }}

stages:
  - stage: Deploy
    jobs:
      - job: Deploy
        steps:
          - script: |
              # Use secret from parameter
              echo "##vso[task.setvariable variable=SECRET;issecret=true]$(secretKey)"
```

---

## 6. Monitoring & Detection

### 6.1 Enable Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure and monitor Azure DevOps audit logs.

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Organization Settings → Auditing**
2. Review events:
   - Service connection changes
   - Permission changes
   - Pipeline modifications

**Step 2: Export to SIEM**
```powershell
# Export audit logs via API
$org = "your-org"
$continuationToken = ""

do {
    $response = Invoke-RestMethod `
        -Uri "https://auditservice.dev.azure.com/$org/_apis/audit/auditlog?api-version=7.1&continuationToken=$continuationToken" `
        -Headers $headers

    $response.decoratedAuditLogEntries | ForEach-Object {
        # Send to SIEM
        Send-ToSiem $_
    }

    $continuationToken = $response.continuationToken
} while ($continuationToken)
```

#### Detection Queries

```kusto
// Azure Sentinel / Log Analytics queries

// Detect service connection modifications
AzureDevOpsAuditing
| where OperationName contains "ServiceEndpoint"
| where OperationName contains "Modified" or OperationName contains "Created"
| project TimeGenerated, ActorUPN, OperationName, ProjectName, Data

// Detect pipeline permission changes
AzureDevOpsAuditing
| where OperationName contains "Security" or OperationName contains "Permission"
| project TimeGenerated, ActorUPN, OperationName, ProjectName, Data

// Detect unusual build activity
AzureDevOpsAuditing
| where OperationName == "Build.QueueBuild"
| summarize count() by ActorUPN, bin(TimeGenerated, 1h)
| where count_ > 50
```

---

## 7. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Azure DevOps Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | Azure AD + Conditional Access | 1.1 |
| CC6.2 | Project permissions | 1.2 |
| CC8.1 | Branch policies | 4.1 |

### NIST 800-53 Mapping

| Control | Azure DevOps Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | Azure AD MFA | 1.1 |
| IA-5 | Service connection OIDC | 2.1 |
| CM-3 | Branch policies | 4.1 |
| AU-2 | Audit logging | 6.1 |

---

## Appendix A: Edition Compatibility

| Control | Basic | Basic + Test Plans | Azure DevOps Server |
|---------|-------|-------------------|---------------------|
| Azure AD | ✅ | ✅ | ✅ |
| Conditional Access | ✅ | ✅ | AD FS |
| Audit Logs | ✅ | ✅ | ✅ |
| Workload Identity | ✅ | ✅ | ✅ |
| Advanced Security | Add-on | Add-on | Add-on |

---

## Appendix B: References

**Official Microsoft Documentation:**
- [Azure DevOps Security Best Practices](https://docs.microsoft.com/azure/devops/organizations/security/security-best-practices)
- [Workload Identity Federation](https://docs.microsoft.com/azure/devops/pipelines/library/connect-to-azure)
- [Audit Logging](https://docs.microsoft.com/azure/devops/organizations/audit/azure-devops-auditing)

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial Azure DevOps hardening guide | How to Harden Community |
