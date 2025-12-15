---
layout: default
title: About
---

<div class="about-page" markdown="1">

# About How to Harden

How to Harden is an open-source collection of security hardening guides for SaaS platforms. Our mission is to help organizations defend against supply chain attacks by providing actionable, vendor-specific security configurations.

## Why This Exists

Modern enterprises rely on dozens of SaaS applications—identity providers, DevOps platforms, data warehouses, and collaboration tools. Each of these integrations represents a potential entry point for attackers.

Recent breaches highlight the risk:
- **2024 Snowflake breach**: 165+ organizations compromised via credential stuffing against accounts without MFA
- **2023 CircleCI breach**: Secret rotation required for all customers after internal compromise
- **December 2024 BeyondTrust breach**: API key compromise led to US Treasury access

How to Harden provides the specific configuration guidance needed to prevent these attacks.

## Our Approach

Each guide follows a consistent structure:

1. **Authentication & Access Controls** - SSO, MFA, and RBAC configurations
2. **API & Integration Security** - Token management, OAuth hardening, webhook security
3. **Data Security** - Encryption, access controls, and data protection
4. **Monitoring & Detection** - Audit logging, SIEM integration, and detection queries

We prioritize:
- **Actionable guidance** - Step-by-step ClickOps and Code implementations
- **Real-world scenarios** - Attack patterns based on actual incidents
- **Compliance mapping** - NIST 800-53, SOC 2, ISO 27001 control references
- **Edition awareness** - Clear compatibility matrices for different product tiers

## Risk Tiers

Guides are organized by supply chain risk:

| Tier | Risk Level | Examples |
|------|------------|----------|
| **Tier 1** | Critical | Identity providers, secrets managers, EDR platforms |
| **Tier 2** | High | DevOps platforms, CRM systems, data platforms |
| **Tier 3** | Medium-High | HR systems, SIEM, container registries |
| **Tier 4** | Medium | Productivity tools, marketing platforms |
| **Tier 5** | Standard | Supporting tools, analytics platforms |

## Contributing

How to Harden is open source and welcomes contributions. You can:

- **Submit a guide** - Follow our template to add coverage for new platforms
- **Improve existing guides** - Add controls, fix errors, or update for new features
- **Report issues** - Found a problem? Open an issue on GitHub

Visit our [GitHub repository](https://github.com/grcengineering/how-to-harden) to get started.

## Philosophy

We believe security guidance should be:

- **Specific, not generic** - "Enable MFA" isn't enough; we show exactly how
- **Defensive, not compliance-driven** - Controls that actually prevent attacks
- **Accessible** - Free, open source, and community-maintained
- **Current** - Updated as platforms evolve and new threats emerge

## A GRC Engineering Project

How to Harden is a [GRC Engineering](https://grc.engineering) project. GRC Engineering represents a fundamental shift in how governance, risk, and compliance is done—one that fully embraces an engineering mindset.

</div>
