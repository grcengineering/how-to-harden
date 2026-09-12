# Security Policy

How to Harden publishes security hardening guidance and copy-paste **Code Packs**.
Two different things can be "a vulnerability" here, and they are reported the same way:

1. **A defect in this repository's own software supply chain** — CI workflows,
   validation scripts, the published Jekyll site, or its dependencies.
2. **Unsafe guidance in a guide or Code Pack** — a control that is wrong,
   a snippet that weakens the system it claims to harden, or an installation
   step that executes unverified code. Guidance that would damage a reader's
   environment is treated as a vulnerability, not a documentation bug.

## Reporting a vulnerability

**Report privately. Do not open a public issue for a security problem.**

Use GitHub's private vulnerability reporting on this repository:
[**Report a vulnerability**](https://github.com/grcengineering/how-to-harden/security/advisories/new).

Please include:

- which guide, Code Pack file, workflow, or script is affected (path and line);
- what an attacker gains, concretely;
- the steps or snippet that demonstrate it;
- the version, commit SHA, or page URL you looked at.

## What to expect

| Stage | Target |
|-------|--------|
| Acknowledgement of your report | 3 business days |
| Initial assessment and severity | 10 business days |
| Fix or documented decision | 90 days from acknowledgement |

If a report is accepted, the fix ships with a GitHub Security Advisory and you
are credited unless you ask otherwise. If it is declined, you get the reasoning,
not silence.

Please give us the 90-day window before public disclosure. If a flaw is already
being exploited in the wild, say so in the report — that changes the timeline.

## Scope

**In scope**

- `packs/**` — Code Packs readers are expected to apply to real systems
- `docs/_guides/**` — published hardening guidance
- `.github/workflows/**`, `scripts/**`, `Makefile` — this repository's own build
  and validation supply chain
- the published site at [howtoharden.com](https://howtoharden.com)

**Out of scope**

- Vulnerabilities in the vendor products the guides describe. Report those to the
  vendor under their own disclosure policy; tell us if a guide should change because
  of one.
- Findings from an automated scanner with no demonstrated impact, including
  infrastructure-as-code checks that flag a Code Pack for not configuring a control
  that a different, sibling Code Pack exists to configure. Code Packs are
  deliberately single-control fragments; see `AGENTS.md`.
- Missing hardening you would merely prefer. Open a normal issue or pull request —
  those are very welcome.

## Supported versions

This project publishes continuously from `main`; there are no maintained release
branches. Fixes land on `main` and the site rebuilds from it. Always compare
against `main` before reporting.

## This repository's own supply-chain controls

The posture is enforced in CI, not asserted here. It is bootstrapped and
verified with [sscs-bootstrapper](https://github.com/p4gs/sscs-bootstrapper):
configuration in `.sscsb/config.toml`, machine-readable posture in
`security-insights.yml`, and the control-to-framework mapping from `sscsb report`.

Highlights:

- **Secret scanning** — TruffleHog at pre-commit, pre-push, and in CI. Findings are
  provider-verified, so an alert means a live credential.
- **SAST** — CodeQL and OpenGrep on every pull request.
- **Vulnerability scanning** — Trivy and OSV-Scanner, plus a weekly schedule.
- **Signed commits** — protected-branch pushes must be signed by an approved human
  signer in `.sscsb/policy/signers.toml`.
- **Pinned actions** — every GitHub Action is pinned to a full commit SHA, and
  `step-security/harden-runner` monitors egress and tampering in every job.
- **Provenance** — SBOM generation, Sigstore signing, and SLSA Build L3 provenance
  on releases.
