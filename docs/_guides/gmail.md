---
layout: guide
title: "Gmail Hardening Guide"
vendor: "Gmail"
slug: "gmail"
platform: "Google Workspace"
platform_slug: "google-workspace"
product: "Gmail"
tier: "1"
category: "Productivity"
description: "Security hardening for Gmail within Google Workspace — coming soon. Gmail-specific controls (spoofing/SPF/DKIM/DMARC, attachment & link protection, routing) are not yet documented as standalone controls."
version: "0.0.1"
maturity: "draft"
last_updated: "2026-05-29"
---

## Overview

Gmail is the email surface of Google Workspace and the primary target for phishing and business email compromise. This product guide is a placeholder: **Gmail-specific hardening controls are not yet documented as standalone controls.** It exists so the Google Workspace platform card surfaces Gmail as a known product and so future Gmail controls have a home.

> **Status: Coming soon.** Until Gmail-specific controls are written, the platform-wide controls that already protect Gmail — authentication/MFA, OAuth app allowlisting, the DLP engine, and admin audit logging — live in the [Google Workspace platform guide](/guides/google-workspace/). No Gmail control content is fabricated here.

### Intended Audience
- Security engineers and IT administrators managing Gmail in Google Workspace
- GRC professionals tracking email-security coverage
- Contributors who want to author the Gmail control set (see Contributing)

### How to Use This Guide
- **L1 (Crawl):** Apply the platform-wide controls in the [Google Workspace guide](/guides/google-workspace/) — they cover Gmail authentication, OAuth, DLP, and audit logging today.
- **L2 (Walk):** Watch this guide for Gmail-specific controls (spoofing protection, SPF/DKIM/DMARC, attachment & link protection, routing & compliance) as they are added.
- **L3 (Run):** Pair forthcoming Gmail controls with the platform DLP engine and audit logging.

### Scope
This guide will cover Gmail-specific Admin Console hardening once authored: spoofing & authentication (SPF/DKIM/DMARC), safety settings (attachment, link, and external-sender protection), email routing & compliance, and Gmail-specific logging. Platform-wide authentication, OAuth allowlisting, the DLP engine, and audit logging are covered in the [Google Workspace guide](/guides/google-workspace/). Google Chat and Google Drive have their own product guides.

---

## Planned Controls

The following Gmail control areas are planned. They will be added as verified, documented controls — none are claimed as implemented yet:

- Email authentication: SPF, DKIM, and DMARC enforcement
- Spoofing and authentication safety settings
- Attachment protection (encrypted attachments, dangerous file types)
- Link and external-image protection
- Email routing, content compliance, and objectionable-content rules
- Gmail-specific log events and detection

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.0.1 | 2026-05-29 | Created Gmail product placeholder as part of the Google Workspace multi-product platform restructure. No controls documented yet — platform-wide controls remain in the Google Workspace guide. |

## Contributing

Want to author the Gmail control set? Open an issue or PR on [GitHub](https://github.com/grcengineering/how-to-harden). Follow the control structure used in the [Google Chat](/guides/google-chat/) and [Google Drive](/guides/google-drive/) product guides, and keep all code in Code Packs (no inline code blocks).
