# Pluto / OpenAI reconciliation — 2026-11-12

Scope: public Pluto Dots and Codex practical guides and their linked architecture guidance, compared with current HTH Dots, Work/Codex, Enterprise and API Platform controls. No tenant changes or live validation. Public vendor Markdown bodies were fetched this session; automation capabilities are not inferred from third-party prose.

## Sources and disposition

| Source | Recommendation groups | HTH disposition |
|--------|-----------------------|-----------------|
| [Dots practical guide](https://pluto.security/blog/chatgpt-dots-security-practical-guide/) | Cloud/browser/password manager; local device controls; approval rules; memory; delegation; logging | 3.1–3.4, 4.1–4.4, 5.2, 6.1, 7.1–7.2 already cover the baseline. Tightened browser-session cleanup, future app-action defaults and separate reviewer/telemetry boundaries. Added explicit delegation control 2.3 and local denied-read config pack at 3.4. |
| [Personal-assistant architecture](https://pluto.security/blog/personal-ai-assistant-security/) | Runtime packages; desktop credential redirection; approval/artifact binding; persistent context; cross-channel delegation | Explicit dispositions below. Historical research and proposed platform guarantees are not current exploitability evidence or available admin settings. |
| [Codex practical guide](https://pluto.security/blog/securing-openai-codex/) | Enforced requirements; sandbox/network; browser/desktop; cloud/GitHub/API identities; tool supply chain; audit/hooks; phased rollout | Work/Codex 1.1–1.3, 2.1–2.7, 3.1–3.4, 4.1–4.4 and OpenAI API identity controls already cover these. Keep current HTH corrections rather than restoring May assumptions. No additional duplicate Codex pack warranted. |

### Dots detailed coverage

- Cloud capabilities/password manager: 3.1–3.3; session cleanup now explicit because unsaved browser sessions still authorize access.
- Local grant, device policy/MDM, per-device revocation and positive/negative runtime tests: 3.4 and Work/Codex 1.1, 2.1–2.4. New 3.4 emitter prevents conflating read-only with hidden secrets. Native Windows subprocess caveat retained.
- Shell rules/custom rules/approval reviewer: 4.1–4.4; updated 4.2 clarifies that current requirements support both prompt and forbidden. Neither becomes a browser/MCP boundary. Do not copy Pluto's obsolete “only forbidden” assertion.
- Saved context/shared memory/source disconnect/reset: 5.2, 7.2; current deletion is within 30 days, not immediate erasure. Separate ChatGPT Memory and artifacts survive. No invented per-note deletion.
- Codex task versus environment-management permissions, private sharing, environment-owned credentials and network identities: new 2.3, with actual current public-internet UI rather than Pluto's historical label. Public restrictions do not disable VPN.
- App permissions/future actions/source identity: 2.1; explicit future-default denial does not retroactively disable enabled tools.
- Compliance, local OTel and Activity View: 6.1–6.2; local collector excludes cloud orchestration. Verification uses receiving-service records and does not promise one event per action.

### Personal-assistant architecture: full recommendation disposition

The article body was read through its conclusion, including its three execution zones and all five failure-path sections. The following closes the architecture-source mapping separately from the practical guide.

| Recommendation or research boundary | HTH treatment |
|---|---|
| Separate endpoint, orchestrator and hosted machine | Dots overview, 2.3, 3.1–3.4, 4.2; no local policy treated as a universal cloud control |
| Review vendor package inventory, patch status and reachable vulnerable code | Vendor-assurance follow-up, not a customer hardening API. 3.1–3.2 limit exposure; no present CVE totals/compromise assertion copied from the dated scan |
| Review extracted executable content, not merely archive listings | 4.4 validation now checks reviewed artifacts/actual invocation. No archive-scanning pack represented as a complete defense |
| Restrict egress and minimize credential lifetime | 2.1, 2.3, 3.2 and Work/Codex 1.2/3.1; source-service credentials remain independently scoped |
| Protect client launch configuration and use managed signed updates | 3.4 now links Work/Codex 4.3. Endpoint-redirection research is version/test-specific; no invented production override-disabling key or claim of a fixed current build |
| Bind approvals to exact execution, including post-review mutations | 4.4 adds operator validation. Immutable hash binding is a supplier architectural requirement, not an established Dots feature |
| Keep memory provenance, separation and selective deletion | 5.2/7.2 constrain inputs and reset context. Per-entry deletion and perfect partitioning are not claimed; current supported admin lifecycle supersedes older no-reset assertions |
| Review unattended work and offboarding | 7.1–7.2 and Activity View review; scheduled work and delegated work checked separately |
| Preserve originating requester and approval boundary on delegation | 2.2–2.3 validation; low-trust channel input must not acquire environment credentials by implication |
| Minimize account-wide connectors; monitor organization evidence | 2.1 and 6.1; task-scoped grants are not falsely represented as a native enforcement capability |

### Codex detailed coverage and rejected assumptions

- Workspace versus filesystem boundary and separate ChatGPT/API Platform RBAC: overview, 1.1–1.2; no cross-plane admin endpoints substituted.
- Admin requirements rather than editable defaults: 2.1 and existing native config pack. Current policy resolution is service-owned; do not ship a copied historical first-group-match algorithm.
- Read-only does not prohibit every command or conceal readable secrets; HTH 2.1 correctly uses deny_read and platform-specific validation.
- The older `untrusted` approval value is retired in current docs. HTH keeps on-request and valid requirements rather than the article's old ranked table.
- Egress/search independent controls: 2.4; browser routes 2.2; desktop/paired/SSH surfaces 1.3 and 2.3. Natural-language instructions are not enforcement.
- Cloud environments/repo access/service accounts: 2.7, 3.1, API Platform guide. Environment-owned versus personal credential distinction preserved.
- Reviewed plugins/MCP/skills/hooks/project trust: 2.5 and native config pack. Pluto's Marketplace is not an automatic approval or proof of safety.
- Audit: 3.3 preserves current version caveat, minimal prompt/result content and independent Compliance/API/local streams. Analytics is not forensic evidence.
- Hook enforcement: 2.6 preserves fail-open timeout/transport behavior and orchestrator/local differences; do not promote Pluto's broad “genuine enforcement” statement into a fail-closed guarantee.
- Pilot, effective-policy tests, re-review and containment: existing validation sections cover the operational recommendations; no speculative vendor scheduling API is added.

## Fetched primary references and automation census

| Surface | Evidence checked | Disposition |
|---------|------------------|-------------|
| Terraform | [Managed configuration](https://learn.chatgpt.com/docs/enterprise/managed-configuration) and existing source ledger | Public policy support is described, but no newly verified provider resource/schema obtained; no fabricated enforcement pack. |
| API | [Dots admin](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide), [Dots security](https://learn.chatgpt.com/docs/enterprise/dots-security), existing Compliance exporter | Existing read-only exporter retained. Current environment/dots policy write schema remains unverified; console guidance only. |
| CLI | `docs/research/cli-inventory.md` rows18/131; [Agent Security](https://learn.chatgpt.com/docs/enterprise/agent-security) | Codex local controls are not dots workspace administration. No new dots admin CLI claimed. |
| SDK | Current vendor administration/managed-configuration references | No new dots/environment administration SDK contract verified; API Platform SDK not substituted. |
| Config | [Managed configuration](https://learn.chatgpt.com/docs/enterprise/managed-configuration) | Current available allowed_sandbox_modes and permissions.filesystem.deny_read produce reviewable native TOML; emitter is read-only, does not deploy. Existing runtime-specific packs retained. |
| SIEM | [Dots security](https://learn.chatgpt.com/docs/enterprise/dots-security), existing Compliance and OTel coverage | Correlation and minimal content, not a new invented event schema. |

[Cloud environments](https://learn.chatgpt.com/docs/environments/cloud-environments) and [Apps and connectors](https://learn.chatgpt.com/docs/enterprise/apps-and-connectors) were fetched for new delegation and future-tool guidance. Read/write boundaries remain explicit. The public [OpenAI Trust Portal](https://trust.openai.com/) was reopened on 2026-11-12, with provenance from OpenAI’s security/privacy page. Its visible Documents list includes ISO SoA, Data Flow Diagram, System Cards, Pentest/Security Threat reports, Security Whitepaper, SOC3, VPAT, CSA STAR and FedRAMP20x. Public search for secure-configuration/deployment material did not reveal a new applicable customer Dots baseline. Restricted documents and the full authenticated catalog remain unreviewed; no completeness claim for gated contents or configuration inference from badges. Adjacent Gov/FedRAMP entries are not interchangeable with commercial Dots.

## Verification

Offline tests parse emitted TOML and reject invalid profile levels. They do not prove tenant policy delivery, Windows shell denial, cloud-runtime applicability, or audit completeness. See consolidated Pluto validation report for run results.
