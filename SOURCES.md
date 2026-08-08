# Authoritative Sources for HTH Content

The standard for what counts as a legitimate source when deriving How to Harden guide content, and how each tier may be used. Every control, rationale claim, and hardening link in this repo traces to a source admitted under this taxonomy.

**The bright line:** a vendor's Trust Center, company "Security" marketing page, compliance-badge page, or "we take security seriously" whitepaper about the vendor's OWN infrastructure is **never** a hardening source. The test for any page: *does it give an administrator configuration steps, settings, or auditable requirements for hardening the product?* If it describes the vendor's certifications or internal practices instead, it fails.

**Tier semantics:** each tier is marked by what it may do — **ORIGINATE** a control (be the reason a control exists and the source of its steps), **SET VALUES** (determine the recommended setting), or **CORROBORATE** (supply rationale, incidents, and attack context).

---

## Tier 1 — First-Party Vendor Configuration Documentation

*May: ORIGINATE controls · authoritative on FACTS (whether a setting exists, its name, its default, its console path)*

**What qualifies:** the vendor's own admin guides, security-configuration docs, hardening guides, API/CLI references, and security-relevant release notes — on the official vendor docs domain.

**Role:** the mandatory source class. Every control must trace to at least one Tier 1 citation proving the setting exists as described; every ClickOps step and console path is transcribed from Tier 1.

**Built-in conflict of interest:** vendor docs prove what EXISTS, but vendor-recommended values favor adoption and compatibility. On strictness questions, Tier 1 does not outrank Tier 2 (see Conflict Resolution).

**Representative examples** (what a Tier 1 hardening doc looks like in the wild — the vendor's own docs domain, admin-configuration content):

| Vendor | Domain | Example hardening guide |
|--------|--------|-------------------------|
| GitHub | docs.github.com | [Security hardening for GitHub Actions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions) |
| HashiCorp Vault | developer.hashicorp.com | [Production Hardening](https://developer.hashicorp.com/vault/docs/concepts/production-hardening) |
| Google Workspace | knowledge.workspace.google.com | [Security checklist for medium/large businesses](https://knowledge.workspace.google.com/admin/security/security-checklist-for-medium-and-large-businesses-100-users) |
| Zscaler | help.zscaler.com | [ZIA Policy Leading Practices Guide](https://help.zscaler.com/zscaler-deployments-operations/zia-policy-leading-practices-guide) |
| Snowflake | docs.snowflake.com | [Authentication policies](https://docs.snowflake.com/en/user-guide/authentication-policies) |
| Ona | ona.com | [Guardrails overview](https://ona.com/docs/ona/guardrails/overview.md) |

**Never qualifies:** `trust.vendor.com`, `vendor.com/security` marketing pages, SOC 2 attestation pages, whitepapers about the vendor's own datacenters.

## Tier 2 — Configuration-Prescriptive Benchmark Bodies

*May: ORIGINATE controls · authoritative on VALUES (what to set)*

**Standing list:**

| Source name | Source domain | Example hardening guide | Use for |
|-------------|---------------|-------------------------|---------|
| CIS Benchmarks | cisecurity.org | [CIS Microsoft 365 Foundations Benchmark](https://www.cisecurity.org/benchmark/microsoft_365) | Per-product numbered baselines. Numbering shifts between major versions — verify IDs against the current release or map by control name with a version note |
| DISA STIGs | public.cyber.mil/stigs | *STIG Downloads library (e.g. "Microsoft Windows STIG", "Kubernetes STIG") at public.cyber.mil/stigs/downloads* | The strictest per-product baselines; L3 targets and compliance tables |
| CISA SCuBA | github.com/cisagov | [ScubaGear (M365/Entra baselines)](https://github.com/cisagov/ScubaGear) · [ScubaGoggles (Google Workspace)](https://github.com/cisagov/ScubaGoggles) | Machine-checkable policy IDs (GWS._, MS._), preferred for compliance tables; also Binding Operational Directives and the KEV catalog |
| NSA CSI | nsa.gov / media.defense.gov | *NSA Cybersecurity Information Sheets (e.g. cloud/Kubernetes hardening guidance), often joint with CISA* | Product-specific, configuration-prescriptive government guidance |
| ACSC | cyber.gov.au | *Essential Eight Maturity Model and per-product hardening guides* | Only where it publishes explicit control values; otherwise Tier 2b |

**Role:** set the recommended values, seed compliance mappings, and legitimately originate controls the vendor under-documents.

> Rows whose example is in *italics* are described, not a session-verified URL — the authoring agent must fetch-verify a current URL from that domain (Verification Rule 1) before citing.

## Tier 2b — Framework and Advisory Bodies

*May: CORROBORATE and supply compliance mappings · may NOT originate a configuration step*

**Standing list:**

| Source name | Source domain | Example framework/guide | Use for |
|-------------|---------------|-------------------------|---------|
| NIST | csrc.nist.gov | *SP 800-53 Rev 5, SP 800-63, CSF 2.0, AI RMF* | Control-family mappings and rationale |
| CSA | cloudsecurityalliance.org | *Cloud Controls Matrix (CCM), SaaS/AI governance guidance* | Cloud/SaaS control mapping |
| ENISA | enisa.europa.eu | *EU threat-landscape and cloud-security guidance* | Rationale, EU context |
| BSI | bsi.bund.de | *IT-Grundschutz modules* | Control catalog (DE) |
| SANS | sans.org | *Technical whitepapers/posters where they carry concrete config steps* | Rationale; occasional concrete steps |
| OWASP | owasp.org | [OWASP Top 10 for LLM Applications](https://owasp.org/www-project-top-10-for-large-language-model-applications/) · *ASVS* | Application-layer security (in lane); out of lane for SaaS tenant-admin toggles |

**Role:** control-family catalogs and abstractions by design; they justify and map controls but always need a Tier 1/2 source to instantiate an actual setting. Italic examples are described, not session-verified URLs — fetch-verify before citing.

## Tier 3 — Expert Security-Vendor Research

*May: CORROBORATE always · ORIGINATE only where no Tier 2 baseline covers the surface, and only after Tier 1 cross-verification*

**Admission criteria (all three):** (1) demonstrated ORIGINAL product-specific research — a novel misconfiguration, attack chain, or detection they built; not vendor size, not content marketing; (2) named authors; (3) technical reproducibility — claims reference actual admin-console settings or API endpoints.

**Standing list (extend via the criteria, not vibes):**

| Source name | Source domain | Example hardening guide / research |
|-------------|---------------|-----------------------------------|
| Wiz | wiz.io | [Wiz vulnerability database](https://www.wiz.io/vulnerability-database) · *cloud misconfiguration research at wiz.io/blog* |
| Datadog Security Labs | securitylabs.datadoghq.com | *cloud/SaaS attack research and detection engineering* |
| Mandiant / Google Threat Intelligence | cloud.google.com/blog/topics/threat-intelligence | [UNC6040 voice-phishing / Salesforce data-extortion](https://cloud.google.com/blog/topics/threat-intelligence/voice-phishing-data-extortion) |
| Trail of Bits | blog.trailofbits.com | [Mitigating ELUSIVE COMET Zoom remote-control attacks](https://blog.trailofbits.com/2025/04/17/mitigating-elusive-comet-zoom-remote-control-attacks/) |
| Legit Security | legitsecurity.com/blog | [Remote prompt injection in GitLab Duo](https://www.legitsecurity.com/blog/remote-prompt-injection-in-gitlab-duo) |
| Snyk Security Labs | labs.snyk.io | [Gitpod RCE via WebSockets](https://labs.snyk.io/resources/gitpod-remote-code-execution-vulnerability-websockets/) |
| PromptArmor | promptarmor.com | [Data exfiltration from Slack AI via indirect prompt injection](https://www.promptarmor.com/resources/data-exfiltration-from-slack-ai-via-indirect-prompt-injection) |
| Cyata | cyata.ai | [Cracking the Vault — HashiCorp Vault zero-days](https://cyata.ai/blog/cracking-the-vault-how-we-found-zero-day-flaws-in-authentication-identity-and-authorization-in-hashicorp-vault/) |
| Pluto Security | pluto.security | [Securing Claude Tag: A Practical Hardening Guide](https://pluto.security/blog/securing-claude-tag-a-practical-hardening-guide/) |
| Harmonic Security | harmonic.security | *product-specific AI-tool hardening guides (e.g. Claude) at harmonic.security/blog* |
| Pillar Security | pillar.security | *AI application/agent security research at pillar.security/blog* |
| StepSecurity | stepsecurity.io | *GitHub Actions / CI-CD hardening research at stepsecurity.io/blog* |
| Obsidian Security | obsidiansecurity.com | *SaaS identity/integration attack research* |
| Push Security | pushsecurity.com | *identity-attack and SaaS security research* |
| Unit 42 (Palo Alto) | unit42.paloaltonetworks.com | *threat research and mitigations* |
| Rapid7 Research | rapid7.com/blog | *vulnerability and product-security research* |
| Praetorian | praetorian.com/blog | *offensive-security research with concrete config guidance* |
| AppOmni | appomni.com | *SaaS security posture research* |
| GitGuardian | blog.gitguardian.com | *secrets/CI-CD security research* |
| Mitiga | mitiga.io | *cloud/SaaS incident and detection research* |
| Varonis Threat Labs | varonis.com/blog | *SaaS/data-exfiltration research* |

Italic examples are described, not session-verified URLs — fetch-verify a current URL before citing.

**Where Tier 3 leads:** for new attack surfaces with no CIS/STIG/SCuBA coverage yet (AI SaaS: Claude, ChatGPT Enterprise, Copilot-class products), Tier 3 is often the only source with real content — it may originate controls there, flagged **"no benchmark equivalent yet"**, and every step still cross-verified against the vendor's real admin UI/API (Tier 1) before shipping. A Tier 3 claim alone never ships unverified.

## Tier 4 — Established Independent Researchers

*May: CORROBORATE and enrich · originate only with explicit Tier 1 verification*

**Admission criteria:** named researcher with verifiable identity and track record (CVE credits, vendor-acknowledged disclosures, recognized conference talks — Black Hat, DEF CON, BSides, fwd:cloudsec); technical specificity (exact settings, reproducible steps); published on an accountable venue. This is a *class*, not a fixed allowlist — admit per the criteria. Representative example:

| Source name | Source domain | Example research |
|-------------|---------------|------------------|
| Dirk-jan Mollema | dirkjanm.io | [Obtaining Global Admin in every Entra ID tenant with Actor tokens (CVE-2025-55241)](https://dirkjanm.io/obtaining-global-admin-in-every-entra-id-tenant-with-actor-tokens/) |

**Never:** anonymous blogs, aggregator/SEO content, citation-of-a-citation — always resolve to the primary source.

---

## Verification Rules (all tiers)

1. **Fetch or it didn't happen.** Every cited URL must be fetched successfully in the working session. Hosts that block fetchers (403s, JS-only shells) get a real-browser check before citation. Unverifiable URL = not a source. Beware SPAs that return HTTP 200 for nonexistent pages (LastPass-style): confirm real content rendered, not a shell.
2. **Currency.** Cite the canonical/current URL, not one that 301-redirects (redirects rot; vendors migrate doc hosts — e.g., Google's support.google.com/a → knowledge.workspace.google.com).
3. **Capability claims need Tier 1.** "The vendor now supports X" must be shown in vendor docs, not inferred from a Tier 3 post; if a Tier 3 finding contradicts Tier 1, re-fetch Tier 1 — the docs may have changed.
4. **Cite specifically.** Tier 2 citations carry benchmark name + version + recommendation ID; re-verify on each benchmark release.

## Conflict Resolution

**Do not average. Tier 1 wins on FACTS; Tier 2 wins on VALUES.**

- **Strictness conflicts** (e.g., Google recommends SPF `~all`; CISA SCuBA requires `-all`): the strictest defensible position from a prescriptive source is the documented recommendation; the more permissive vendor position is retained as an explicitly labeled compatibility note with the risk delta explained — never suppressed, never silently averaged.
- **Value precedence when tiers disagree:** Tier 2 (conflict-of-interest-free) > Tier 1 vendor recommendation > Tier 3 > Tier 4.
- **Fact disputes** (does the setting exist, what is it called, what is the default): Tier 1's current docs always win.
- **Stale guide vs current source:** the current verified source wins; correct the guide in place (update-hth-guide skill).

## Maintenance

Tiers 1-2/2b are standing allowlists that rarely change. Tiers 3-4 are standing lists plus per-citation review against the admission criteria; prune quarterly for dead links, acquisitions, and quality drift.

## Changelog

| Date | Changes |
|------|---------|
| 2026-08-08 | Converted the Tier 1 (examples), Tier 2, Tier 2b, Tier 3, and Tier 4 source lists into tables carrying Source Name + Source Domain + Example Hardening Guide, so authoring agents search by domain and know what a real hardening guide from each source looks like (verified URLs where available this session; italic = describe-then-fetch-verify). Added **Pluto Security** (pluto.security) to the Tier 3 standing list with its verified Claude Tag hardening guide as the example. |
| 2026-08-08 | Council-refined revision: Tier 2/2b split (prescriptive bodies vs framework catalogs), originate/values/corroborate semantics per tier, facts-vs-values conflict rule with strictest-defensible precedence, Tier 3 elevation for un-benchmarked surfaces with mandatory Tier 1 cross-verification, maintenance cadence. Two council seats (formal semantics, provenance rigor) were synthesized conservatively — revisit if those areas prove contentious. |
| 2026-08-08 | Initial version — taxonomy formalized from the August 2026 full-repo audit (A–Z link audit, currency waves, trust-center purge). |
