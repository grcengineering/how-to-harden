# Adobe organization and product boundaries

Discovery snapshot: November 27, 2026. The attachment's undifferentiated
“Adobe” row is covered as the Adobe enterprise Admin Console management
plane, not counted again as a separate product. The console governs shared
identities, roles and product entitlements. Adobe Workfront, Creative Cloud,
Acrobat Sign and Commerce have separate implementation paths and scopes.
No live console or tenant validation was performed.

| Guide | Verified candidate planes | Pack boundary and follow-up |
|-------|---------------------------|-----------------------------|
| Adobe Admin Console | Authentication settings, identity types, delegated access, and separate Admin APIs; official UMAPI group catalog | Bounded groups/profiles read through OAuth Server-to-Server. No inference about complete directory membership, MFA enforcement or product-native access. Adobe I/O has a separate Admin Console audit stream. |
| Creative Cloud | Asset Settings (which can affect Document Cloud), managed packages, access to Content Logs, and Developer Console journal registration | One read from the approved existing Content Logs journal emits only the envelope count; no event payload or continuous operation claim. Enterprise storage entitlement and effective policy still require verification. |
| Acrobat Sign | Sign account/group hierarchy, approved signer identity methods, completed agreement content protection, audit report and commercial API v6 | Exact commercial agreement GET returns only ID and status; not an audit trail export, recipient challenge trace, or settings read. Government, embedded and partner variants need separate validation. |
| Adobe Commerce | Application Admin native 2FA versus Adobe IMS, Cloud Infrastructure project roles/SSH MFA, and SaaS/PaaS integration auth | First-party Cloud CLI inventory is PaaS-only. SaaS API system configuration is documented but the read/write behavior for these exact admin controls was not established. No risk-scanning or infrastructure changes attempted. |

Official customer configuration and developer references are linked from the
guides. Adobe Security/Trust assurance references were not relied on to
establish customer setting behavior. No exact CIS benchmark surfaced in the
bounded [public catalog](https://www.cisecurity.org/cis-benchmarks) review.
Product-specific DISA, SCuBA, NSA, ACSC, Terraform and narrow SIEM coverage
are unverified here. The CLI inventory distinguishes admin and endpoint tools.

Verification is offline: shell syntax and static checks, generated YAML, and
synthetic command/response fixtures. Licensed administrative entitlements,
tenant console paths and actual API responses require authorized validation.
