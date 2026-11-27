---
layout: guide
title: "Amazon Bedrock Hardening Guide"
vendor: "Amazon Bedrock"
slug: "amazon-bedrock"
tier: "3"
category: "AI/ML Platform"
description: "Amazon Bedrock exposes foundation model inference and security configuration within AWS accounts"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

**Product Editions Covered:** Amazon Bedrock in supported commercial AWS Regions

## Overview

Amazon Bedrock exposes foundation model inference and security configuration within AWS accounts. Treat an account and Region as explicit evidence dimensions: model invocation logging and account-level enforced guardrails are regional, and an Organizations policy is a separate enforcement plane.

### Intended Audience

Platform administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Baseline controls for the documented deployment.
- **L2 (Walk):** Add verified controls where the workload needs stronger isolation.
- **L3 (Run):** Add controls warranted by higher-risk workflows and contractual requirements.

### Scope

Covers Bedrock account-level guardrails, AWS PrivateLink connectivity for documented Bedrock endpoints, and invocation logging. Does not assess AgentCore runtimes, account-wide AWS hardening, model safety guarantees, or prompt handling at the application layer.

---

## Table of Contents

1. [Model Safeguards](#1-model-safeguards)
2. [Network Isolation](#2-network-isolation)
3. [Logging and Data Handling](#3-logging-and-data-handling)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

---

## 1. Model Safeguards

### 1.1 Enforce a reviewed guardrail version

**Profile Level:** L2 (Walk)

#### Description

Apply a published, numeric guardrail version at the account level in each supported Region that runs in-scope inference. Use comprehensive system and message evaluation unless an exception is explicitly approved.

#### Rationale

- An application-level guardrail configuration may be absent or differ across workloads. Account-level enforcement supplies a separate safeguard; model exclusions, endpoint coverage and Organizations inheritance still matter.

#### Prerequisites

A published guardrail, an authorized administrator, approved model scope and a staged rollout. If a cross-account guardrail is used, confirm its resource policy grants the invoking principals evaluation access.

#### ClickOps Implementation

1. Open **Amazon Bedrock → Guardrails** in the target Region.
2. Under **Account-level enforcement configurations**, choose **Add**, choose the guardrail and numeric version, and select comprehensive guarding for system messages and messages.
3. Submit and repeat in every in-scope Region. Inspect any Organizations policy separately.

Source: [Vendor configuration reference](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails-enforcements.html).

#### Code Implementation

The CLI and Boto3 read the **account-level** configurations; neither determines the effective organization-wide policy.

{% include pack-code.html vendor="amazon-bedrock" section="1.1" %}

#### Validation & Testing

Check the approved ARN/version, comprehensive modes and inclusion/exclusion lists in each account and Region. Test benign synthetic prompts through supported application methods in a sandbox. An empty account list does not prove no Organizations policy applies.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Review false refusals and latency. IAM mistakes or unsupported models can break inference; pilot first.

#### Rollback Procedure

Restore the previous approved version/settings in the same account and Region. Separately revert the authorized Organizations change if one was made.

---

## 2. Network Isolation

### 2.1 Route production inference through PrivateLink

**Profile Level:** L2 (Walk)

#### Description

Provision an interface VPC endpoint for each in-scope Bedrock service plane from private workloads; Bedrock control-plane and Runtime are distinct endpoint services.

#### Rationale

- A private endpoint keeps supported traffic on private AWS routes, but does not on its own prevent the same role from using a public endpoint.

#### Prerequisites

VPC administrator, subnet and DNS design, endpoint security groups, approved inference roles and a test VPC.

#### ClickOps Implementation

1. In **VPC → Endpoints**, choose **Create endpoint**, select the documented Bedrock service for the intended Region and plane, and choose the intended VPC and subnets.
2. Enable private DNS where supported and permit TLS inbound only from the required workloads. Review the endpoint policy and, separately, the workload IAM boundary if public routes must be denied.

Source: [Vendor configuration reference](https://docs.aws.amazon.com/bedrock/latest/userguide/vpc-interface-endpoints.html).

#### Code Implementation

Use the AWS providing service for verification: this CLI read-back shows routing settings and the endpoint policy, not effective identity authorization.

{% include pack-code.html vendor="amazon-bedrock" section="2.1" %}

#### Validation & Testing

From an approved workload, resolve the service name to the intended private endpoint and validate normal connectivity. Confirm public-route restrictions separately; examining the endpoint object cannot demonstrate them.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Interface endpoints incur cost; private DNS can change routing for existing callers in the VPC.

#### Rollback Procedure

Restore approved DNS and role settings before removing an endpoint or retiring callers that depend on it.

---

## 3. Logging and Data Handling

### 3.1 Review and constrain model invocation logging

**Profile Level:** L2 (Walk)

#### Description

Make an explicit regional decision on invocation payload collection, limit enabled modalities to approved requirements and send logs to restricted same-account, same-Region destinations.

#### Rationale

- Invocation logs may contain model inputs and outputs. Collecting all payloads can create a new sensitive store; leaving logging disabled where required can eliminate evidence.

#### Prerequisites

Logging owner approval for content categories, retention and access; reviewed S3 or CloudWatch Logs delivery policy and compatible destination.

#### ClickOps Implementation

1. Open **Amazon Bedrock → Settings → Model invocation logging** in the target Region.
2. If required by policy, enable only approved modalities and select the authorized S3 or CloudWatch Logs destination. Configure destination retention and encryption separately.

Source: [Vendor configuration reference](https://docs.aws.amazon.com/bedrock/latest/userguide/model-invocation-logging.html).

#### Code Implementation

This verification pack reads settings only, not model content. Terraform supports a separate regional logging resource; reconcile state ownership and existing account settings before managing it.

{% include pack-code.html vendor="amazon-bedrock" section="3.1" %}

#### Validation & Testing

Verify the returned configuration matches decision and destinations. Use only a benign synthetic observation to verify delivery. This feature does not collect invocations on bedrock-mantle; validate alternate telemetry separately.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Logging may store sensitive content and incur costs. Restrict access before turning it on.

#### Rollback Procedure

Restore the previous settings or disable collection according to policy. Disabling collection does not remove already delivered records; handle them under the approved retention and incident process.

---

## 4. Compliance Quick Reference

These mappings indicate how settings can contribute to a control objective; they do not establish conformity or operation over a period.

| HTH control | NIST SP 800-53 Rev. 5 | Evidence to retain |
| --- | --- | --- |
| 1.1 | CM-6, SI-4 | Approved versions, scoped configuration and sandbox verification |
| 2.1 | SC-7 | Endpoint state, security group, route/IAM review |
| 3.1 | AU-2, AU-9 | Regional logging decision, restricted storage and delivery check |

## Appendix A: Automation and Evidence

REST control-plane operations require AWS Signature Version 4; the official CLI and SDK provide that signing. The AWS CLI also exposes configuration mutations; these packs intentionally verify only and perform no inference. AWS-specific policy documents and destinations must be reviewed independently. No Bedrock-specific CIS, STIG or SCuBA equivalent is claimed. The AWS cloud benchmark is not proof of Bedrock configuration. No live tenant checks were performed.

## Appendix B: References

- [AWS IAM actions and condition keys](https://docs.aws.amazon.com/service-authorization/latest/reference/list_bedrock.html)
- [Bedrock CloudTrail coverage](https://docs.aws.amazon.com/bedrock/latest/userguide/logging-using-cloudtrail.html)
- [AWS security reference architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture-generative-ai/bedrock-integration.html)
- [Terraform regional logging resource](https://registry.terraform.io/providers/hashicorp/aws/6.2.0/docs/resources/bedrock_model_invocation_logging_configuration)

## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial platform controls and documented verification packs | How to Harden Community |

## Contributing

Report inaccurate or outdated guidance through the [issue tracker](https://github.com/grcengineering/how-to-harden/issues).
