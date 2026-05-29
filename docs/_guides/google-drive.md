---
layout: guide
title: "Google Drive Hardening Guide"
vendor: "Google Drive"
slug: "google-drive"
platform: "Google Workspace"
platform_slug: "google-workspace"
product: "Google Drive"
tier: "1"
category: "Productivity"
description: "Security hardening for Google Drive — external sharing restrictions and Drive-specific data-loss-prevention guidance."
version: "0.1.0"
maturity: "draft"
last_updated: "2026-05-29"
---

## Overview

Google Drive is the primary file-collaboration and storage surface of Google Workspace, and oversharing is one of the biggest security risks in the platform. This guide covers Drive-specific data-protection controls: external sharing posture and the Drive-side application of the Workspace Data Loss Prevention engine.

This is a **product guide within the [Google Workspace platform](/guides/google-workspace/)**. Platform-wide controls (authentication, OAuth app allowlisting, the DLP engine itself, admin audit logging) live in the Google Workspace **Common Controls** hub and are referenced here rather than duplicated.

### Intended Audience
- Security engineers managing Google Workspace / Google Drive
- IT administrators configuring Admin Console Drive & Docs settings
- GRC professionals assessing data-sharing and DLP compliance
- Third-party risk managers evaluating Drive-based collaboration

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Google Drive external sharing restrictions and Drive-specific DLP guidance in the Google Workspace Admin Console. The platform-wide DLP **engine**, authentication, OAuth allowlisting, and audit logging are covered in the [Google Workspace guide](/guides/google-workspace/). Gmail and Google Chat are covered in their own product guides.

---

## Table of Contents

1. [Data Security](#1-data-security)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

---

## 1. Data Security

### 1.1 Configure External Drive Sharing Restrictions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3, AC-22 |
| CIS Google Workspace | 3.1 |

#### Description
Restrict external sharing of Google Drive files to prevent unauthorized data exposure. Configure default sharing settings to "Restricted" and control "Anyone with the link" sharing.

#### Rationale
**Why This Matters:**
- Oversharing is one of the biggest security risks in Google Workspace
- "Anyone with the link" files can be accessed by anyone who discovers the URL
- Data exposure from misconfigured sharing is common

**Attack Prevented:** Data exfiltration, accidental data exposure, insider threats

#### Prerequisites
- Inventory of current sharing policies
- Business requirements for external collaboration

#### ClickOps Implementation

**Step 1: Configure Organization-Wide Sharing**
1. Navigate to: **Admin Console** → **Apps** → **Google Workspace** → **Drive and Docs**
2. Click **Sharing settings**
3. Configure **Sharing options**:
   - **Sharing outside of [organization]:** Off or Allowlisted domains only
   - **Default link sharing:** Restricted (only people added)
4. Click **Save**

**Step 2: Configure Sharing for Specific OUs**
1. Select organizational unit from left panel
2. Override settings for teams requiring external collaboration
3. Use most restrictive settings possible

**Step 3: Disable "Anyone with the link"**
1. In Sharing settings, find **Link sharing default**
2. Set to **Restricted** (not "Anyone with the link")
3. Optionally block "Anyone with the link" entirely

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="google-drive" section="1.1" %}

#### Validation & Testing
1. Create test file and verify default sharing is Restricted
2. Attempt to share externally - verify appropriate restrictions apply
3. Audit existing files with external sharing
4. Confirm allowed external sharing still functions

**Expected result:** Default Drive sharing is Restricted; external sharing limited to allowlisted domains (or off).

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | AC-3 | Access enforcement |
| **NIST 800-53** | AC-22 | Publicly accessible content |
| **CIS Google Workspace** | 3.1 | Drive external sharing restrictions |

---

### DLP for Drive

Data Loss Prevention for Drive (content-aware rules that scan Drive files for sensitive data and block or warn on sharing) is configured through the platform-wide DLP engine. See **[Google Workspace → Enable Data Loss Prevention (DLP)](/guides/google-workspace/#42-enable-data-loss-prevention-dlp)** for the engine setup, then scope a Drive-targeted rule:

- In the DLP rule, set the **scope** to **Google Drive** and target the relevant organizational units.
- Pair the rule with the external-sharing restrictions above so a detector blocks sensitive content even when a user attempts an allowed external share.

---

## 2. Compliance Quick Reference

| Control | SOC 2 | NIST 800-53 | CIS Google Workspace |
|---------|-------|-------------|----------------------|
| [1.1](#11-configure-external-drive-sharing-restrictions) External sharing | CC6.1 | AC-3, AC-22 | 3.1 |
| DLP for Drive (via hub) | CC6.7 | SC-7, SI-4 | 3.2 |

> Platform-wide compliance mappings (authentication, OAuth, the DLP engine, admin audit logging) are in the [Google Workspace guide](/guides/google-workspace/#7-compliance-quick-reference).

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-05-29 | Initial Google Drive product guide — split from the Google Workspace guide (control 1.1 external sharing restrictions; DLP-for-Drive cross-references the platform DLP engine). Part of the multi-product platform restructure. |

## Contributing

Found an issue or have an improvement? See the [Google Workspace platform guide](/guides/google-workspace/) for platform-wide controls, or open an issue/PR on [GitHub](https://github.com/grcengineering/how-to-harden).
