---
layout: guide
title: "Microsoft Copilot Studio Hardening Guide"
vendor: "Microsoft Copilot Studio"
slug: "copilot-studio"
platform: "Microsoft"
platform_slug: "microsoft-365"
product: "Microsoft Copilot Studio"
tier: "1"
category: "AI/ML Platform"
description: "Harden Copilot Studio agent identity, connectors, MCP, delegated agents, computer use, model providers and retained artifacts."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-12"
---

## Overview

This is a product guide within the [Microsoft platform](/guides/microsoft-365/). Apply the hub’s tenant MFA, privilege management, OAuth consent and audit requirements, plus [Microsoft Entra ID](/guides/microsoft-entra-id/) policies. Those do not configure Copilot Studio’s separate Power Platform and agent control surfaces.

### Intended Audience

Power Platform administrators, agent owners, security engineers and reviewers of third-party integrations.

### How to Use This Guide

- **L1 (Crawl):** Minimum production controls.
- **L2 (Walk):** Enhanced controls for sensitive workflows.
- **L3 (Run):** Regulated deployments must additionally validate their specific edition, region and authorization boundary.

### Scope

Microsoft Copilot Studio, principally its **standard harness**, Power Platform environments, Dataverse records and connected tools. New GitHub Copilot/Customer Conversation harnesses have different feature availability; validate applicability rather than assuming identical settings. This is not a complete Microsoft 365 Copilot or Foundry guide. No tenant was modified or live-validated.

This guide reconciles Pluto’s CopilotSec research with current Microsoft documentation. The [research ledger](/research/pluto-copilot-reconciliation-2026-11-12/) records coverage, conflicting defaults and unresolved surfaces. Security recommendations below are HTH’s deployment choices, not claims that a model can enforce a policy by instructions alone.

## Table of Contents

1. [Identity and production ownership](#1-identity-and-production-ownership)
2. [Integration supply chain](#2-integration-supply-chain)
3. [Execution and model boundaries](#3-execution-and-model-boundaries)
4. [Retention and monitoring](#4-retention-and-monitoring)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

## 1. Identity and production ownership

### 1.1 Require authentication on every production channel

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-3, IA-2 |

#### Description

Require an identity check before an internal agent exposes data or actions. Inventory every published channel; an authenticated Teams deployment does not prove that a second web channel is protected.

#### Rationale

**Why This Matters:**
- Anonymous callers must not inherit privileged integrations.
- Review permissions at each boundary, not just the sign-in screen.

**Attack Prevented:** Unauthenticated access to internal agents.

#### ClickOps Implementation

1. Open the agent’s **Settings > Security > Authentication**. Select **Authenticate with Microsoft**, or configure **Authenticate manually** for a supported deployment.
2. Save and **Publish**; an unsaved or unpublished authentication change does not protect the live agent.
3. Review **Channels** and retire unused public/demo deployments. Apply the tenant policy in §2.1 to prevent makers restoring anonymous access.

#### Code Implementation

{% include pack-code.html vendor="copilot-studio" section="1.1" %}

#### Validation & Testing

Test each published URL signed out and with an unauthorized account. Both must fail before sensitive tools or knowledge run. Re-test after publishing.

**Sources:** [User authentication](https://learn.microsoft.com/en-us/microsoft-copilot-studio/configuration-end-user-authentication).

### 1.2 Separate production makers, operators, and readers

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, CM-3 |

#### Description

Use dedicated production environments and narrowly assigned maker roles. A colleague allowed to chat should not automatically become an editor. Maintain an accountable owner and reviewed release record for each agent.

#### Rationale

**Why This Matters:**
- Editing an agent changes its effective supply chain.
- Review permissions at each boundary, not just the sign-in screen.

**Attack Prevented:** Unauthorized agent modification and privilege expansion.

#### ClickOps Implementation

1. In the **Power Platform admin center**, restrict environment membership using approved Microsoft Entra security groups.
2. Assign authoring roles only to approved makers through Dataverse group teams. Avoid routine System Administrator access.
3. In the agent’s **… > Share**, distinguish collaboration from permission to chat; review recipients and role changes before saving.
4. Require independent approval before promoting changes to production.

#### Code Implementation

{% include pack-code.html vendor="copilot-studio" section="1.2" %}

#### Validation & Testing

A chat-only test user must not edit tools, instructions or sharing. Confirm production changes have a reviewer and compare the agent inventory with your approved register.

**Sources:** [Secure projects](https://learn.microsoft.com/en-us/microsoft-copilot-studio/guidance/sec-gov-phase3); [Sharing](https://learn.microsoft.com/en-us/microsoft-copilot-studio/admin-share-bots).

### 1.3 Prevent unintended use of maker credentials

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-3, AC-6 |

#### Description

For user-driven internal agents, require end-user credentials rather than lending every caller the maker’s authority. Handle unattended workloads separately with explicitly reviewed least-privilege identities.

#### Rationale

**Why This Matters:**
- A valid caller is not necessarily entitled to the maker’s permissions.
- Review permissions at each boundary, not just the sign-in screen.

**Attack Prevented:** Confused-deputy access through shared credentials.

#### ClickOps Implementation

1. In **Power Platform admin center > Manage > Environments > [environment] > Settings > Product > Features > Copilot Studio agents**, set **Control maker credential options** to **End-user credentials** for the user-driven environment.
2. For grouped environments, configure the environment group instead.
3. Pilot first: enforcement affects existing tools and can break scheduled/background agents that lack a live user. Do not quietly restore maker credentials to fix those failures.

**Automation:** Unverified for direct enforcement of this precise setting in this review. Use the documented console path; the surface census records known APIs and remaining schema gaps rather than asserting no automation exists.

#### Validation & Testing

Try an action with a user who lacks permission at the target service. It must remain denied. Test autonomous workloads separately before rollout.

**Sources:** [Credential governance](https://learn.microsoft.com/en-us/microsoft-copilot-studio/configure-no-maker-authentication).

## 2. Integration supply chain

### 2.1 Enforce connector, channel, trigger, and HTTP data policies

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-4 |

#### Description

Establish a scoped Power Platform data policy for production. Use Blocked for disallowed capabilities; Non-business is a segregation group, not an unconditional deny.

#### Rationale

**Why This Matters:**
- A prompt is not an egress policy.
- Review permissions at each boundary, not just the sign-in screen.

**Attack Prevented:** Exfiltration through unapproved connectors or channels.

#### ClickOps Implementation

1. In the **Power Platform admin center**, create or edit a **Data policy**, classify connectors, select environments, and review before saving.
2. Block **Chat without Microsoft Entra ID authentication in Copilot Studio**. Block unused Direct Line and other publication channels, HTTP, skills, and event triggers.
3. Put approved business connectors together; explicitly block rejected connectors, including those underlying MCP. Use documented endpoint filtering where HTTP is necessary.
4. Test effects on existing agents. **Current Microsoft documentation specifies real-time enforcement**, not merely a publish-time check.

**Automation:** Unverified for direct enforcement of this precise setting in this review. Use the documented console path; the surface census records known APIs and remaining schema gaps rather than asserting no automation exists.

#### Validation & Testing

Attempt a blocked connector in a test agent and in an already-published test deployment. Confirm a policy violation and preserve the approved exception list.

**Sources:** [Copilot data policies](https://learn.microsoft.com/en-us/microsoft-copilot-studio/admin-data-loss-prevention); [Policy configuration](https://learn.microsoft.com/en-us/power-platform/admin/prevent-data-loss).

### 2.2 Constrain HTTP destinations and render structured output

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | SI-10 |

#### Description

Do not echo an arbitrary upstream response as authoritative company guidance. Use fixed destinations, validate returned values and render only necessary fields through a maker-controlled template. Structured JSON alone does not make strings or URLs trustworthy.

#### Rationale

**Why This Matters:**
- A compromised endpoint can return convincing instructions.
- Review permissions at each boundary, not just the sign-in screen.

**Attack Prevented:** Upstream content injection and phishing through agent output.

#### ClickOps Implementation

1. In the relevant **Topic**, inspect **Advanced > Send HTTP request** nodes. Replace user-controlled destination URLs with approved destinations and enforce §2.1 endpoint restrictions.
2. Set **Response data type > From Sample Data > Get schema from sample JSON** for the expected response shape.
3. Render approved fields, not the whole response body; reject unexpected URLs, values and errors. Keep external-source attribution outside upstream-controlled text.

**Automation:** Unverified for direct enforcement of this precise setting in this review. Use the documented console path; the surface census records known APIs and remaining schema gaps rather than asserting no automation exists.

#### Validation & Testing

Feed an unexpected URL, extra field, markup and error body from a test endpoint. None should become a trusted link or instruction; malformed responses should fail closed.

**Sources:** [HTTP nodes](https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-http-node).

### 2.3 Allowlist MCP tools and review upstream changes

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-3, AC-6 |

#### Description

Treat MCP servers as changing dependencies. Approving a server is not approval of every future tool or changed description.

#### Rationale

**Why This Matters:**
- Server updates can expand agent capabilities without a new integration.
- Review permissions at each boundary, not just the sign-in screen.

**Attack Prevented:** Tool poisoning and supply-chain capability expansion.

#### ClickOps Implementation

1. Open **Agent > Tools > [MCP server]**. Turn **Allow all** off and enable only approved individual tools.
2. Save and publish. With Allow all off, newly introduced tools remain disabled by default.
3. Apply data policy to the underlying connector, review server identity and permissions, and compare tool names, descriptions and schemas with the approved baseline.
4. Remove unused servers; do not trust a catalog risk score as authorization.

**Automation:** Unverified for direct enforcement of this precise setting in this review. Use the documented console path; the surface census records known APIs and remaining schema gaps rather than asserting no automation exists.

#### Validation & Testing

Add a harmless test tool on an owned test server and confirm it stays disabled. Change a description and verify your review process detects it. A tool inventory is not proof that runtime content is safe.

**Sources:** [MCP selection](https://learn.microsoft.com/en-us/microsoft-copilot-studio/mcp-add-components-to-agent); [Dynamic MCP behavior](https://learn.microsoft.com/en-us/microsoft-copilot-studio/agent-extend-action-mcp).

### 2.4 Review child agents, routing, and completion boundaries

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-3, AC-6 |

#### Description

Inventory delegated agents and their instructions, tools and inputs alongside the parent. Choose explicit invocation for sensitive operations rather than broad description-based routing.

#### Rationale

**Why This Matters:**
- A parent can delegate authority to a less-reviewed dependency.
- Review permissions at each boundary, not just the sign-in screen.

**Attack Prevented:** Routing hijack and unreviewed delegated actions.

#### ClickOps Implementation

1. Open the parent’s **Agents** page and inspect each child, its owner, instructions, tools and knowledge.
2. In child details, review **When will this be used?** and **Outputs > After running**.
3. Do not treat a fixed parent response or adaptive card as a child-output security filter: these choices govern the parent’s completion, not messages the child sends while executing.
4. Review component changes before release; the hash pack flags changes for review, not maliciousness.

#### Code Implementation

{% include pack-code.html vendor="copilot-studio" section="2.4" %}

#### Validation & Testing

Trigger sensitive and unrelated queries. Confirm only intended agents run, inspect every user-visible child message, and test tool permissions independently of wording.

**Sources:** [Child-agent behavior](https://learn.microsoft.com/en-us/microsoft-copilot-studio/add-agent-child-agent).

## 3. Execution and model boundaries

### 3.1 Disable unnecessary computer use and constrain approved runs

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, SC-7 |

#### Description

Treat computer use as a separate execution and credential boundary. Disable the tool when unnecessary; approved runs require limited destinations and a managed machine.

#### Rationale

**Why This Matters:**
- A browser session may possess more authority than the chat user.
- Review permissions at each boundary, not just the sign-in screen.

**Attack Prevented:** Desktop-mediated data exfiltration and privileged actions.

#### ClickOps Implementation

1. In **Agent > Tools**, disable unused computer-use tools. For approved tools, select the intended **Machine**, enable **Access control** with explicit websites/apps, and turn **Enforce HTTPS** on.
2. Prefer per-user machine credentials for conversational workflows. Keep passwords out of instructions; review stored credential scope and run artifacts.
3. Use a dedicated managed machine. The Microsoft-hosted browser is not tenant Entra-joined or Intune-managed; both hosted-browser and Cloud-PC-pool options are documented as preview.
4. Test human supervision and approval requirements before enabling writes.

**Automation:** Unverified for direct enforcement of this precise setting in this review. Use the documented console path; the surface census records known APIs and remaining schema gaps rather than asserting no automation exists.

#### Validation & Testing

Attempt a harmless action outside the allowlist. **Access control restricts interaction, not opening a site**; it is not a network firewall. Check screenshots, logs and target permissions using synthetic data.

**Sources:** [Computer use](https://learn.microsoft.com/en-us/microsoft-copilot-studio/computer-use); [Runtime choices](https://learn.microsoft.com/en-us/microsoft-copilot-studio/configure-where-computer-use-runs).

### 3.2 Limit dynamic tool execution and require confirmation

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-3, SI-10 |

#### Description

For sensitive tools, use explicit topic invocation, fixed validated inputs and end-user confirmation. Treat these as complementary controls, not a substitute for target-system authorization.

#### Rationale

**Why This Matters:**
- Broad orchestration can select a powerful tool from untrusted context.
- Review permissions at each boundary, not just the sign-in screen.

**Attack Prevented:** Unintended consequential tool execution.

#### ClickOps Implementation

1. Open **Agent > Tools > [tool] > Details > Additional details**. Clear **Allow agent to decide dynamically when to use the tool** where explicit invocation is required.
2. Set **Ask the end user before running** to Yes for consequential user-driven actions.
3. Under **Inputs**, validate values and use **Custom value** for destinations or other parameters that users/model inference must not choose.

**Automation:** Unverified for direct enforcement of this precise setting in this review. Use the documented console path; the surface census records known APIs and remaining schema gaps rather than asserting no automation exists.

#### Validation & Testing

Try to invoke the tool indirectly from retrieved content and use an out-of-range input. Confirm no action occurs without the intended topic, valid parameters and required approval.

**Sources:** [Tool controls](https://learn.microsoft.com/en-us/microsoft-copilot-studio/add-tools-custom-agent).

### 3.3 Approve model providers across every model-using component

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | SA-9, CM-3 |

#### Description

Maintain a provider/model allowlist covering the agent, prompt tools and computer use. A primary-model selection alone does not describe the complete processing chain.

#### Rationale

**Why This Matters:**
- Different components can send data to different approved processors.
- Review permissions at each boundary, not just the sign-in screen.

**Attack Prevented:** Unreviewed processing and incompatible residency/compliance assumptions.

#### ClickOps Implementation

1. Review each provider’s processing terms and deployment suitability before enabling it in Microsoft 365.
2. In **Power Platform admin center > Manage > Environments > [environment] > Settings > Product > Features**, turn unapproved external provider settings off. Use group rules for managed environment groups.
3. Review the agent’s model selection and every prompt/computer-use model. Exclude preview/experimental options from production unless separately approved; validate supported alternatives before disabling a used provider.

**Automation:** Unverified for direct enforcement of this precise setting in this review. Use the documented console path; the surface census records known APIs and remaining schema gaps rather than asserting no automation exists.

#### Validation & Testing

Verify unapproved providers are unavailable to makers and exercise existing agents after the change. Capture provider, model, region and component in the release record.

**Sources:** [External model controls](https://learn.microsoft.com/en-us/power-platform/admin/allow-llm-generative-responses); [Model lifecycle](https://learn.microsoft.com/en-us/microsoft-copilot-studio/guidance/plan-agent-model-lifecycle).

### 3.4 Restrict grounding and validate moderation behavior

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | SI-10 |

#### Description

Use approved knowledge sources for policy-sensitive answers. Disable unnecessary web search and unsupported-answer paths, while recognizing that grounding and moderation do not eliminate prompt injection.

#### Rationale

**Why This Matters:**
- Open-ended sources widen what can influence an answer.
- Review permissions at each boundary, not just the sign-in screen.

**Attack Prevented:** Untrusted grounding and fabricated authoritative responses.

#### ClickOps Implementation

1. Review both **Knowledge** sources and topic-level generative-answer nodes. Remove unapproved sources.
2. In **Generative AI > Knowledge**, turn **Allow ungrounded responses** off and disable **Use information from the web/Web Search** unless required.
3. Review content moderation for the agent and topic overrides. Choose the strictest level compatible with the approved use case and test it.

**Automation:** Unverified for direct enforcement of this precise setting in this review. Use the documented console path; the surface census records known APIs and remaining schema gaps rather than asserting no automation exists.

#### Validation & Testing

Ask questions outside the approved corpus, including malicious instructions in test documents. Confirm fallback behavior. Turning off ungrounded responses does not prevent general knowledge being combined with retrieved material.

**Sources:** [Knowledge configuration](https://learn.microsoft.com/en-us/microsoft-copilot-studio/knowledge-copilot-studio); [Prompt-model settings](https://learn.microsoft.com/en-us/microsoft-copilot-studio/prompt-model-settings).

## 4. Retention and monitoring

### 4.1 Set transcript access and retention independently

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-9, AU-11 |

#### Description

Approve who can read conversation records and how long each copy persists. Distinguish Dataverse retention from temporary Copilot Studio storage and Purview records.

#### Rationale

**Why This Matters:**
- Conversation evidence can become a second sensitive-data repository.
- Review permissions at each boundary, not just the sign-in screen.

**Attack Prevented:** Unauthorized disclosure through retained conversation data.

#### ClickOps Implementation

1. In **Power Platform admin center > Manage > Environments > [environment] > Settings > Product > Features > Copilot Studio agents**, configure transcript viewing/downloading and saving deliberately. Use group rules where required.
2. In Power Apps, review **ConversationTranscript** retention and approved cleanup processes, preserving legal holds. Do not assume hiding downloads deletes stored data.
3. Account for temporary Copilot Studio storage (up to 28 days) and separate Purview retention. Turning Dataverse saving off can take up to 24 hours and affects reporting.

**Automation:** Unverified for direct enforcement of this precise setting in this review. Use the documented console path; the surface census records known APIs and remaining schema gaps rather than asserting no automation exists.

#### Validation & Testing

With synthetic conversations, verify allowed/denied viewers, saved records, and expiration in each store. Test the incident-response workflow before shortening retention.

**Sources:** [Transcript controls](https://learn.microsoft.com/en-us/microsoft-copilot-studio/admin-transcript-controls); [Power Apps transcripts](https://learn.microsoft.com/en-us/microsoft-copilot-studio/analytics-transcripts-powerapps).

### 4.2 Audit access to run artifacts without exporting secrets

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, AU-9 |

#### Description

Review Dataverse privileges and retention for computer-use artifacts separately from normal transcripts. Screenshots and detailed logs can reveal sensitive material.

#### Rationale

**Why This Matters:**
- A workflow’s data exposure can outlive its execution.
- Review permissions at each boundary, not just the sign-in screen.

**Attack Prevented:** Overbroad access to stored execution artifacts.

#### ClickOps Implementation

1. Review environment security roles and effective table permissions, including custom roles and application users; do not rely on role names alone.
2. Use **Power Apps > Tables > All** to inspect the relevant artifact tables with an approved administrator. Inventory metadata before opening content.
3. Define approved retention/cleanup for artifacts and document legal-hold exceptions. The supplied inventory is read-only and never deletes records or downloads binary contents.

#### Code Implementation

{% include pack-code.html vendor="copilot-studio" section="4.2" %}

#### Validation & Testing

Check access using a low-privilege test identity. Review the inventory’s timestamps and types against synthetic computer-use runs; do not assume every flow-session binary is a screenshot.

**Sources:** [Flow-session binary schema](https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/reference/flowsessionbinary?view=dataverse-latest); [Run monitoring](https://learn.microsoft.com/en-us/microsoft-copilot-studio/monitor-computer-use).

### 4.3 Verify audit coverage and deployment drift

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-6, CM-3 |

#### Description

Maintain evidence of approved configuration, deployment changes and runtime events. Test the logging pipeline for every enabled channel instead of assuming one dashboard captures everything.

#### Rationale

**Why This Matters:**
- An unobserved configuration change can remove a preventive control.
- Review permissions at each boundary, not just the sign-in screen.

**Attack Prevented:** Undetected agent modification and delayed incident response.

#### ClickOps Implementation

1. Use **Microsoft Purview > Audit** and the applicable DSPM activity views to verify Copilot Studio events and access restrictions.
2. Compare the read-only agent inventory and component hashes with each approved release. Investigate differences before republishing.
3. Check channel-specific licensing prerequisites; non-Microsoft-channel Purview support requires pay-as-you-go billing. Retain raw evidence only in an approved restricted repository.

**Automation:** Unverified for direct enforcement of this precise setting in this review. Use the documented console path; the surface census records known APIs and remaining schema gaps rather than asserting no automation exists.

#### Validation & Testing

Make a harmless change in a test agent, run a test conversation, and find corresponding evidence. Record missing events and retention limits rather than claiming full prompt/tool visibility.

**Sources:** [Purview coverage](https://learn.microsoft.com/en-us/purview/ai-copilot-studio).

## 5. Compliance Quick Reference

These are thematic mappings, not product certification or a claim of benchmark equivalence.

| Control family | NIST SP 800-53 Rev. 5 | Guide sections |
|---|---|---|
| Access enforcement / least privilege | AC-3, AC-6 | 1, 2, 3 |
| Configuration change control | CM-3 | 1.2, 2.3, 2.4, 4.3 |
| Audit review / retention | AU-6, AU-11 | 4 |

No Copilot Studio-specific CIS/STIG/SCuBA prescription was verified in this review. Microsoft 365/Entra baselines remain complementary, not substitutes for agent-specific controls.

## Appendix A: Automation and applicability

The Code Packs are read-only audits, not enforcement or tenant-compliance certification. They enumerate all returned pages, fail on errors, restrict pagination to the selected HTTPS origin, and avoid transcript bodies/binary downloads. Run under a scoped identity in every relevant environment. Empty or permission-limited output does not prove a clean tenant.

Power Platform CLI, Dataverse Web API, Terraform Power Platform provider and Dataverse .NET SDK are real surfaces. Direct setting writes and complete Terraform-resource coverage remain explicitly scoped research gaps; no speculative endpoint is supplied. Two pack types are provided (API and CLI), rather than cosmetic placeholders for unsupported operations.

## Appendix B: References

- [Microsoft security and governance](https://learn.microsoft.com/en-us/microsoft-copilot-studio/security-and-governance)
- [Microsoft secure-project guidance](https://learn.microsoft.com/en-us/microsoft-copilot-studio/guidance/sec-gov-phase3)
- [Pluto: Securing Copilot Studio](https://pluto.security/blog/securing-copilot-studio-a-practical-hardening-guide/)
- [Pluto: Inside Copilot Studio](https://pluto.security/blog/inside-copilot-studio-how-microsofts-citizen-developer-agent-platform-actually-works/)

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-12 | 0.1.0 | ai-drafted | Initial Pluto-to-Microsoft reconciliation: identity, DLP, MCP, HTTP, child agents, computer use, model governance, retention and read-only audits; current primary-source corrections and evidence gaps documented | Jai |

## Contributing

Submit corrections and verified implementation evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Do not include tenant data or credentials.
