# Pluto browser and n8n reconciliation — 2026-11-12

Documentation-derived changes, not live tenant validation. Full Pluto census is in the companion source inventory.

## Candidate disposition

| Pluto source / recommendation | Disposition |
|---|---|
| chrome-extension-supply-chain-attacks-permission-creep; browser-extension-security; chrome-extension-security: inventory, default deny, least permissions, sensitive origins, update/ownership review | Added Google Workspace 3.3 and Intune 3.3 with native Chrome/Edge ExtensionSettings and read-only paginated Chrome inventory. Defender browser inventory path/license/Windows limits documented. |
| Same sources: BlockExternalExtensions as broad host-permission control; ExtensionInstallSources as general sideload boundary; exact version pinning | Rejected inaccurate equivalences. Use blocked_permissions/runtime_blocked_hosts; allowed install sources are not a complete allowlist. Minimum version is a floor; update source control is not an invented version pin field. |
| n8n-security-issues: discover instances/workflows/owners, least privilege and governance/templates | New n8n 1.1,3.3; project role separation, ownership register, personal-space limits and audit. Existing published workflows/shares survive toggle restrictions. Preview workflow reviews explicitly not production guarantee. |
| n8n: credential manager, scoped service accounts, rotation, no embedded secrets | 2.1; credential storage and Enterprise project vault scope; runtime env access blocked. Actual rotation must occur at issuing service, not a guessed n8n rotation endpoint. |
| n8n: auth and isolation/firewall | 1.1,2.2,3.1; password MFA enforcement vs separate IdP MFA, dangerous/community node restrictions, external runner guidance, SSRF guard plus network controls and webhook audit. |
| n8n: logging, anomalies, patching | 3.2,3.3; payload minimization/pruning with operational warning, Enterprise event streaming, read-only n8n audit, Cloud Updates and self-hosted upgrade ownership. |
| n8n: incident/CVE claims | Not copied without authoritative advisory match. Product features provide the mitigation basis. |

## First-party sources inspected

- Google: https://support.google.com/chrome/a/answer/9867568 and https://support.google.com/chrome/a/answer/7532015; Chrome management Reports API countInstalledApps and index.
- Microsoft: https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/ExtensionSettings ; https://learn.microsoft.com/en-us/deployedge/microsoft-edge-manage-extensions-policies ; https://learn.microsoft.com/en-us/deployedge/configure-edge-with-intune ; https://learn.microsoft.com/en-us/defender-vulnerability-management/tvm-browser-extensions . Per-ID Edge policy inherits only installation mode/update URL, not wildcard permission/host restrictions.
- n8n: https://docs.n8n.io/llms.txt full index; security hub and child audit, SSRF, node exclusion, runner hardening, security policies pages; environment security/nodes/executions; project membership; external secret stores; enterprise log streaming; Cloud Updates. Exact links are beside controls.
- Placement: n8n GmbH → standalone n8n, https://n8n.io/legal/eula/ and current self-serve terms. Public ownership/change-control search found no evidenced transfer; no other n8n guide/platform exists in corpus.

## Trust Center and benchmark boundaries

n8n legal/support pages led to https://trust.n8n.io/ (SafeBase). Opened root and Documents category: public catalog lists SOC reports, pentest, CAIQ for cloud/self-hosted and policies. No customer hardening guide was identified in the rendered public catalog. Private reports require access/NDA and were not read; private content completeness remains unverified, not absent. Configuration evidence instead comes from public docs security subtree. Browser policies came from first-party Google/Microsoft configuration references, not vendor assurance claims.

Public targeted CIS/DISA/SCuBA coverage searches returned no product-specific n8n baseline. Separate NIST/NSA/ACSC product-specific catalog completeness remains unverified. This is bounded absence, not a comprehensive certification claim. Stable NIST objectives are contextual mappings only.

## Automation surface census and limits

| Surface | Browser scope | n8n scope |
|---|---|---|
| Native config | Documented Chrome/Edge ExtensionSettings JSON; pack | Documented native env settings; five packs covering identity, runtime secret exposure, node loading, SSRF and retention |
| CLI | Existing gws/Graph tooling catalog reviewed; no invented universal extension-policy CLI | Official installed `n8n audit`, read-only pack; actual configured deployment/database required |
| REST | Chrome countInstalledApps paginated read-only pack; Intune Graph setting IDs not fabricated | Public API index and audit/user references inspected. POST audit supported, user inventory owner-scoped; additional API wrappers not created merely to duplicate CLI audit. Identity policy writes and external-vault write contract unverified, no guessed endpoints |
| Terraform | No new policy provider assertion; existing vendor deployment controls unaffected | Official AWS Terraform module discovered in docs index; deployment infrastructure outside focused application-control scope, not claimed nonexistent. Its full resource/data-source coverage not audited |
| SDK/GraphQL | Not used; no new unsupported bindings claimed | Official SDK/GraphQL admin configuration coverage unverified; no invented pack |
| SIEM | Managed inventory and lifecycle review, no generic pretend SIEM rule | Enterprise event streaming documented, guide path; destination env configuration exists but not packaged without site-specific schema review. Guide does not claim click-only absence |

Six n8n controls each have an implemented native-config or CLI review path (3.3 audit also supports API); two distinct pack surfaces implemented. Pack application does not itself prove upstream credential scope, identity policy, webhook authorization, or Cloud enforcement. All affected production flows need an administrator-led functional test. No live credentials, environment changes, installs, or tenant actions were performed.

## Pluto source URLs

- https://pluto.security/blog/chrome-extension-security/
- https://pluto.security/blog/browser-extension-security/
- https://pluto.security/blog/chrome-extension-supply-chain-attacks-permission-creep/
- https://pluto.security/blog/n8n-security-issues/
