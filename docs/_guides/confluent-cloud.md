---
layout: guide
title: "Confluent Cloud Hardening Guide"
vendor: "Confluent Cloud"
slug: "confluent-cloud"
tier: "3"
category: "Data"
description: "Harden workload identities, network filtering, and audit evidence in managed Kafka."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden workload identities, network filtering, and audit evidence in managed Kafka.

[IBM completed its acquisition of Confluent in March 2026](https://newsroom.ibm.com/2026-03-17-ibm-completes-acquisition-of-confluent%2C-making-real-time-data-the-engine-of-enterprise-ai-and-agents?lnk=hpln1au). This guide is specific to the Confluent Cloud control plane.

**Validation status:** Documented control paths and offline Code Pack behavior; no live tenant, credentials, or production changes. License and effective permissions may limit visibility.

### Intended Audience

Platform owners, identity administrators, and security reviewers.

### How to Use This Guide

- **L1 (Crawl):** Establish accountable identities and least privilege.
- **L2 (Walk):** Add narrower access boundaries and independent monitoring.

### Scope

Confluent Cloud organization, environment, and Kafka data-plane settings. Self-managed Confluent Platform is out of scope.

## Table of Contents

1. [Access and Administration](#1-access-and-administration)
2. [Network, Integrations and Audit](#2-network-integrations-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Access and Administration

### 1.1 Separate workload identities

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Assign each workload a dedicated service account; grant only the required resource roles.

#### Rationale

**Why This Matters:**

- Shared accounts obscure attribution and make rotation or retirement affect unrelated services.

#### ClickOps Implementation

1. Confirm the available plan and effective administrative permissions in the [vendor documentation](https://docs.confluent.io/cloud/current/security/authenticate/workload-identities/service-accounts/create-service-accounts.html).
2. In Accounts & access, open Service accounts, select Add service account, name its owner and workload, and assign only the needed resource roles in the Access view. Keep production and nonproduction principals distinct.

**Automation:** The REST and CLI packs inventory the caller-visible service accounts; they do not establish role scope. The Terraform example creates an unbound service account. Choose one authorization model and review any bindings separately.

#### Code Implementation

{% include pack-code.html vendor="confluent-cloud" section="1.1" %}

#### Validation & Testing

Reconcile the service-account inventory and role bindings against workload ownership. Verify an authorized test workload can access its designated resource and ordinary access to an unrelated test resource is denied.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

## 2. Network, Integrations and Audit

### 2.1 Limit public ingress with approved IP groups

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-17 |

#### Description

Limit publicly reachable management or Kafka operations to intended public egress ranges.

#### Rationale

**Why This Matters:**

- A valid credential alone should not enable covered public operations from anywhere. Private connectivity is outside this filter boundary.

#### ClickOps Implementation

1. Confirm the available plan and effective administrative permissions in the [vendor documentation](https://docs.confluent.io/cloud/current/security/access-control/ip-filtering/manage-ip-filters.html).
2. Open Accounts & access → IP filtering. Document the target scope and operation group, record the prior filter, and stage required client egress IPs in IP groups. Attach those groups to the relevant IP filter after testing nonproduction clients and confirming operator recovery access.

**Automation:** Public documentation describes native CLI and API management; this guide does not include an IP-filter write pack because the correct operation group, egress sets and recovery depend on deployment topology.

#### Validation & Testing

Run documented benign requests from allowed and non-allowed egress against a sandbox with the intended scope; use logs to confirm the operation type. Verify private access separately.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-17 |

### 2.2 Preserve and monitor audit events

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-12 |

#### Description

Retain and monitor administrative changes and supported authorization events.

#### Rationale

**Why This Matters:**

- Unexpected key creation, role grants and network-filter changes can go unnoticed without an independent audit trail.

#### ClickOps Implementation

1. Confirm the available plan and effective administrative permissions in the [vendor documentation](https://docs.confluent.io/cloud/current/monitoring/audit-logging/cloud-audit-log-categories.html).
2. Follow the [Cloud audit-log configuration guide](https://docs.confluent.io/cloud/current/monitoring/audit-logging/configure.html) to identify the audit cluster, topic and service account. Use a dedicated audit-cluster key under your approved lifecycle process, restrict access to the destination and review retention independently. The topic is not browsable in the Cloud Console.

**Automation:** No SIEM query is supplied; confirm the event schema and destination mapping before writing a detection.

#### Validation & Testing

Make an approved benign administrative change in a sandbox and reconcile event type, actor, resource and delivery delay. Alert on missing delivery as well as on changes.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-12 |

## 3. Compliance Quick Reference

These mappings support control design; they are not evidence of certification or operating effectiveness.

| Section | Control | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 | Separate workload identities | AC-6 |
| 2.1 | Limit public ingress with approved IP groups | AC-17 |
| 2.2 | Preserve and monitor audit events | AU-12 |

## References

- [Cloud Security FAQ](https://docs.confluent.io/cloud/current/security/security-faq.html)
- [Service Accounts API](https://docs.confluent.io/cloud/current/ccloud/list-iam-v-2-service-accounts/)

## Changelog

- **0.1.0 (2026-11-27):** Initial guide and documented automation examples.
