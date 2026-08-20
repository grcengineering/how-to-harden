# HTH Guide Versions

This document provides a central registry of all How to Harden (HTH) guides with their current version and maturity status.

## Versioning Model

HTH uses **Extended SemVer with Maturity Qualifier**, aligned with [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks) versioning practices:

```
v{MAJOR}.{MINOR}.{PATCH}-{maturity}
```

### Semantic Version Components

| Component | Signals | Triggers |
|-----------|---------|----------|
| **MAJOR** | Scope expansion or coverage milestone | Net-new product added, major feature area expansion, structural overhaul, first `ni-validated` release |
| **MINOR** | Incremental improvements within scope | New controls, new sections, compliance mappings added |
| **PATCH** | Editorial/maintenance changes | Typos, URL fixes, vendor UI path changes, clarifications |

#### MAJOR Version Triggers (Detailed)

| Trigger | Example |
|---------|---------|
| Net-new product added | Okta WIC guide → Okta WIC + CIC guide |
| Major feature area expansion | SSO hardening → SSO + SCIM + API security |
| First `ni-validated` release | v0.x.x-ai-drafted → v1.0.0-ni-validated milestone |
| Structural overhaul | Complete rewrite with new control taxonomy |

#### What About Breaking Changes?

Removals, reversals, and other disruptive changes use **changelog tags** rather than forcing MAJOR bumps:

| Change Type | Version Bump | Changelog Tag |
|-------------|--------------|---------------|
| Single control removed | MINOR | `[BREAKING]` |
| Recommendation reversed | MINOR | `[BREAKING]` |
| Critical security addition | MINOR | `[SECURITY]` |
| Entire section removed | MAJOR | `[BREAKING]` |
| Product dropped from scope | MAJOR | `[BREAKING]` |

This approach keeps version numbers meaningful for **scope/completeness** while clearly signaling disruptive or urgent changes.

### Changelog Tags

Use these tags in changelog entries to signal special circumstances:

| Tag | Meaning | When to Use |
|-----|---------|-------------|
| `[SECURITY]` | Addresses active/prevalent threat | New control for emerging attack vector, critical gap filled |
| `[BREAKING]` | May disrupt existing implementations | Control removed, recommendation reversed, API changed |

Example changelog entries:
```
| 2025-12-27 | 0.3.0 | ai-drafted | [SECURITY] Add L1: Phishing-resistant MFA | @contributor |
| 2025-12-28 | 0.4.0 | ai-drafted | [BREAKING] Remove deprecated SSO control | @contributor |
| 2026-08-19 | 0.4.0 | ai-drafted · ai-validated | Added ai-validated: validate-hth-guide run against a live tenant, FAIL=0, 11 controls VERIFIED-LIVE | Claude Code (Opus 5) |
```

The `Maturity` column carries the guide's **whole status set as of that row**, ` · `-joined in canonical order — not just the status the row added. Statuses accumulate, so a promotion row shows the set widening (`ai-drafted` → `ai-drafted · ai-validated`) rather than one value replacing another; a row that shows a *narrower* set than the row beneath it is recording a demotion, and should say why.

### Maturity Statuses — the Matrix

**This section is the single definition of the maturity vocabulary.** README.md, CONTRIBUTING.md, `docs/contributing.md`, `templates/vendor-guide-template.md`, the authoring skills in `.claude/skills/`, `docs/_includes/status-set.html`, `docs/_includes/status-badge.html`, `docs/_layouts/guide.html`, `docs/index.html`, and `scripts/validate-guides.sh` all point here instead of carrying their own copy. If a status's meaning changes, it changes here first and the rest follow.

Maturity is **not a ladder — it is a matrix**, because two different things were being collapsed into one number. Two independent axes:

- **STAGE — how far the work got.** `drafted` → `reviewed` → `validated`. This axis *is* ordered: nothing can be reviewed or validated before it exists, and validating means the guidance was taken to a real system rather than merely read.
- **AGENT — who did it.** `ai` (artificial intelligence — a machine) or `ni` (natural intelligence — a person). This axis is **not** ordered and has no top. Neither value implies the other, and neither can be inferred from the other.

Crossing them gives six statuses:

|  | **drafted** | **reviewed** | **validated** |
|--|-------------|--------------|---------------|
| **`ai`** — a machine did it | `ai-drafted` | `ai-reviewed` | `ai-validated` |
| **`ni`** — a person did it | `ni-drafted` | `ni-reviewed` | `ni-validated` |

**The six are not mutually exclusive.** A guide holds a *set*, not a position on a line, so `maturity` in frontmatter is a list:

```yaml
maturity: ["ai-drafted", "ai-validated"]
```

A guide can be `ai-drafted` and `ni-drafted` at once. Holding both `ai-validated` and `ni-validated` is strictly better than holding either alone. The rendering follows the model rather than flattening it: `docs/_layouts/guide.html` paints one chip per status, and the home-page filter matches by **membership**, so filtering for AI Validated surfaces every guide that holds it regardless of what else it holds.

| Status | What it asserts | What it does **NOT** assert | Who may set it |
|--------|-----------------|-----------------------------|----------------|
| `ai-drafted` | An AI agent wrote the guide from vendor documentation, and it is structurally complete. | That anything touched the product. Every console path and every line of pack code is a claim transcribed from a document. Also asserts nothing about a person having written or read any of it. | A [`create-hth-guide`](.claude/skills/create-hth-guide/SKILL.md) run. Every AI-authored guide starts here and every guide currently in the corpus holds it. |
| `ni-drafted` | A person wrote the guide, or wrote enough of it to own the content. | That anyone else has read it, and that it has been applied anywhere. Human authorship is not human review — the author cannot be their own reviewer. | The contributing author, in the PR that lands the content. |
| `ai-reviewed` | An AI agent read every control against the current vendor documentation and vouched for the transcription: the setting exists, the path is spelled the way the vendor spells it, the mapping cites a real control ID. | **Human judgement of any kind.** A machine can check a guide against documents; it cannot decide whether a control is the *right* control, correctly scoped, or safe for a given organization. | An agent review run, recorded in the changelog. Never hand-typed. |
| `ni-reviewed` | A human practitioner with platform experience read every control and vouched for its accuracy and appropriateness. | That the controls were applied to a running system — reviewing is judgement, not contact. | Maintainers, after a named review. |
| `ai-validated` | **An AI agent exercised this guidance against a real tenant or console and the guidance survived that contact.** Console paths were re-read off the live UI, read-only Code Packs were executed against a live tenant, and the run closed with `FAIL = 0` and at least one `VERIFIED-LIVE` result. | **That a human practitioner has reviewed it.** Machine validation proves the steps are findable and the code runs — never that a control is the right control. | Only a [`validate-hth-guide`](.claude/skills/validate-hth-guide/SKILL.md) run, as its Phase 6 close-out. Never hand-typed. |
| `ni-validated` | A person applied and tested the controls on a real system and reported the result. | — (furthest cell on its row). | Maintainers, after a named test. |

**An `ai-*` status is a claim about a machine's act, and asserts nothing about human judgement.** That is the whole reason the agent axis exists as an axis instead of a rung. An agent can prove a console path is where the guide says it is; it cannot decide whether the control belongs in your environment. So **an AI status never discharges the need for its NI twin**: a guide can sit at `ai-validated` indefinitely and still be a guide waiting for its human reviewer. Anything that reads `ai-validated` as "good enough, review skipped" is reading it wrong. The reverse holds too — `ni-reviewed` says nothing about whether any pack in the guide actually runs.

**Both agents at the same stage is the strongest thing this vocabulary can express.** `ai-validated` + `ni-validated` means the guidance survived contact with a real system twice, once under machine rigour and once under human judgement, and the two failure modes those catch barely overlap. There is no seventh status above it; combining is how the matrix expresses "better".

**Where the corpus actually stands: no guide holds any `ni-*` status.** All 130 guides are `ai-drafted`; two of them (Buildkite, Ona) additionally hold `ai-validated`. The entire NI row is empty. Read it as a standing invitation to reviewers and practitioners rather than as a description of anything already done — every `ni-*` cell in this document describes a status that exists in the vocabulary and has never yet been earned.

#### The version qualifier

The qualifier appended to a guide's version names the **furthest stage reached**, prefixed by the agent unless **both** agents reached it, in which case the bare stage is used. `docs/_includes/status-set.html` implements this and hands the same three values to the guide banner and the home page, so the string is derived from the set rather than typed alongside it.

1. Take the furthest STAGE any status in the set reached (`validated` beats `reviewed` beats `drafted`), regardless of which agent got there.
2. If **both** `ai-{stage}` and `ni-{stage}` are in the set → the qualifier is the bare stage.
3. Otherwise → the qualifier is the one agent that reached it, prefixed: `ai-{stage}` or `ni-{stage}`.

| `maturity` set | Qualifier | Reads as |
|----------------|-----------|----------|
| `["ai-drafted"]` | `-ai-drafted` | A machine wrote it; nothing else has happened. |
| `["ai-drafted", "ni-drafted"]` | `-drafted` | Both wrote; neither reviewed nor validated. |
| `["ai-drafted", "ai-validated"]` | `-ai-validated` | A machine took it to a live tenant. No person has reviewed it. |
| `["ai-drafted", "ni-reviewed"]` | `-ni-reviewed` | A person vouched for it; nobody has applied it. |
| `["ai-drafted", "ai-validated", "ni-reviewed"]` | `-ai-validated` | Furthest stage is `validated`, reached by AI alone — the `ni-reviewed` claim is real but sits at an earlier stage, so it does not appear in the qualifier. Read the banner chips, not just the string. |
| `["ai-drafted", "ai-validated", "ni-validated"]` | `-validated` | Both agents validated. |

**`v1.0.0-validated` is the strongest string this system can produce** — a guide that both a machine and a person applied and tested on real systems. Note the deliberate lossiness in row five: the qualifier is a headline, not the record. The record is the status set, which the banner always renders in full.

#### How the statuses are enforced

- **Allowlist (machine-checked).** `scripts/validate-guides.sh` Test 5b requires `maturity` to be a **list** — a bare scalar is rejected outright — with every member drawn from the six statuses, at least one member present, and any `*-reviewed` or `*-validated` claim resting on a `*-drafted` claim in the same set, because nothing can be reviewed or validated before it exists. This test exists because an unrecognised value fails nowhere else: `docs/_includes/status-set.html` falls through to a bare `{% else %}` that resolves to `ai-drafted`, silently publishing a guide whose banner contradicts its own frontmatter with zero red anywhere.
- **Per-requirement badge.** Any status can also mark an individual control, via `{% include status-badge.html status="…" evidence="…" date="…" %}` placed on its own line **between** a control's `### N.N` heading and its `**Profile Level:**` line. In practice `ai-validated` is the one that gets stamped, and only on controls a run returned `VERIFIED-LIVE` for — never `SKIPPED`, `BLOCKED`, or `DRIFT-CHECKED-ONLY`. Two badges on one control (a machine and a person both exercised it) go on consecutive lines in that same slot: they add, they do not replace. The include's own comment block documents why every other placement breaks something silently — heading anchors, the cheat-sheet parser, the description cell. The page-level status is the sum of these badges, which is why the badge and the banner deliberately render the same mark.
- **Provenance.** The changelog row that adds a status names the act that earned it — which run, against what, how many controls came back live — so the claim is auditable rather than asserted.

### Version Examples

- `v0.1.0-ai-drafted` - Initial AI-drafted guide
- `v0.1.1-ai-drafted` - Typo fixes (PATCH)
- `v0.2.0-ai-drafted` - New control added (MINOR)
- `v0.2.0-ai-validated` - Same content, now exercised against a live tenant by an agent (status added, no content change)
- `v0.2.0-ni-reviewed` - Same content, now vouched for by a human practitioner (status added, no content change)
- `v1.0.0-ni-validated` - First release a person applied and tested on a real system (MAJOR milestone)
- `v1.0.0-validated` - The same guide once a machine has validated it too — the strongest qualifier the vocabulary produces
- `v2.0.0-validated` - Net-new product added (MAJOR scope expansion)

### Author Attribution

Changelog entries must attribute authors accurately:

| Author Type | Format | Example |
|-------------|--------|---------|
| Human contributor | GitHub handle or name | `@username`, `Jane Doe` |
| Claude Code | `Claude Code ({model})` | `Claude Code (Opus 4.5)` |
| Other AI tools | `{Tool Name} ({model})` | `GitHub Copilot (GPT-4)` |
| Community (legacy) | `How to Harden Community` | For pre-versioning entries |

---

## Guide Version Registry

Last updated: 2026-08-20 — 130 guides. Every one is `ai-drafted`; two (Buildkite, Ona) additionally hold `ai-validated`. **No guide holds any `ni-*` status** — the whole natural-intelligence half of the matrix is currently empty.

> **This table is derived, not authored.** Every cell comes from a guide's own YAML frontmatter — `title` (minus the trailing "Hardening Guide"), `tier`, `version`, `maturity`, `last_updated` — which is the source of truth. Hand-patching one row is how this registry fell 76 guides behind between 2025-12-27 and 2026-08-20 while every guide file was individually correct. Rebuild the whole thing from frontmatter rather than editing rows; this dumps the inputs:

```bash
grep -H -E '^(title|tier|version|maturity|last_updated):' docs/_guides/*.md
```

A guide is listed here because it exists on disk — presence in this table is bookkeeping and confers no status. The `Maturity` column is the guide's own status **set**, ` · `-joined in the canonical order `status-set.html` uses (stage ascending, `ai` before `ni` within a stage), so the cell reads the same way the guide's own banner does. What each status means is defined once, above, under [Maturity Statuses](#maturity-statuses--the-matrix).

### Tier 1 (High Priority)

| Guide | Version | Maturity | Last Updated |
|-------|---------|----------|--------------|
| [Anthropic Platform](docs/_guides/anthropic-claude.md) | v1.1.0 | ai-drafted | 2026-08-15 |
| [AWS IAM Identity Center](docs/_guides/aws-iam-identity-center.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [BeyondTrust](docs/_guides/beyondtrust.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [ChatGPT Enterprise](docs/_guides/chatgpt-enterprise.md) | v0.3.0 | ai-drafted | 2026-08-08 |
| [Claude API & Console](docs/_guides/anthropic-api.md) | v1.1.0 | ai-drafted | 2026-08-15 |
| [Claude Code](docs/_guides/claude-code.md) | v1.0.2 | ai-drafted | 2026-08-15 |
| [Claude Enterprise](docs/_guides/claude-enterprise.md) | v0.2.0 | ai-drafted | 2026-08-15 |
| [Cloudflare Zero Trust](docs/_guides/cloudflare.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [CrowdStrike Falcon](docs/_guides/crowdstrike.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Cursor](docs/_guides/cursor.md) | v0.4.0 | ai-drafted | 2026-08-08 |
| [Datadog](docs/_guides/datadog.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [GitHub](docs/_guides/github.md) | v0.7.1 | ai-drafted | 2026-08-08 |
| [Gmail](docs/_guides/gmail.md) | v0.1.0 | ai-drafted | 2026-08-03 |
| [Google Chat](docs/_guides/google-chat.md) | v0.3.0 | ai-drafted | 2026-08-12 |
| [Google Drive](docs/_guides/google-drive.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Google Workspace](docs/_guides/google-workspace.md) | v0.4.1 | ai-drafted | 2026-08-08 |
| [HashiCorp Vault](docs/_guides/hashicorp-vault.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [Idira (formerly CyberArk)](docs/_guides/cyberark.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [LangChain](docs/_guides/langchain.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Microsoft 365](docs/_guides/microsoft-365.md) | v0.3.1 | ai-drafted | 2026-08-08 |
| [Microsoft Entra ID](docs/_guides/microsoft-entra-id.md) | v0.3.0 | ai-drafted | 2026-08-08 |
| [Microsoft Intune](docs/_guides/microsoft-intune.md) | v0.3.0 | ai-drafted | 2026-08-08 |
| [MongoDB Atlas](docs/_guides/mongodb-atlas.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Netskope](docs/_guides/netskope.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [Okta](docs/_guides/okta.md) | v0.4.1 | ai-drafted | 2026-08-08 |
| [OneLogin](docs/_guides/onelogin.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [Ping Identity](docs/_guides/ping-identity.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [SentinelOne](docs/_guides/sentinelone.md) | v0.1.3 | ai-drafted | 2026-08-08 |
| [ServiceNow](docs/_guides/servicenow.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Slack](docs/_guides/slack.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [Snowflake](docs/_guides/snowflake.md) | v0.4.1 | ai-drafted | 2026-08-08 |
| [Splunk Cloud](docs/_guides/splunk.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Stripe](docs/_guides/stripe.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Zscaler](docs/_guides/zscaler.md) | v0.1.2 | ai-drafted | 2026-08-08 |

### Tier 2

| Guide | Version | Maturity | Last Updated |
|-------|---------|----------|--------------|
| [1Password Business](docs/_guides/1password.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [Abnormal AI](docs/_guides/abnormal.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Airtable](docs/_guides/airtable.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Amplitude](docs/_guides/amplitude.md) | v0.1.2 | ai-drafted | 2026-08-08 |
| [Asana](docs/_guides/asana.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Atlassian Cloud](docs/_guides/atlassian.md) | v0.4.0 | ai-drafted | 2026-08-08 |
| [Auth0](docs/_guides/auth0.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Azure DevOps](docs/_guides/azure-devops.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Bitbucket Cloud](docs/_guides/bitbucket.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [Braze](docs/_guides/braze.md) | v0.1.2 | ai-drafted | 2026-08-08 |
| [Buildkite](docs/_guides/buildkite.md) | v0.3.1 | ai-drafted · ai-validated | 2026-08-20 |
| [CircleCI](docs/_guides/circleci.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Cisco Duo Security](docs/_guides/duo.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [Clari](docs/_guides/clari.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Coupa](docs/_guides/coupa.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Databricks](docs/_guides/databricks.md) | v0.3.0 | ai-drafted | 2026-08-03 |
| [DocuSign](docs/_guides/docusign.md) | v0.1.2 | ai-drafted | 2026-08-08 |
| [Drata](docs/_guides/drata.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Figma Enterprise](docs/_guides/figma.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Fivetran](docs/_guides/fivetran.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [GitLab](docs/_guides/gitlab.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [Gong](docs/_guides/gong.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Harness](docs/_guides/harness.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [HubSpot](docs/_guides/hubspot.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Intercom](docs/_guides/intercom.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Jamf Pro](docs/_guides/jamf.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Jenkins](docs/_guides/jenkins.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [JFrog](docs/_guides/jfrog.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [Jira Cloud](docs/_guides/jira-cloud.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [JumpCloud](docs/_guides/jumpcloud.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Keeper Security](docs/_guides/keeper.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [KnowBe4](docs/_guides/knowbe4.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [LastPass Business](docs/_guides/lastpass.md) | v0.1.2 | ai-drafted | 2026-08-08 |
| [Mimecast](docs/_guides/mimecast.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Mixpanel](docs/_guides/mixpanel.md) | v0.1.2 | ai-drafted | 2026-08-08 |
| [Monday.com](docs/_guides/monday.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [NetSuite](docs/_guides/netsuite.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Notion](docs/_guides/notion.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [Ona](docs/_guides/ona.md) | v0.2.1 | ai-drafted · ai-validated | 2026-08-20 |
| [Orca Security](docs/_guides/orca.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Outreach](docs/_guides/outreach.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [PagerDuty](docs/_guides/pagerduty.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Paylocity](docs/_guides/paylocity.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Postman Enterprise](docs/_guides/postman.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [Proofpoint](docs/_guides/proofpoint.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Qualys](docs/_guides/qualys.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Rapid7](docs/_guides/rapid7.md) | v0.2.2 | ai-drafted | 2026-08-08 |
| [Salesforce](docs/_guides/salesforce.md) | v0.2.0 | ai-drafted | 2026-08-03 |
| [SAP Concur](docs/_guides/concur.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Segment](docs/_guides/segment.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [SendGrid](docs/_guides/sendgrid.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [Sentry](docs/_guides/sentry.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [Shopify Plus](docs/_guides/shopify.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Square](docs/_guides/square.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Tenable](docs/_guides/tenable.md) | v0.2.2 | ai-drafted | 2026-08-08 |
| [Twilio](docs/_guides/twilio.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [UKG Pro](docs/_guides/ukg.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Vanta](docs/_guides/vanta.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Webex](docs/_guides/webex.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Wiz](docs/_guides/wiz.md) | v0.1.2 | ai-drafted | 2026-08-08 |
| [Workato](docs/_guides/workato.md) | v0.3.0 | ai-drafted | 2026-08-08 |
| [Workday](docs/_guides/workday.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Zoom](docs/_guides/zoom.md) | v0.2.2 | ai-drafted | 2026-08-08 |

### Tier 3

| Guide | Version | Maturity | Last Updated |
|-------|---------|----------|--------------|
| [Adobe Marketo](docs/_guides/marketo.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [ADP](docs/_guides/adp.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Box](docs/_guides/box.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [Docker Hub](docs/_guides/dockerhub.md) | v0.3.0 | ai-drafted | 2026-08-08 |
| [Dropbox](docs/_guides/dropbox.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Fullstory](docs/_guides/fullstory.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [HCP Terraform (formerly Terraform Cloud)](docs/_guides/terraform-cloud.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Heap](docs/_guides/heap.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Kernel](docs/_guides/kernel.md) | v0.1.0 | ai-drafted | 2026-08-11 |
| [Linear](docs/_guides/linear.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Lovable](docs/_guides/lovable.md) | v0.1.0 | ai-drafted | 2026-08-15 |
| [Oracle HCM Cloud](docs/_guides/oracle-hcm.md) | v0.1.2 | ai-drafted | 2026-08-08 |
| [Pendo](docs/_guides/pendo.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Replit](docs/_guides/replit.md) | v0.1.0 | ai-drafted | 2026-08-15 |
| [SailPoint](docs/_guides/sailpoint.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [SAP SuccessFactors](docs/_guides/sap-successfactors.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Windows 11](docs/_guides/windows-11.md) | v0.1.0 | ai-drafted | 2026-08-15 |

### Tier 4

| Guide | Version | Maturity | Last Updated |
|-------|---------|----------|--------------|
| [Klaviyo](docs/_guides/klaviyo.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [LaunchDarkly](docs/_guides/launchdarkly.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Mailchimp](docs/_guides/mailchimp.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Miro](docs/_guides/miro.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Tableau](docs/_guides/tableau.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [Zendesk](docs/_guides/zendesk.md) | v0.2.0 | ai-drafted | 2026-08-08 |

### Tier 5

| Guide | Version | Maturity | Last Updated |
|-------|---------|----------|--------------|
| [BambooHR](docs/_guides/bamboohr.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Freshservice](docs/_guides/freshservice.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Gusto](docs/_guides/gusto.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Looker](docs/_guides/looker.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [New Relic](docs/_guides/new-relic.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Power BI](docs/_guides/power-bi.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Rippling](docs/_guides/rippling.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Smartsheet](docs/_guides/smartsheet.md) | v0.2.0 | ai-drafted | 2026-08-08 |
| [Snyk](docs/_guides/snyk.md) | v0.2.1 | ai-drafted | 2026-08-08 |
| [Vercel](docs/_guides/vercel.md) | v1.2.1 | ai-drafted | 2026-08-08 |

---

## Version History Summary

| Milestone | Date | Description |
|-----------|------|-------------|
| Maturity became a matrix | 2026-08-20 | The single-file ladder was replaced by three stages × two agents: six non-exclusive statuses held as a set. The retired rungs map forward — the old top rung (a person tested it in production) is now `ni-validated`, the old review rung is `ni-reviewed`, and the old starting rung is `ai-drafted`. `maturity` frontmatter became a list, the version qualifier became derived, and `validate-guides.sh` Test 5b now enforces the list form, the six names, and the rule that a `*-reviewed`/`*-validated` claim rests on a `*-drafted` one |
| `ai-validated` rung added | 2026-08-20 | Machine validation was first modelled as one more rung on the old ladder — superseded the same day by the matrix, which kept the distinction and dropped the false claim that machine work and human work sit on one ordered scale |
| GitHub guide v0.4.0 | 2026-03-07 | Major revamp: 33 controls, control YAML alignment, new sections 7-8 |
| Versioning model introduced | 2025-12-27 | Extended SemVer with maturity qualifiers adopted |
| Initial guides created | 2025-12-13 | 53 AI-drafted guides published |

---

## Notes

- **Pre-1.0 versions**: All guides start at `v0.x.x` during the alpha phase. Version `v1.0.0` is reserved for guides that have reached **`ni-validated`** — a person applied and tested the controls on a real system. **`ai-validated` does not qualify on its own**: the v1.0.0 milestone is gated on human contact, and a machine-validated guide is still an unreviewed, human-untested guide. A guide that holds both validated statuses ships as `v1.0.0-validated`, which is the strongest version string this system can print.
- **Statuses accumulate, they do not replace**: a guide can gain a status without any content change (`["ai-drafted"]` → `["ai-drafted", "ai-validated"]`, version untouched), or change content while holding the same set (`v0.1.0-ai-validated` → `v0.2.0-ai-validated`). Nothing has to be earned in order across agents: a human practitioner reviewing a guide adds `ni-reviewed` whether or not an agent ever validated it, and `ai-validated` is never a prerequisite for anything on the NI row. The only ordering the model enforces is within the stage axis — `*-reviewed` and `*-validated` presuppose a `*-drafted` claim, because nothing can be reviewed or validated before it exists (Test 5b checks exactly this).
- **The AI half is never a stand-in for the NI half**: `ai-reviewed` and `ai-validated` describe what a machine did and assert nothing about human judgement. Adding them never closes out the need for `ni-reviewed` or `ni-validated`, and a guide sitting at `ai-validated` for a year is a guide that has been waiting a year for a reviewer.
- **Demotion is normal**: a status is a claim about the world, so it expires when the world moves. If a currency pass finds the vendor moved a console path or removed a setting, remove the statuses that finding invalidates (and strip the per-requirement badges that went with them) rather than leaving a stale claim standing — typically dropping a guide back to `["ai-drafted"]`. Say so in the changelog row; a narrowing set with no explanation looks like a mistake.
- **Registry updates**: This file should be updated whenever a guide version changes. The registry above is derived from guide frontmatter — regenerate it rather than hand-patching one row (see the note under the registry heading).
- **CIS alignment**: This versioning model is inspired by [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks), which use semantic versioning where MAJOR versions signal significant platform changes or restructuring, and version numbers don't reflect minor editorial changes that don't change the security posture.
- **DISA STIG comparison**: Unlike [DISA STIGs](https://public.cyber.mil/stigs/) which use Version/Release (VxRy) notation with quarterly release cycles, HTH uses semantic versioning for broader accessibility outside DoD contexts.
