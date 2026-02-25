---
layout: guide
title: "MongoDB Atlas Hardening Guide"
vendor: "MongoDB"
slug: "mongodb-atlas"
tier: "1"
category: "Data"
description: "Database-as-a-Service security hardening for MongoDB Atlas network access, authentication, and encryption"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

MongoDB Atlas is the leading cloud database platform, serving **millions of developers** with fully managed MongoDB deployments across AWS, Azure, and Google Cloud. As a critical data store for applications, Atlas security configurations directly impact data protection. By default, all access is blocked and must be explicitly enabled, but misconfigurations can expose databases to unauthorized access.

### Intended Audience
- Security engineers managing database infrastructure
- Database administrators configuring Atlas clusters
- GRC professionals assessing data security
- DevOps engineers implementing secure deployments

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers MongoDB Atlas security configurations including network access, authentication, encryption, and monitoring. Self-managed MongoDB deployments are covered in a separate guide.

---

## Table of Contents

1. [Network Security](#1-network-security)
2. [Authentication & Access](#2-authentication--access)
3. [Encryption](#3-encryption)
4. [Monitoring & Auditing](#4-monitoring--auditing)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Network Security

### 1.1 Configure IP Access List

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | SC-7 |

#### Description
Configure IP access lists to restrict which IP addresses can connect to your Atlas clusters. By default, all access is blocked.

#### Rationale
**Why This Matters:**
- Default-deny ensures no unauthorized network access
- IP allowlisting limits exposure to known addresses
- Prevents database exposure to the internet

#### ClickOps Implementation

**Step 1: Access Network Configuration**
1. Navigate to: **MongoDB Atlas** → **Project** → **Network Access**
2. Review current IP access list

**Step 2: Configure IP Access**
1. Click **Add IP Address**
2. Configure allowed IPs:
   - **Development:** Individual developer IPs (temporary)
   - **Production:** Application server IPs/CIDR ranges only
   - **NEVER:** 0.0.0.0/0 (allows any IP)
3. Add description for each entry
4. Set expiration for temporary access

**Best Practices:**

| Environment | Recommended Configuration |
|-------------|--------------------------|
| Development | Individual IPs with expiration |
| Staging | Application server IPs only |
| Production | Smallest CIDR possible, VPC peering preferred |

**Time to Complete:** ~15 minutes

---


{% include pack-code.html vendor="mongodb-atlas" section="1.1" %}

### 1.2 Configure VPC Peering or Private Endpoints

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 12.1 |
| NIST 800-53 | SC-7 |

#### Description
Configure private connectivity via VPC peering or private endpoints to eliminate public internet exposure.

#### Rationale
**Why This Matters:**
- Private endpoints eliminate public internet exposure
- Traffic stays within cloud provider network
- More secure than IP allowlisting alone

#### Prerequisites
- MongoDB Atlas M10 tier or higher
- AWS VPC, Azure VNet, or GCP VPC configured

#### ClickOps Implementation

**Step 1: Configure VPC Peering**
1. Navigate to: **Network Access** → **Peering**
2. Click **Add Peering Connection**
3. Select cloud provider and region
4. Enter VPC/VNet details:
   - VPC ID
   - CIDR block
   - Account/Project ID
5. Accept peering from your cloud provider console

**Step 2: Configure Private Endpoints (Recommended)**
1. Navigate to: **Network Access** → **Private Endpoint**
2. Click **Add Private Endpoint**
3. Select cloud provider and region
4. Follow provider-specific instructions:
   - **AWS:** Create VPC endpoint
   - **Azure:** Create private endpoint
   - **GCP:** Create private service connect

**Step 3: Update IP Access List**
1. Private endpoints are automatically added
2. Remove public IP entries if no longer needed
3. Verify connectivity through private endpoint

**Time to Complete:** ~1 hour

---

## 2. Authentication & Access

### 2.1 Configure Database Users with Least Privilege

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Create database users with role-based access control (RBAC) following the principle of least privilege.

#### Rationale
**Why This Matters:**
- Limits blast radius of compromised credentials
- Supports compliance requirements
- Enables audit of access patterns

#### ClickOps Implementation

**Step 1: Access Database Users**
1. Navigate to: **Database Access** → **Database Users**
2. Review existing users

**Step 2: Create Least Privilege Users**
1. Click **Add New Database User**
2. Configure authentication:
   - **SCRAM:** Password-based (most common)
   - **X.509 Certificate:** Certificate-based (recommended)
   - **AWS IAM:** For AWS workloads
   - **LDAP:** Deprecated in Atlas 8.0+
3. Configure privileges:
   - **Built-in Role:** Select appropriate role
   - **Custom Role:** Create granular permissions
4. Restrict to specific database if possible

**Recommended Roles:**

| Use Case | Recommended Role |
|----------|-----------------|
| Application read | readAnyDatabase or read on specific DB |
| Application write | readWriteAnyDatabase or readWrite on specific DB |
| Admin operations | dbAdmin on specific DB |
| Full admin | atlasAdmin (limit to 1-2 users) |

**Step 3: Create Separate Service Accounts**
1. Create dedicated users for each application
2. Avoid shared credentials
3. Document user purpose

**Time to Complete:** ~30 minutes

---


{% include pack-code.html vendor="mongodb-atlas" section="2.1" %}

### 2.2 Enable Multi-Factor Authentication for Atlas Console

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all users accessing the MongoDB Atlas console.

#### ClickOps Implementation

**Step 1: Configure Organization MFA**
1. Navigate to: **Organization** → **Settings** → **Require Multi-Factor Authentication**
2. Enable MFA requirement for all organization members

**Step 2: Configure Personal MFA**
1. Each user: **Account** → **Security** → **Multi-Factor Authentication**
2. Configure MFA method:
   - Authenticator app (recommended)
   - SMS (not recommended)

---

### 2.3 Configure X.509 Certificate Authentication

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2 |

#### Description
Configure X.509 certificate authentication for stronger machine-to-machine authentication.

#### ClickOps Implementation

**Step 1: Enable X.509 Authentication**
1. Navigate to: **Database Access** → **Database Users**
2. Click **Add New Database User**
3. Select **Certificate** authentication
4. Choose:
   - **Atlas-managed:** Atlas manages certificates
   - **Self-managed:** You provide CA and certificates

**Step 2: Configure Atlas-Managed X.509**
1. Download client certificate for your application
2. Configure application connection string with certificate
3. Rotate certificates before expiration

---

### 2.4 Configure Organization and Project Roles

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Configure granular roles for Atlas console access at organization and project levels.

#### ClickOps Implementation

**Step 1: Review Organization Roles**
1. Navigate to: **Organization** → **Access Manager**
2. Review user assignments
3. Available roles:
   - **Organization Owner:** Full access (limit to 2-3)
   - **Organization Member:** Basic access
   - **Organization Read Only:** View only
   - **Billing Admin:** Billing only

**Step 2: Review Project Roles**
1. Navigate to: **Project** → **Access Manager**
2. Assign project-specific roles:
   - **Project Owner:** Full project access
   - **Project Data Access Admin:** Database user management
   - **Project Cluster Manager:** Cluster management
   - **Project Read Only:** View only

---

## 3. Encryption

### 3.1 Verify Default Encryption

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-8, SC-28 |

#### Description
Verify that default encryption at rest and in transit is enabled (cannot be disabled in Atlas).

#### Atlas Default Security

| Feature | Default Setting | Can Disable? |
|---------|-----------------|--------------|
| Encryption at Rest (AES-256) | ✅ Enabled | ❌ No |
| Encryption in Transit (TLS 1.2+) | ✅ Enabled | ❌ No |
| TLS 1.3 Support | ✅ Available | N/A |

#### Validation
1. Navigate to: **Clusters** → Select cluster → **Security**
2. Verify encryption indicators show enabled
3. Test connection requires TLS

---

### 3.2 Configure Customer Key Management (CMK)

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Configure customer-managed encryption keys for additional control over data encryption.

#### Rationale
**Why This Matters:**
- Provides customer control over encryption keys
- Supports compliance requirements (PCI, HIPAA)
- Enables key rotation policies

#### Prerequisites
- MongoDB Atlas M10 tier or higher
- Cloud provider KMS (AWS KMS, Azure Key Vault, GCP Cloud KMS)

#### ClickOps Implementation

**Step 1: Configure Cloud Provider KMS**
1. Create KMS key in your cloud provider
2. Configure key policy for Atlas access
3. Note key ARN/ID

**Step 2: Enable CMK in Atlas**
1. Navigate to: **Project** → **Security** → **Encryption at Rest**
2. Click **Configure Encryption at Rest**
3. Select cloud provider
4. Enter KMS key details
5. Configure role/credentials for Atlas access
6. Enable encryption

**Step 3: Verify CMK Configuration**
1. Check cluster shows CMK-encrypted
2. Test key rotation capability

**Time to Complete:** ~1 hour

---


{% include pack-code.html vendor="mongodb-atlas" section="3.2" %}

### 3.3 Configure Client-Side Field Level Encryption

**Profile Level:** L3 (Maximum Security)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-28 |

#### Description
Configure Client-Side Field Level Encryption (CSFLE) to encrypt sensitive fields before they leave the application.

#### Rationale
**Why This Matters:**
- Encrypts PII and sensitive data at field level
- Data remains encrypted even in database
- Only authorized clients can decrypt

#### Implementation
1. Configure encryption schema defining fields to encrypt
2. Generate data encryption keys
3. Configure application driver with encryption settings
4. Test encryption/decryption of sensitive fields

---

## 4. Monitoring & Auditing

### 4.1 Enable Database Auditing

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable database auditing to log authentication attempts and data access.

#### ClickOps Implementation

**Step 1: Enable Auditing**
1. Navigate to: **Project** → **Database Deployments**
2. Select cluster → **Auditing**
3. Enable auditing
4. Configure audit filter for events of interest

**Step 2: Configure Audit Log Export**
1. Navigate to: **Project** → **Integrations**
2. Configure log export to:
   - Atlas Data Federation
   - AWS S3
   - Azure Blob Storage
   - Third-party SIEM

---


{% include pack-code.html vendor="mongodb-atlas" section="4.1" %}

### 4.2 Monitor Atlas Activity Feed

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | AU-6 |

#### Description
Monitor Atlas Activity Feed for administrative and security events.

#### ClickOps Implementation

**Step 1: Access Activity Feed**
1. Navigate to: **Project** → **Activity Feed**
2. Review recent events:
   - User authentication
   - Configuration changes
   - Alerts

**Step 2: Configure Alerts**
1. Navigate to: **Project** → **Alerts**
2. Create alerts for:
   - Failed authentication attempts
   - Configuration changes
   - Resource threshold violations

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Atlas Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | MFA for console | [2.2](#22-enable-multi-factor-authentication-for-atlas-console) |
| CC6.1 | Database users | [2.1](#21-configure-database-users-with-least-privilege) |
| CC6.6 | Network access | [1.1](#11-configure-ip-access-list) |
| CC6.7 | Encryption | [3.1](#31-verify-default-encryption) |
| CC7.2 | Auditing | [4.1](#41-enable-database-auditing) |

### NIST 800-53 Rev 5 Mapping

| Control | Atlas Control | Guide Section |
|---------|---------------|---------------|
| SC-7 | Network security | [1.1](#11-configure-ip-access-list), [1.2](#12-configure-vpc-peering-or-private-endpoints) |
| AC-6 | Least privilege | [2.1](#21-configure-database-users-with-least-privilege) |
| IA-2(1) | MFA | [2.2](#22-enable-multi-factor-authentication-for-atlas-console) |
| SC-28 | Encryption at rest | [3.1](#31-verify-default-encryption) |
| AU-2 | Auditing | [4.1](#41-enable-database-auditing) |

---

## Appendix A: Tier Compatibility

| Feature | M0 (Free) | M2/M5 | M10+ | Dedicated |
|---------|-----------|-------|------|-----------|
| IP Access List | ✅ | ✅ | ✅ | ✅ |
| VPC Peering | ❌ | ❌ | ✅ | ✅ |
| Private Endpoints | ❌ | ❌ | ✅ | ✅ |
| CMK Encryption | ❌ | ❌ | ✅ | ✅ |
| Database Auditing | ❌ | ❌ | ✅ | ✅ |
| LDAP/X.509 | ❌ | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official MongoDB Documentation:**
- [MongoDB Atlas Trust Center](https://www.mongodb.com/products/platform/trust)
- [MongoDB Atlas Product Documentation](https://www.mongodb.com/docs/atlas/)
- [Atlas Security Features](https://www.mongodb.com/docs/atlas/setup-cluster-security/)
- [Network Security Guidance](https://www.mongodb.com/docs/atlas/architecture/current/network-security/)
- [Security Checklist](https://www.mongodb.com/docs/manual/administration/security-checklist/)

**API Documentation:**
- [MongoDB Atlas Administration API](https://www.mongodb.com/docs/atlas/api/)
- [MongoDB Drivers and SDKs](https://www.mongodb.com/docs/drivers/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO/IEC 27001:2022, ISO 27017, ISO 27018, ISO 9001, PCI DSS v4.0, CSA STAR Level 2 — via [MongoDB Atlas Trust Center](https://www.mongodb.com/products/platform/trust)
- [Request Compliance Reports](https://www.mongodb.com/products/platform/trust/request-compliance-documentation)
- [MongoDB Atlas Compliance Features](https://www.mongodb.com/docs/atlas/architecture/current/compliance/)

**Hardening Benchmarks:**
- [CIS MongoDB Benchmark](https://www.cisecurity.org/benchmark/mongodb)

**Security Incidents:**
- **Corporate Systems Breach (December 2023):** MongoDB detected unauthorized access to corporate systems on December 13, 2023 via a phishing attack. Customer names, phone numbers, email addresses, and account metadata were exposed. One customer's system logs were accessed. MongoDB Atlas cluster data was NOT affected — the attackers never accessed Atlas clusters or the Atlas authentication system. — [MongoDB Security Incident Update](https://www.mongodb.com/company/blog/news/mongodb-security-incident-update-december-20-2023)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with network, authentication, and encryption controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
