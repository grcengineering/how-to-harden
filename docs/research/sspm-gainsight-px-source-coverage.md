# Gainsight PX source coverage

Reviewed 2026-11-27. Palo Alto's [onboarding source](https://docs.paloaltonetworks.com/saas-security/sspm/onboard-saas-apps-supported-by-sspm/onboard-a-gainsight-app-to-sspm) identifies the intended scope as Gainsight PX, which has its own admin plane separate from Gainsight CS. Its onboarding procedure is not an HTH hardening recommendation.

| Candidate | Source | Disposition |
|-----------|--------|-------------|
| SAML only and local exceptions | [SAML setup](https://support.gainsight.com/PX/Administration/Security/Configure_SAML_Authentication) | Covered under native sign-in settings and IdP-enforced MFA. |
| Subscription / product roles and production launch | [User management](https://support.gainsight.com/docs/user-management) | Covered in role inventory, staged release authorization and admin export. No verified API for subscription administrators. |
| Sensitive tracking data | [Tracking filters](https://support.gainsight.com/v1/docs/security-tracking-filters) | Covered in UI and SDK configuration. Offline fragment does not activate the SDK. |
| Opt-out | [User preference API](https://support.gainsight.com/PX/Security_and_Compliance/Enablement/User_Preferences_for_Tracking_and_Engagement) and [vendor region list](https://support.gainsight.com/v1/docs/gainsight-px-connector) | US read-only GET for one synthetic ID. Key scope is not read-only, and the example HTTP URL in the old method doc is not used. Explicitly do not generalize to other product, region or event types. |
| CSP compatibility | [Vendor strict CSP path](https://support.gainsight.com/v1/docs/using-px-with-content-security-policy-csp) | Cross-reference only. Customer host deployment and per-product asset requirements are not tenant settings. |

Automation: native SDK config for exclusion, REST GET for individual tracking preferences and documented console export for operator roles. Terraform, CLI, admin SDK and audit-to-SIEM handles unverified in the reviewed material. No product-specific CIS/DISA/SCuBA baseline found in reviewed references; no assertion of exhaustive absence. No live tenant tested.
