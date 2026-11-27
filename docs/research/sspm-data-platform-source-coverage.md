# Salesforce, Oracle ERP, and SAP Ariba starter scope

Discovery snapshot: November 27, 2026. These are initial baselines for specific
customer control planes, not complete vendor control inventories. No customer
account, nonproduction tenant, vendor credential, or real evidence was used.

| Product | Verified candidate planes | Implemented evidence and excluded surfaces |
|---------|---------------------------|---------------------------------------------|
| Marketing Cloud Engagement | Salesforce Help Security Settings, Login IP Allowlist and rollout notice; Installed Packages; official REST scopes and first-party Security Events example | Audit events are documented REST reads; no setting write inferred. Audit result is page one, not a continuous collection or exhaustive inventory. Export allowlisting, Shield capabilities, and exact vendor release-stage-specific controls remain outside this starter guide; do not infer absence. |
| Agentforce | Salesforce Help Service Agent Access and shared responsibility; developer Agentforce DX + official command reference | GA first-party CLI can list test definitions. Authoring, preview/execution, publish, lifecycle and metadata surfaces exist; this pack invokes none of those. This does not cover all agent types, Data 360 setup, Action/MCP administration, or validate runtime behavior. |
| Oracle Fusion Cloud ERP and Financials | Securing ERP release 26C index, 26B Financials chapter, General Ledger Security and audit policy 26D, Financials REST and Fusion OAuth references | REST documents read, create and update operations for assignment data; only the single-object read is packaged. Explicitly exclude unsupported OCI/HCM/NetSuite administration substitutions. Location-based access, ERP role export/import, certificate/key lifecycle, broader procurement and project security remain outside this starter guide. |
| SAP Ariba | Intelligent Configuration Manager SAML, procurement User Management audit categories, SAP Ariba Applications SCIM API and Developer Portal OAuth | SCIM group reads and mutations are documented; only group detail is packaged. Pack targets the US Developer Portal runtime specified by its operator, not other Ariba offerings or the Next-Gen Invoicing administrative plane. Scope and entitlement require tenant validation. |

Public vendor security/trust searches and catalog documentation were used to
locate customer setup references. Assurance-only claims do not establish settings.
No exact benchmark was identified by the bounded [CIS public catalog search](https://www.cisecurity.org/cis-benchmarks);
this is not a claim that a benchmark does not exist. DISA/CISA SCuBA/NSA/ACSC
product-specific baselines and private trust-center artifacts remain unverified.
First-party tenant admin CLI coverage is recorded in the CLI inventory. Terraform,
additional SDK and SIEM-specific implementation handles remain unverified for
these controls; general provider integrations and customer log ingestion are
not proof of setting automation.

Validation: syntax and shell static analysis; offline command shims checked each
valid request or command and an invalid input causing no tool call. Auth endpoints,
permissions, exact tenant response schema, and actual console state remain
unverified without a live authorized tenant.
