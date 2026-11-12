# Pluto → Grok Bot reconciliation

Checked 2026-11-12 against HTH main `491e70a`. No tenant access or live execution; maturity remains AI-drafted. This is a bounded reconciliation of the two fetched articles below, not an assertion that every future Pluto article or vendor feature is covered.

## Sources and admission

- [Securing Grok Bot](https://pluto.security/blog/securing-grok-bot/) (2026-11-09): named authors Eitan Chassid and Yotam Perkal; Tier 3 research lead.
- [Inside Personal AI Assistants](https://pluto.security/blog/personal-ai-assistant-security/) (2026-10-20): same named authors; architecture/research lead, not proof of current unpatched vulnerabilities.
- Current first-party bodies fetched through web retrieval: [teams](https://docs.x.ai/grok-bot/teams-and-enterprises), [security](https://docs.x.ai/grok-bot/security), [FAQ](https://docs.x.ai/grok-bot/security-faq), [approvals](https://docs.x.ai/grok-bot/approvals-security-and-privacy), [computer lifecycle](https://docs.x.ai/grok-bot/computer-and-apps), [Bot management](https://docs.x.ai/grok-bot/bots), [Admin API](https://cursor.com/docs/account/teams/admin-api), [Grok Build CLI](https://docs.x.ai/build/cli/reference).
- Cursor attribution is supported by the current first-party Bot architecture and administration pages, not inferred from Pluto's branding. Grok Build CLI and Grok Bot remain distinct surfaces.
- The existing source-first SpaceXSI ledger records Trust Center discovery. This narrow reconciliation does not claim new access to gated assurance documents. Pluto does not establish customer control of the vendor's package supply chain or model runtime.

## Complete recommendation disposition

| Pluto area | HTH disposition | Result of current-source check |
|---|---|---|
| Enterprise entitlement | Overview and Appendix A | Preserve plan distinctions; self-serve Teams is not Enterprise |
| Shared per-user computer | Overview, 2.5, new 7.4 | Covered; separate Bots are not isolation |
| Destination restrictions | 3.1 API pack | Covered; functional service destinations remain exceptions |
| Remove root | 3.5 | Covered, including restart requirement |
| Setup secrets | 3.3 API inventory pack | Covered; no invented secret-writing endpoint |
| Update hosted runtime | New 7.4 | Gap closed; distinguish software refresh from computer replacement |
| Post-task browser/file cleanup | 7.1 and new 7.4 | Clarify role retirement versus destructive offboarding |
| Local team ceiling | 2.4 API + Sigma | Covered; not a cloud-runtime switch |
| Per-device member restriction | 2.4, 8.7 | Covered; approval of exact operation emphasized in 4.1 |
| Desktop session protection | 1.2, 7.1 | Covered; uninstall is not credential revocation |
| Enforced approval rules | 4.1 API + Sigma | Covered; current Slack requester-card behavior corrected |
| Required Team Rules | 4.2 API + Sigma | Covered; instruction versus enforcement distinction retained |
| Personal narrow rules | 8.7 | Updated current Custom Rules labels; sync assumptions removed |
| Review exceptions | 4.3 API + Sigma | Covered; team-only API cannot prove group compliance |
| Minimize role inputs | New 7.4 | Added source-of-record and role boundary procedure |
| Personal description | New 7.4 | Reject stale Pluto UI advice; current personal Bots use chat instructions |
| Retire persistent work | 7.1, 5.3, new 7.4 | Added hide/duplicate/routine distinction |
| Fresh learned context | New 7.4 | Duplicate is not credential isolation or deletion proof |
| Disable delegation | 2.3 API | Covered; receiving Cloud Agent controls still apply |
| Approved MCP/connectors | 2.1, 3.4; Cursor 4.1 | Covered; account-wide grant and backend network plane distinct |
| Provider least privilege/revocation | 2.1, 7.1 | Covered; no task-local grant isolation inferred |
| Action records versus audit | 6.1 and 6.2 packs | Covered; configuration events do not prove executed-task visibility |
| Content export sensitivity | 6.1 | Covered; telemetry is not guaranteed secret-free |
| Prove telemetry coverage | 6.1 validation | Covered; actual task-to-event correlation required |
| Hosted package risk (architecture article) | 3.1, 3.3, 3.5, new 7.4 | Runtime evidence/update checks; do not convert historical CVE matches into present compromise claims |
| Desktop endpoint override (architecture article) | 1.2 and 8.2, deployment review | Research finding is version-scoped; no undocumented production policy key invented |
| Approval/artifact binding | 4.1 validation | Added operator check; no native hash-binding guarantee asserted |
| Memory provenance/partition | 5.2 and new 7.4 | Data minimization and replacement procedure; no unsupported memory editor |
| Delegated authority and initiating audience | 2.3, 2.4, 5.2, 5.3 | Existing source-channel and shared-credential limits retained |

## Automation surface census

Baseline: 27 leveled controls, 17 includes; 16 API scripts, one Terraform pack, 13 Sigma files, plus common API helper. New 7.4 is a member workflow and deliberately adds no fake executable surface.

| Surface | Discovery / read-write decision |
|---|---|
| Terraform | Existing pack only covers external IdP policy. Cursor provider docs refetch was blocked; no verified new Grok Bot update/duplicate resource or data source. No Terraform change |
| API | Admin API fetched: existing policy reads/writes and Organization computer operations. No setting-specific update/duplicate/individual-memory route established. Existing 4.1 executable unchanged; misleading Slack warning corrected |
| CLI | Inventory row 123 and current Grok Build command reference: adjacent coding CLI, not Bot administration. No CLI pack |
| SDK | No Bot administration SDK established by fetched Bot/API references. Do not reuse inference SDK as admin API |
| Config | Team Setup is documented and already covered by 3.3. No new native update/memory-retirement config established |
| SIEM | Action Recording/export documented in current teams page; existing Sigma coverage retained. No invented update/duplicate event names |

Not finding an automation surface in these references is not proof that none can exist. No new handle is shipped. Existing Admin API handles retained as documented, with plan applicability and group visibility limitations preserved.

## Validation

- Baseline `bash scripts/validate-packs.sh grok-bot` unexpectedly checks the full corpus: five existing failure groups, six warnings; not a vendor-only clean result.
- Changed shell syntax checked with `bash -n`; no operation against any tenant.
- Guide has no fenced code; new control keeps Description/Rationale/Profile/ClickOps/Validation anatomy, no renumbering.
- `bun test ./scripts/test-spacexai-refresh-packs.ts`: 17 passed, 0 failed, 220 assertions (synthetic fixtures only).
- Parent integration owns generated pack YAML sync, full lint and final integration test execution.
