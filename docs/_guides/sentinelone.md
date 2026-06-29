---
layout: guide
title: "SentinelOne Hardening Guide"
vendor: "SentinelOne"
slug: "sentinelone"
tier: "1"
category: "Security"
description: "Endpoint Detection and Response (EDR) hardening for SentinelOne Singularity platform"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

SentinelOne is a leading AI-powered Endpoint Detection and Response (EDR) platform protecting **millions of endpoints** worldwide. As a critical security control for endpoint protection, SentinelOne configurations directly impact threat detection, prevention, and response capabilities. Misconfigured policies or suboptimal settings can leave endpoints vulnerable despite having EDR deployed.

### Intended Audience
- Security engineers managing SentinelOne deployments
- IT administrators configuring endpoint protection
- SOC analysts tuning detection and response
- GRC professionals assessing endpoint security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers SentinelOne Management Console hardening, policy configuration, detection tuning, and response procedures.

---

## Table of Contents

1. [Management Console Security](#1-management-console-security)
2. [Policy Configuration](#2-policy-configuration)
3. [Detection & Prevention](#3-detection--prevention)
4. [Response & Remediation](#4-response--remediation)
5. [Monitoring & Operations](#5-monitoring--operations)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Management Console Security

### 1.1 Secure Console Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Secure SentinelOne Management Console with SSO, MFA, and role-based access controls.

#### Rationale
**Why This Matters:**
- Console access controls all endpoint protection
- Compromised admin can disable protection or exfiltrate data
- Role-based access limits blast radius of compromise

#### ClickOps Implementation

**Step 1: Configure SSO**
1. Navigate to: **SentinelOne Console** → **Settings** → **Users** → **SSO**
2. Configure SAML SSO:
   - Upload IdP metadata
   - Configure attribute mappings
   - Test SSO authentication

**Step 2: Enable MFA**
1. If using SSO, enforce MFA through identity provider
2. For local accounts: **Settings** → **Users** → Enable MFA requirement
3. Require MFA for all admin accounts

**Step 3: Configure Role-Based Access**
1. Navigate to: **Settings** → **Users** → **Roles**
2. Review default roles:
   - **Admin:** Full access
   - **IR Team:** Incident response capabilities
   - **SOC:** Alert review and basic response
   - **Viewer:** Read-only
3. Create custom roles as needed
4. Assign minimum required permissions

**Time to Complete:** ~45 minutes

---

### 1.2 Configure API Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure SentinelOne API access and token management.

#### Rationale
**Why This Matters:**
- API tokens grant programmatic access to the console, often with the same power as a logged-in administrator
- Long-lived or over-scoped tokens become persistent backdoors if leaked in source code, logs, or CI systems
- Separate, minimally-scoped tokens per integration limit what an attacker can do with any single stolen credential
- Rotation and immediate revocation ensure a compromised token can be cut off quickly without disrupting every integration

**Attack Prevented:** Token theft, credential leakage, privilege escalation, persistent unauthorized API access

#### ClickOps Implementation

**Step 1: Manage API Tokens**
1. Navigate to: **Settings** → **Users** → **API Token**
2. Review existing API tokens
3. Remove unused tokens
4. Set appropriate token expiration

**Step 2: Configure Token Permissions**
1. Create tokens with minimum required scope
2. Use separate tokens for different integrations
3. Document token usage and owners

**Best Practices:**
- Store tokens in secure vault
- Rotate tokens regularly
- Monitor API token usage
- Revoke tokens immediately if compromised

---

## 2. Policy Configuration

### 2.1 Configure Protection Mode

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.1 |
| NIST 800-53 | SI-3 |

#### Description
Configure SentinelOne agents to "Protect" mode for automatic threat mitigation.

#### Rationale
**Why This Matters:**
- Protect mode automatically mitigates threats
- Detect-only mode requires manual intervention
- Automatic response reduces dwell time

#### ClickOps Implementation

**Step 1: Set Global Policy**
1. Navigate to: **Sentinels** → **Policy**
2. Select scope (Global, Site, or Group)
3. Under **Agent Mode**, select **Protect**

**Step 2: Configure Mitigation Actions**
1. In Policy settings, configure:
   - **Threats:** Kill process, Quarantine file, Remediate
   - **Suspicious:** Alert (or Kill for high-security)
   - **Ransomware:** Enable Rollback

**Mitigation Settings:**

| Threat Type | Recommended Action |
|-------------|-------------------|
| Malware | Kill, Quarantine, Remediate |
| Ransomware | Kill, Quarantine, Rollback |
| Fileless | Kill process |
| PUP | Alert or Block (based on policy) |

**Time to Complete:** ~20 minutes

---

### 2.2 Configure Detection Engines

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.1, 10.5 |
| NIST 800-53 | SI-3, SI-4 |

#### Description
Configure SentinelOne's detection engines for optimal threat detection.

#### Rationale
**Why This Matters:**
- Each engine covers a different attack stage, so disabling any one leaves a detection blind spot attackers can exploit
- Static AI catches malware on write while behavioral AI catches fileless and living-off-the-land techniques at runtime
- Anti-tampering stops adversaries from disabling or uninstalling the agent before executing their payload
- Cloud intelligence and deep visibility enrich local detection with reputation and telemetry the endpoint alone cannot see

**Attack Prevented:** Malware execution, fileless attacks, agent tampering, single-layer detection evasion

#### ClickOps Implementation

**Step 1: Enable All Detection Engines**
1. Navigate to: **Sentinels** → **Policy**
2. Verify all engines are enabled:
   - **Static AI:** On-write file analysis
   - **Behavioral AI:** Runtime behavior analysis
   - **Anti-tampering:** Agent self-protection
   - **Rollback:** Ransomware recovery

**Step 2: Configure Engine Sensitivity**
1. Set AI detection sensitivity:
   - **Low:** Fewer false positives, may miss threats
   - **Normal:** Balanced (recommended)
   - **Aggressive:** Maximum detection, more false positives
2. Tune based on environment needs

**Step 3: Configure Cloud Intelligence**
1. Enable **Cloud Intelligence** for reputation lookups
2. Enable **Deep Visibility** for advanced telemetry
3. Configure network connectivity for cloud services

---

### 2.3 Configure Ransomware Protection

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.1 |
| NIST 800-53 | SI-3 |

#### Description
Configure SentinelOne's ransomware protection and rollback capabilities.

#### Rationale
**Why This Matters:**
- Ransomware encrypts data faster than human responders can react, so automated kill-and-quarantine is essential
- VSS-based rollback restores encrypted files without paying a ransom or relying solely on offline backups
- A dedicated anti-ransomware engine detects mass-encryption behavior even when the malware family is novel
- Testing rollback in advance confirms recovery actually works before a real incident, not during one

**Attack Prevented:** Ransomware encryption, data destruction, extortion, unrecoverable data loss

#### ClickOps Implementation

**Step 1: Enable Ransomware Protection**
1. Navigate to: **Sentinels** → **Policy** → **Engines**
2. Verify **Anti-Ransomware** engine is enabled
3. Set action to **Kill and Quarantine**

**Step 2: Enable Ransomware Rollback**
1. Enable **Rollback** in policy settings
2. Configure VSS snapshots for Windows
3. Verify disk space for snapshots

**Step 3: Test Rollback Capability**
1. In test environment, simulate ransomware
2. Verify automatic detection and rollback
3. Document recovery time

---

### 2.4 Configure Network Control

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.4 |
| NIST 800-53 | SC-7 |

#### Description
Configure network control features for threat containment and investigation.

#### Rationale
**Why This Matters:**
- Network isolation severs an infected endpoint from the rest of the environment, stopping lateral movement and C2 traffic
- Containing a compromised host preserves it for forensic investigation instead of forcing an immediate wipe
- Auto-isolation on critical threats contains breaches at machine speed when responders are offline or asleep
- Firewall control adds host-level segmentation that limits which services an attacker can reach from a foothold

**Attack Prevented:** Lateral movement, command-and-control communication, data exfiltration, ransomware spread

#### ClickOps Implementation

**Step 1: Configure Network Isolation**
1. Navigate to: **Sentinels** → **Policy**
2. Enable **Network Quarantine** capability
3. Configure auto-isolation for critical threats (optional)

**Step 2: Configure Firewall Control**
1. Enable firewall control if licensed
2. Configure baseline firewall rules
3. Use for additional network segmentation

---

## 3. Detection & Prevention

### 3.1 Configure Exclusions Carefully

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.1 |
| NIST 800-53 | SI-3 |

#### Description
Manage exclusions to prevent false positives while maintaining security coverage.

#### Rationale
**Why This Matters:**
- Excessive exclusions create security gaps
- Attackers target exclusion paths
- Each exclusion should be documented and justified

#### ClickOps Implementation

**Step 1: Review Existing Exclusions**
1. Navigate to: **Sentinels** → **Exclusions**
2. Audit all exclusions by type:
   - Path exclusions
   - Hash exclusions
   - Certificate exclusions
   - Browser extension exclusions
3. Document business justification for each

**Step 2: Minimize Exclusions**
1. Remove unnecessary exclusions
2. Use most specific exclusion type possible:
   - Prefer hash over path
   - Prefer specific path over wildcard
3. Set exclusion scope narrowly (site/group vs global)

**Step 3: Monitor Exclusion Usage**
1. Review threats that would have been blocked
2. Periodically re-evaluate exclusion necessity
3. Alert on new exclusion creation

**Exclusion Best Practices:**

| Approach | Security Impact |
|----------|-----------------|
| File hash exclusion | Safest - specific to file |
| Certificate exclusion | Safe - signed software only |
| Specific path exclusion | Moderate - limited scope |
| Wildcard path exclusion | Risk - avoid if possible |
| Process exclusion | High risk - carefully evaluate |

---

### 3.2 Configure Custom Detection Rules

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.5 |
| NIST 800-53 | SI-4 |

#### Description
Create custom detection rules for organization-specific threats and behaviors.

#### Rationale
**Why This Matters:**
- Out-of-the-box detections cannot anticipate threats specific to your applications, naming conventions, or environment
- Custom Deep Visibility rules detect attacker behaviors and policy violations the default engines do not flag
- Tuning severity and automated actions per rule lets high-confidence detections respond without analyst delay
- Codifying threat-hunting findings into rules turns one-time discoveries into permanent, repeatable detection

**Attack Prevented:** Targeted attacks, insider threats, environment-specific TTPs, detection coverage gaps

#### ClickOps Implementation

**Step 1: Access Custom Rules**
1. Navigate to: **Custom Rules** or **Watchlist** (depending on version)
2. Review existing custom detections

**Step 2: Create Detection Rule**
1. Click **New Rule**
2. Configure:
   - **Name:** Descriptive rule name
   - **Query:** Deep Visibility query
   - **Severity:** Critical, High, Medium, Low
   - **Action:** Alert, Kill, Quarantine

**Example Rules:**

---

### 3.3 Enable Local Upgrade Authorization

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-7 |

#### Description
Enable Local Upgrade Authorization to control agent upgrades and prevent unauthorized modifications.

#### Rationale
**Why This Matters:**
- Prevents unauthorized agent downgrades
- Increases accountability for changes
- Protects against tampering via version manipulation

#### ClickOps Implementation

**Step 1: Enable Upgrade Authorization**
1. Navigate to: **Sites** → Select Site → **Settings**
2. Enable **Local Upgrade Authorization**
3. Configure approval workflow

**Step 2: Test Upgrade Process**
1. Attempt local upgrade
2. Verify approval request is generated
3. Approve and verify completion

---

## 4. Response & Remediation

### 4.1 Configure Automated Response

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.1 |
| NIST 800-53 | IR-4 |

#### Description
Configure automated threat response to minimize dwell time and analyst workload.

#### Rationale
**Why This Matters:**
- Automated mitigation kills and quarantines threats in seconds, minimizing dwell time before damage spreads
- Manual-only response leaves a window where malware can persist, spread, or exfiltrate while waiting on an analyst
- Auto-remediation reverses file, registry, and system changes so endpoints return to a known-good state automatically
- Machine-speed response covers off-hours and high-alert-volume periods when human triage cannot keep up

**Attack Prevented:** Malware persistence, lateral spread, data exfiltration, prolonged dwell time

#### ClickOps Implementation

**Step 1: Configure Auto-Mitigation**
1. Navigate to: **Sentinels** → **Policy**
2. Enable automatic mitigation for:
   - **Malicious threats:** Auto-kill and quarantine
   - **Ransomware:** Auto-kill, quarantine, rollback
3. Configure notification settings

**Step 2: Configure Auto-Remediation**
1. Enable automatic remediation
2. Configure remediation actions:
   - Delete malicious files
   - Restore modified files
   - Clean registry modifications

---

### 4.2 Configure Threat Intelligence

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.5 |
| NIST 800-53 | SI-5 |

#### Description
Integrate threat intelligence feeds for enhanced detection.

#### Rationale
**Why This Matters:**
- Threat intelligence feeds let the platform recognize known-bad indicators before they execute or connect
- STIX/TAXII and custom IOC lists extend detection to threats specific to your industry and known adversaries
- Reputation lookups via cloud intelligence flag malicious files and domains already seen elsewhere in the wild
- Alerting on IOC matches surfaces early-stage intrusions tied to active campaigns targeting your sector

**Attack Prevented:** Known-malware execution, malicious C2 connections, campaign-based attacks, IOC-matched intrusions

#### ClickOps Implementation

**Step 1: Enable Built-in Intelligence**
1. Verify Cloud Intelligence is enabled
2. Configure reputation lookups

**Step 2: Add Custom Intelligence**
1. Navigate to: **Threat Intelligence**
2. Upload IOC feeds:
   - STIX/TAXII feeds
   - Custom IOC lists
   - Industry-specific intelligence
3. Configure alert actions for IOC matches

---

## 5. Monitoring & Operations

### 5.1 Configure Alerting and Notifications

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | SI-4 |

#### Description
Configure alerting and notifications for threat visibility and response.

#### Rationale
**Why This Matters:**
- Timely alerts ensure critical threats reach responders immediately instead of sitting unseen in the console
- SIEM and syslog export centralize EDR telemetry with other logs for correlation and long-term retention
- Notifications on agent-offline and policy changes catch coverage gaps and unauthorized configuration drift
- Routing critical alerts to monitored channels shortens the time between detection and human response

**Attack Prevented:** Undetected breaches, delayed incident response, silent protection gaps, missed policy tampering

#### ClickOps Implementation

**Step 1: Configure Email Notifications**
1. Navigate to: **Settings** → **Notifications**
2. Configure notification rules:
   - Critical threats → Immediate email
   - Agent offline → Daily digest
   - Policy changes → Admin notification

**Step 2: Configure SIEM Integration**
1. Navigate to: **Settings** → **Integrations**
2. Configure syslog/CEF export to SIEM
3. Or use API integration for Splunk, Sentinel, etc.

**Step 3: Configure Slack/Teams Integration**
1. If available, configure chat notifications
2. Route critical alerts to security channel

---

### 5.2 Health Monitoring

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 10.1 |
| NIST 800-53 | SI-4 |

#### Description
Monitor agent health to ensure consistent protection coverage.

#### Rationale
**Why This Matters:**
- An endpoint without a healthy, reporting agent is effectively unprotected and invisible to the SOC
- Tracking coverage and online status surfaces gaps before attackers find and exploit the unmonitored host
- Outdated agent versions lack the latest detections and may carry their own known vulnerabilities
- Policy-compliance monitoring confirms every endpoint actually enforces the protections you configured

**Attack Prevented:** Unmonitored endpoints, coverage gaps, exploitation of outdated agents, policy drift

#### Key Metrics to Monitor

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Agent coverage | 100% | < 95% |
| Agents online | 100% | < 90% |
| Agent version | Latest | > 2 versions behind |
| Policy compliance | 100% | < 98% |
| Detection rate | Baseline | Significant deviation |

#### ClickOps Implementation

**Step 1: Review Dashboard**
1. Navigate to: **Dashboard**
2. Review:
   - Total agents deployed
   - Agents online/offline
   - Threat trends
   - Unresolved threats

**Step 2: Configure Health Alerts**
1. Alert on agents going offline
2. Alert on outdated agent versions
3. Alert on policy non-compliance

---

### 5.3 Maintain Agent Updates

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | SI-2 |

#### Description
Keep SentinelOne agents updated to ensure latest protection capabilities.

#### Rationale
**Why This Matters:**
- Updates deliver new detection logic, engine improvements, and fixes for vulnerabilities in the agent itself
- Outdated agents miss protections against the latest malware families and evasion techniques
- Auto-update with maintenance windows keeps the fleet current without manual per-host effort
- Tracking and investigating failed updates prevents a slow drift toward a stale, under-protected endpoint population

**Attack Prevented:** Exploitation of agent vulnerabilities, evasion by newer malware, protection gaps from stale agents

#### ClickOps Implementation

**Step 1: Configure Auto-Update**
1. Navigate to: **Sentinels** → **Policy**
2. Enable auto-upgrade for agents
3. Configure maintenance windows if needed

**Step 2: Monitor Update Status**
1. Review agent version distribution
2. Identify outdated agents
3. Investigate agents failing to update

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | SentinelOne Control | Guide Section |
|-----------|---------------------|---------------|
| CC6.1 | Console access control | [1.1](#11-secure-console-access) |
| CC7.1 | Threat protection | [2.1](#21-configure-protection-mode) |
| CC7.2 | Detection & alerting | [5.1](#51-configure-alerting-and-notifications) |
| CC7.3 | Incident response | [4.1](#41-configure-automated-response) |

### NIST 800-53 Rev 5 Mapping

| Control | SentinelOne Control | Guide Section |
|---------|---------------------|---------------|
| AC-6(1) | Admin roles | [1.1](#11-secure-console-access) |
| SI-3 | Malware protection | [2.1](#21-configure-protection-mode) |
| SI-4 | Detection rules | [3.2](#32-configure-custom-detection-rules) |
| IR-4 | Automated response | [4.1](#41-configure-automated-response) |

---

## Appendix A: Feature Compatibility

| Feature | Control | Complete | Commercial |
|---------|---------|----------|------------|
| EPP/EDR | ✅ | ✅ | ✅ |
| Ransomware Rollback | ✅ | ✅ | ✅ |
| Firewall Control | ❌ | ✅ | ✅ |
| Device Control | ❌ | ✅ | ✅ |
| Ranger (Network Discovery) | ❌ | ❌ | ✅ |
| Storyline Active Response | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official SentinelOne Documentation:**
- [SentinelOne Community / Knowledge Base](https://community.sentinelone.com/s/)
- [Endpoint Security Best Practices](https://www.sentinelone.com/cybersecurity-101/endpoint-security/endpoint-security-best-practices/)
- [Policy Configuration Guide](https://support.sentinelone.com) (requires login)

**Trust & Compliance:**
- [SentinelOne Trust Center](https://trust.sentinelone.com/)
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018 -- via [SentinelOne Trust Center](https://trust.sentinelone.com/)

**Security Incidents:**
- **China-Linked Attack Attempt (2024-2025):** Chinese state-sponsored threat actors (APT41/PurpleHaze) attempted a supply chain attack against SentinelOne by targeting an IT services vendor working with the company. SentinelOne confirmed no compromise was detected on its software or hardware. The campaign was part of a broader operation targeting 70+ organizations globally between June 2024 and March 2025.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with policy configuration and detection tuning | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
