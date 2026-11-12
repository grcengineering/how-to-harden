---
layout: default
title: "Pluto Copilot Studio reconciliation"
permalink: /research/pluto-copilot-reconciliation-2026-11-12/
---

# Pluto Copilot Studio reconciliation (2026-11-12)

## Scope and baseline

Microsoft → Microsoft platform → Microsoft Copilot Studio, confirmed through Microsoft's [security and governance documentation](https://learn.microsoft.com/en-us/microsoft-copilot-studio/security-and-governance). The existing Microsoft hub, Entra and Intune guides did not mention Copilot Studio. Baseline: zero product controls/packs; resulting guide: 14 controls, four with read-only automation, two implemented pack types. Existing Microsoft common controls are linked, not duplicated. No live tenant access or claim of ai-validated status.

## Source-first reconciliation

The [Plutonium safe-use index](https://plutonium.pluto.security/guides/) links three Microsoft articles. All three were fetched in this session. The former copilotsec.ai portal redirects to Plutonium; its current safe-use catalog points to these same three articles:

- [Introducing CopilotSec](https://pluto.security/blog/introducing-copilotsec-a-community-knowledge-hub-for-security-of-the-microsoft-ai-ecosystem/): discovery/index and connector-review context, not a technical baseline on its own.
- [Inside Copilot Studio](https://pluto.security/blog/inside-copilot-studio-how-microsofts-citizen-developer-agent-platform-actually-works/): architecture/research context; model, delegation and artifact risks mapped to sections 2–4. Research-tenant defaults are not promoted to universal facts.
- [Securing Copilot Studio](https://pluto.security/blog/securing-copilot-studio-a-practical-hardening-guide/): prescriptive candidate inventory below.

| Candidate theme | HTH disposition |
|---|---|
| Authentication/channels | New §1.1 and §2.1; primary-source enum correction in audit |
| HTTP passthrough | New §2.2; structured values still require validation |
| Delegated agents | New §2.4; completion options do not suppress child messages |
| MCP changes | New §2.3; tool allowlist and connector policy |
| Computer use | New §3.1, §4.2; separate execution and artifact boundaries |
| Sensitive routing | New §3.2, §3.4 |
| Tenant/environment policy | New §1.2, §2.1 |
| Opaque names | Not adopted as access control; avoid secrets in names, but obscurity cannot substitute for permissions |
| Retention and audits | New §4.1–4.3; metadata-only packs |
| Model/knowledge recommendations | New §3.3–3.4; current provider gates and grounding limitations |

## Verified conflicts and bounded omissions

- Microsoft [bot schema](https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/reference/bot?view=dataverse-latest) documents authenticationmode **0 Unspecified, 1 None, 2 Integrated, 3 Custom Entra ID, 4 Generic OAuth2**. The audit preserves these values and flags unknown values; no heuristic is labeled proof of secure authentication.
- Microsoft [data-policy documentation](https://learn.microsoft.com/en-us/microsoft-copilot-studio/admin-data-loss-prevention) specifies real-time enforcement. Existing-agent testing remains required, but the guide does not claim enforcement is only point-in-time.
- [Child-agent completion](https://learn.microsoft.com/en-us/microsoft-copilot-studio/add-agent-child-agent) governs the parent's completion message, not earlier child messages. A fixed completion is not a sanitization boundary.
- [Runtime choices](https://learn.microsoft.com/en-us/microsoft-copilot-studio/configure-where-computer-use-runs) label both hosted browser and Cloud PC pools preview. Neither is described here as a universally production-ready substitute.
- [Flow-session binary schema](https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/reference/flowsessionbinary?view=dataverse-latest) was verified for metadata reads. The research-specific `type='CuaScreenshot'` filter was not confirmed in that current schema and is not shipped. No screenshot-delete script or universal default-role matrix is copied.
- Broad tenant enumeration of Agent ID through Graph with no administrator privilege was not independently established. No enumeration-permission claim or opaque-name enforcement pack is shipped.
- Fixed provider/model versions, unconditional persisted chain-of-thought, specific default role depths, screenshot retention guarantees and universal prompt-injection bypass claims are research observations, not current guarantees established here. Validate effective permissions/artifacts with synthetic tenant tests.

## Automation surface census

| Surface | Evidence and disposition | Read/write decision |
|---|---|---|
| Terraform | [Microsoft provider resource](https://github.com/microsoft/terraform-provider-power-platform/blob/main/docs/resources/data_loss_prevention_policy.md) confirms DLP resource; registry index returned a JavaScript shell and GitHub directory fetch was blocked. Complete resource/data-source enumeration remains incomplete, not absent. [Releases](https://github.com/microsoft/terraform-provider-power-platform/releases) flag tenant-setting deprecations. | Do not invent a comprehensive Terraform policy; scoped follow-up needed for schema/version-locked enforcement. |
| API | Current [bot](https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/reference/bot?view=dataverse-latest), [botcomponent](https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/reference/botcomponent?view=dataverse-latest), [flowsessionbinary](https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/reference/flowsessionbinary?view=dataverse-latest) schemas fetched; handles available. [Paging contract](https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/query/page-results) verified. GraphQL control surface not verified. | Three GET-only audits; no direct mutation of agent internals. |
| CLI | Existing inventory had M365/Entra/Intune rows but no Copilot Studio. [Official PAC command index](https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/copilot) confirms list/clone/pull/push/publish/quarantine. | Available `pac copilot list --environment` shipped; write commands deliberately not executed. |
| SDK | [Dataverse ServiceClient](https://learn.microsoft.com/en-us/power-apps/developer/data-platform/sdk-client-transition) is the current .NET client. | Same record plane as Web API; no redundant SDK pack or unverified setting setter. |
| Config | PAC workspace authoring exists; HTTP node and tool control prose verified. Full stable setting serialization for all controls not verified. | No fabricated YAML toggles; console implementation remains available. |
| SIEM | [Purview support](https://learn.microsoft.com/en-us/purview/ai-copilot-studio) fetched; channel prerequisites apply. | No invented Sentinel/Splunk table or event schema; hub audit guidance linked. |

The two implemented pack types are intentionally read-only. This is not a claim that the other four surfaces are unavailable. Settings without verified setters carry explicit automation gaps in the guide.

## Trust Center / baseline discovery boundary

Microsoft's official security overview links the [Microsoft Trust Center](https://www.microsoft.com/en-us/trust-center/product-overview). Its product catalog includes Microsoft 365 and Power Platform. The [Service Trust Portal](https://servicetrust.microsoft.com/) returned a JavaScript shell; restricted document catalog completeness and government secure-configuration documents remain unverified. No gated report was downloaded and no assurance page was admitted as a configuration baseline. Public Microsoft Learn secure-project and governance guidance supplies the implementable controls above.

Bounded public searches for Copilot Studio CIS, STIG and SCuBA did not establish a dedicated prescription. This is not proof that none exists. Maester's catalog surfaced Copilot Studio tests as a possible additional assessment lead; their individual implementation was not verified in this pass. Microsoft 365/Entra benchmark coverage is complementary.

## Validation

Four shell scripts pass bash syntax checks. Eleven offline tests exercise pagination, exact authentication classifications, unknown enum handling, foreign-origin and looping links, error fail-closed, hash-only component output, invalid origins and metadata-only artifact queries. Fixture tests do not prove live permissions, API availability in every region/harness, or effective control enforcement. Raw component definitions are fetched only into a restricted temporary directory to calculate hashes, never printed; protect the machine and token accordingly.
