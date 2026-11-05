---
title: RelayMesh Hardening Guide (fictional fixture)
last_updated: "2026-10-01"
version: "0.1.0"
maturity: ["ai-drafted"]
---

This fixture covers RelayMesh console access, access policies and client posture. Generic host infrastructure is outside its scope.

### 1.1 Require MFA

Configure the external identity provider to require MFA for RelayMesh sign-ins. Existing authenticated devices require separate lifecycle review.

### 2.1 Limit service access

Use the central access-policy editor to grant approved identities only their required services. Retain positive and negative policy tests.

### 2.2 Require current client posture

For sensitive grants, require stable release track and built-in auto-updates. Review those two reported attributes in Devices → Device details → Attributes. A missing required attribute fails the grant's posture match.

## Changelog

| Date | Change |
|---|---|
| 2026-10-01 | Verified the three existing controls against current docs; no new feature since June. |
