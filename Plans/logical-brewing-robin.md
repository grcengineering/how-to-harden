# Plan: Add Trivy/TeamPCP Supply Chain Attack Controls to GitHub Guide

## Context

In March 2026, Aqua Security's Trivy ecosystem was compromised in a sophisticated three-stage supply chain attack:

1. **hackerbot-claw** (Feb 27-28): AI-powered bot exploited `pull_request_target` workflows across 7 repos including `aquasecurity/trivy`, stole a PAT, privatized the repo
2. **Tag poisoning** (March 19): 75 of 76 `trivy-action` tags force-pushed to malicious commits containing "TeamPCP Cloud stealer" — a three-stage credential harvester that read `/proc/*/mem`, scraped cloud creds/SSH keys, and exfiltrated to typosquat domain `scan.aquasecurtiy.org`
3. **CVE-2026-26189**: Pre-existing script injection in trivy-action (unsanitized `${{ }}` input sourcing)

This connects to the March 2025 tj-actions/reviewdog chain (same TTP class). The existing GitHub guide (v0.4.0) covers Actions security in Section 3 (3.1-3.7) and supply chain in Section 6 (6.1-6.5), but has specific gaps around these TTPs.

## Approach: Add New Controls to Existing GitHub Guide

Add **4 new controls** to the GitHub guide — 3 in Section 3 (Actions) and 1 in Section 6 (Supply Chain). Each control maps to a specific TTP from the Trivy/TeamPCP attack chain.

### New Controls

#### 3.8 Secure `pull_request_target` Workflows Against Pwn Requests
**Priority:** P0 | **Profile:** L1 | **Root cause for:** hackerbot-claw (Feb 2026), SpotBugs→reviewdog→tj-actions (2024-2025)

- **What:** Dedicated control for `pull_request_target` security — the single most exploited GitHub Actions vulnerability
- **Content:**
  - Explain the Pwn Request attack pattern (untrusted checkout + secrets access)
  - UNSAFE pattern: `pull_request_target` + `actions/checkout@ref: ${{ github.event.pull_request.head.sha }}`
  - SAFE split-workflow pattern: untrusted build in `pull_request`, trusted labeling/commenting in separate `pull_request_target` that never checks out PR code
  - SAFE artifact pattern: build in `pull_request`, upload artifact, download + deploy in `pull_request_target`
  - Never interpolate `${{ github.event.pull_request.* }}` in `run:` blocks — use environment variables
  - Reference hackerbot-claw hitting 7 repos including Trivy, and SpotBugs root cause for the 2025 chain
- **Pack files:** Workflow YAML examples showing unsafe vs safe patterns
- **Why this is a new control vs enhancing 3.3:** Section 3.3 covers "workflow approval for first-time contributors" which is a blunt mitigation. `pull_request_target` security requires specific workflow architecture patterns, not just approval settings.

#### 3.9 Enforce Runner Process and Network Isolation
**Priority:** P1 | **Profile:** L2 | **Defends against:** TeamPCP `/proc` memory harvesting, C2 exfiltration

- **What:** Harden self-hosted runners against credential theft from process memory and unauthorized network egress
- **Content:**
  - The TeamPCP payload read `/proc/*/mem` to extract secrets from `Runner.Worker` process memory
  - Runner containerization: ephemeral containers with restricted `/proc` access (read-only `/proc/sys`, no `/proc/*/mem`)
  - seccomp profiles blocking `ptrace` and `/proc` access
  - Network egress allowlisting: only permit connections to GitHub APIs, package registries, and required services
  - StepSecurity Harden-Runner as runtime enforcement (already mentioned in 3.7 as monitoring; this control covers enforcement)
  - Self-hosted runner security hardening: non-root execution, read-only filesystem, no `sudo`
- **Pack files:** Kubernetes runner pod spec with security context, Harden-Runner workflow config with egress policy
- **Why this is new vs enhancing 3.4:** Section 3.4 covers runner security conceptually (ephemeral, runner groups). This control adds specific process isolation and network enforcement techniques that defend against the TeamPCP credential harvesting payload.

#### 3.10 Detect and Prevent Action Tag Poisoning
**Priority:** P0 | **Profile:** L1 | **Defends against:** trivy-action tag poisoning, tj-actions tag rewrite

- **What:** Detect mutable tag manipulation and enforce immutable action references
- **Content:**
  - How tag poisoning works: attacker force-pushes tag to point at malicious commit
  - **Detection:** Imposter commit detection — commits reachable only via tags (not on any branch) are suspicious
  - **Detection:** Unsigned tags on previously-signed repositories (all 75 poisoned trivy-action tags lacked GPG signatures)
  - **Detection:** Tag commit date vs parent date inconsistency (commits dated 2021 with March 2026 parents)
  - **Prevention:** SHA pinning with automated verification (Dependabot + Renovate can pin + update SHAs)
  - **Prevention:** `actions/dependency-review-action` to block compromised actions
  - **Monitoring:** Workflow to audit action SHAs against known-good values
  - Reference both trivy-action (75 tags poisoned) and tj-actions (all tags rewritten) incidents
- **Pack files:** SHA audit workflow, Dependabot config for Actions pinning
- **Why this is new vs enhancing 3.1/3.7:** Section 3.1 restricts to verified creators, 3.7 mentions SHA pinning tools. This control covers the *detection* of tag poisoning after it happens — a gap exposed when 23,000+ repos were affected by tj-actions before anyone noticed.

#### 6.6 Respond to CI/CD Supply Chain Compromises
**Priority:** P1 | **Profile:** L1 | **Defends against:** Post-compromise response for any Actions supply chain attack

- **What:** Incident response playbook for when a GitHub Action dependency is compromised
- **Content:**
  - **Immediate triage:** Identify affected workflows using `gh api` to search for action references
  - **Credential rotation:** ALL secrets accessible to affected workflows must be rotated (not just "changed" ones)
  - **Exfiltration check:** Search org for `tpcp-docs` repos (TeamPCP fallback exfil), check workflow logs for suspicious network calls
  - **Forensic indicators:** Base64-encoded Python in workflow logs, `/proc/*/mem` access patterns, connections to typosquat domains
  - **Containment:** Pin affected action to known-good SHA, disable affected workflows, review recent runs
  - **Communication:** Notify downstream consumers if your Actions/packages may have been affected
  - Reference both Trivy (March 2026) and tj-actions (March 2025) response timelines
- **Pack files:** Shell script to audit org workflows for compromised action references, KQL/Splunk query for detecting exfil patterns
- **Why this is new:** No existing control covers incident response for supply chain compromise. Section 6 covers prevention (dependency review, pinning, Dependabot) but not response.

### Enhancements to Existing Controls

In addition to the 4 new controls, make targeted enhancements:

1. **Section 3.1** (Restrict Actions): Add Trivy incident as a real-world example alongside tj-actions
2. **Section 3.3** (Workflow Approval): Add cross-reference to new 3.8 for deeper `pull_request_target` guidance
3. **Section 3.7** (Security Tools): Add `zizmor` detection rules for `pull_request_target` patterns, note Harden-Runner detected Trivy C2 callout
4. **Section 6.1** (Dependency Review): Add note about Actions dependencies (not just package dependencies)

### Files to Modify/Create

| File | Action |
|------|--------|
| `docs/_guides/github.md` | Add sections 3.8, 3.9, 3.10, 6.6; enhance 3.1, 3.3, 3.7, 6.1 |
| `packs/github/cli/hth-github-3.22-secure-pull-request-target.yml` | SAFE workflow YAML examples |
| `packs/github/cli/hth-github-3.23-runner-process-network-isolation.yml` | Runner hardening configs |
| `packs/github/cli/hth-github-3.24-detect-tag-poisoning.sh` | SHA audit script |
| `packs/github/cli/hth-github-6.07-supply-chain-compromise-response.sh` | Org audit script |
| `docs/_data/packs/github.yml` | Re-sync after new pack files |

### Numbering: Guide Headings vs Pack Sections

**Critical:** The guide's heading numbers (3.1-3.7) are separate from the pack include section numbers (3.1-3.21, 6.1-6.6). The guide already uses `{% include pack-code.html section="3.8" %}` through `section="3.21"` for existing sub-packs within sections 3.1-3.7.

**Guide heading numbers (new):** 3.8, 3.9, 3.10, 6.6 — these don't conflict with existing GUIDE headings.

**Pack section numbers (new, for include tags):**
- Next available in section 3: **3.22, 3.23, 3.24**
- Next available in section 6: **6.7**

**Mapping:**

| Guide Heading | Pack Section(s) | Pack File Number |
|--------------|-----------------|------------------|
| 3.8 (pull_request_target) | 3.22 | `hth-github-3.22-*` |
| 3.9 (Runner isolation) | 3.23 | `hth-github-3.23-*` |
| 3.10 (Tag poisoning) | 3.24 | `hth-github-3.24-*` |
| 6.6 (Compromise response) | 6.7 | `hth-github-6.07-*` |

### Verification

1. `grep -cE '^ *```' docs/_guides/github.md` returns 0 (no inline code blocks)
2. Pack sync produces updated `docs/_data/packs/github.yml` with new sections
3. Each new control has both ClickOps and Code implementations
4. Compliance mappings (SOC 2, NIST 800-53, SLSA) for each new control
5. Real-world incident references for each control
