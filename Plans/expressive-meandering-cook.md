# Plan — `validate-hth-guide`: the fifth HTH skill

## Context

The repo ships four skills. The one named "verify" (`verify-hth`) answers **"does this render correctly?"** — lint, zero-fence, cheat parity, pack *wiring*, bookkeeping. Not one of its six checks asks **"does this actually work?"**

Nothing in the repo executes a Code Pack, syntax-checks one, re-fetches a cited vendor doc, or runs an OCEAN control. `packs/schema/control.schema.json` exists and **is referenced by no script, target, or workflow**. `CONTRIBUTING.md` L155–161 asks contributors to "Test all ClickOps steps in a real environment" and "Check all external links" with zero tooling behind it.

The cost is measurable. A read-only sweep of the current tree found **eight classes of live defect** nobody has seen, because nothing looks:

| # | Defect | Detail |
|---|---|---|
| 1 | 4 silent `(section,type)` collisions | `bitbucket\|config\|4.3`, `chatgpt-enterprise\|api\|6.6`, `github\|api\|5.8`, `hashicorp-vault\|cli\|5.2` — sync drops one file each, no warning |
| 2 | 7 control YAMLs fail `control.schema.json` | `compliance.cis_controls` ×6, `compliance.slsa` ×1 |
| 3 | 5 more fail via `remediate.manual` | undefined key under `additionalProperties: false`; `note:` in 29 more |
| 4 | 1 duplicate Sigma UUID | `c3d4e5f6-a7b8-…` shared by github + terraform-cloud; visibly a placeholder |
| 5 | 6 broken `guide_url` anchors | e.g. github-8.1 → `#71-enable-audit-log-streaming-to-siem` NOT FOUND |
| 6 | 2 missing shebangs, 4 `bash -n` failures | 4 are deliberate doc-snippets; 2 are real |
| 7 | ~30 extension/type violations | `.ps1`/`.py`/`.graphql` in `api/`, `.ps1`/`.hcl` in `cli/` |
| 8 | Dead sync branch | `detect_type()` emits `scripts`, `process_vendor()` can't consume it; 5 okta files unreachable |

**Outcome intended:** a fifth skill that validates guidance against the world rather than against itself, and — the part that makes it a skill and not a linter — **steers agents to iterate fix→revalidate until zero fixable failures remain.**

Scope: 1,128 pack files across 78 vendors · 130 guides · 1,844 controls (66.3% ClickOps-only) · ~2,215 distinct URLs across ~441 hosts.

---

## Binding decisions

1. **Credentials are 1Password-first, and plaintext secrets NEVER enter an agent's context window.** Built on 1Password's documented AI-security stack — Environments, the Agent Hook, `op run`, Shell Plugins, and the Claude connector (§5). An architectural invariant, not a preference.
2. **Code Packs are dual-consumption: standalone-executable AND OCEAN-consumable.** A user must be able to run any pack directly with no OCEAN present; OCEAN must be able to introspect and invoke the same file. Neither contract may break the other (§4).
3. **OCEAN's format is canonical for *control definitions*.** HTH's 74 `packs/*/controls/*.yaml` are deprecated → flagged for migration. This does **not** apply to pack code, which keeps its dual contract per decision 2.
4. **OCEAN is mandatory, never optional.** Discovery: known local repo → prompt for path → offer to clone. Never silently skip.
5. **ClickOps is tiered.** Doc-drift always; Interceptor live walk-through where a tenant is declared. `VERIFIED-LIVE` and `DRIFT-CHECKED-ONLY` never merge.
6. **Live execution allows any safety classification with typed confirmation** — except a hard-refusal class for irreversible destruction or lockout (§6.3), not overridable by confirmation.
7. **Loop until zero FAIL**, with a five-class `BLOCKED` taxonomy.

---

## Discovered constraints that make the naive build wrong

Verified this session. Each would have produced a broken implementation:

- **The `ocean` on PATH is stale.** `/Users/p4gs/.local/bin/ocean` is `0.1.0` and **rejects `ocean build`**. The repo-built `~/Code/grcengineering/OCEAN/target/release/ocean` supports `build`/`verify`/`custody`/`evidence`/`init`. Resolve **repo-first**, then **probe capability** — a version check would not catch this.
- **OCEAN already ships the gate.** `ocean build --validate --source checks` runs clean today: `Validated 69 check(s) — templates OK`, exit 0.
- **OCEAN's safety model is already correct.** `ocean harden` is dry-run by default (`--apply` required); `ocean test` refuses observable/reversible/destructive without `--confirm`.
- **1Password's AI stack is five distinct products, not one** — and picking the wrong one per surface is the easy failure (§5). Specifically: **1Password for Claude is a *browser* connector, not an MCP server**; **Agentic Autofill is Browserbase-only** during Early Access and does **not** work with a local browser, so it cannot serve Interceptor-driven ClickOps.
- **`op` CLI 2.33.1 is installed locally**; no 1Password MCP is registered for Claude Code today (`claude mcp list`).
- **Interceptor drives the operator's already-authenticated browser**, so ClickOps validation usually has **no login step** — and its bridge already refuses to type while 1Password is frontmost. A plan that specifies its own browser-credential flow would both duplicate and contradict a shipped skill (§5.5).
- **1Password Environments' locally-mounted `.env` files are FIFOs (named pipes)**, "aren't tracked by Git or stored on disk, and are only available at the moment you access it" — and are **Mac/Linux only**. The repo supports Windows via Git Bash throughout, so Windows needs a documented fallback.
- **`sync-packs-to-data.sh` always exits 0** (`process_vendor … || true`, ~line 483) and **silently skips its lone YAML check when `python3` is absent**. The new script must exit `2` rather than inherit the bug.
- **Generated ymls carry `# Generated: <ISO8601>`** (line 161) — freshness diffs must strip it.
- **69 pack `.sh` files mutate** (`-X POST|PUT|PATCH|DELETE`); only **7** have any `DRY_RUN` notion. Execution is default-deny.
- **~30 hosts lie about HTTP status** (SOURCES.md Rule 1): SPA-200-always (`help.zscaler.com`, `help.bamboohr.com`), 403-to-fetchers (`media.defense.gov`), and the inverse trap `docs.cyberark.com` which 404s to fetchers on *every* path including root. Only 5 hosts are certified honest-404.
- **Two arrow dialects** in ClickOps paths: ~2,692 bold spans use `→`, ~111 use ASCII `->` (github.md exclusively).
- **`.jsonc` is not parseable JSON** by design (multiple root objects + `//` comments).
- **Two incompatible `common.sh` dialects** across 18 shared libs: anthropic-style (`pass()` auto-increments, `require_admin_key()`) vs github-style (explicit `increment_applied()`, bash `:?`, `should_apply N` profile gate). The dual contract (§4) must accommodate both without a rewrite.
- **`hth-map.yaml`** (cross-repo id map) exists **only in OCEAN worktrees**, not on OCEAN main.

---

## The verdict lattice

| Verdict | Meaning | Green? |
|---|---|---|
| `PASS` | Ran, satisfied | Yes |
| `VERIFIED-LIVE` | Observed against a real tenant | Yes — strongest |
| `DRIFT-CHECKED-ONLY` | Doc-level only; no tenant touched | Yes, **weaker — never printed as PASS** |
| `SKIPPED` | Precondition absent | **No. Neutral.** |
| `BLOCKED` | Failed, in the named unfixable taxonomy, with evidence | **No. Terminal-but-legitimate.** |
| `FAIL` | Failed, fixable | **No. Non-terminal — must loop.** |

Invariants in SKILL.md: **SKIPPED is not PASS** (clean only when `FAIL = 0` *and* every SKIPPED names its missing precondition) · **`VERIFIED-LIVE` and `DRIFT-CHECKED-ONLY` never merge into one number.**

---

## Tier × surface matrix

| | **T0 — Corpus integrity**<br>always · offline | **T1 — Doc drift**<br>always · network | **T2 — Semantic**<br>needs creds | **T3 — Live proof**<br>needs declared tenant |
|---|---|---|---|---|
| **ClickOps** | ClickOps H4 present per leveled control; console paths extractable (both arrows); `guide_url` anchors resolve | Re-fetch vendor docs + `doc_links.yml`; assert path **leaf label** still present; host-policy-aware → `DRIFT-CHECKED-ONLY` | — | Interceptor walk-through, sign-in via **1Password for Claude** → `VERIFIED-LIVE` |
| **Code Packs** | collisions · marker hygiene · shebang · `bash -n` w/ directive · ext↔type · sync freshness + reachability · Sigma UUID · include↔yml · **dual-contract header (§4)** | endpoints traced to live vendor docs | `shellcheck` w/ named exclusions · sigma schema · jq parses · **dry-run under `op run --environment`** | read-only packs executed; **mutating default-deny** → `VERIFIED-LIVE` |
| **OCEAN** | HTH `controls/*.yaml` flagged `MIGRATION-REQUIRED` | — | discovery + capability probe · `ocean build --validate` · `ocean modules validate` | `ocean observe` / `report` / `harden` (dry-run) → `VERIFIED-LIVE` |

**Always-on = T0 + T1.** Every unopened gate emits `SKIPPED` with a reason.

---

## §4 — The dual-consumption pack contract

**The requirement:** a Code Pack must run standalone (`bash packs/github/api/hth-github-1.10-*.sh`, env vars set, no OCEAN anywhere) *and* be introspectable/invocable by OCEAN. Today the first is true by convention and the second is true for nothing. Both become validated contracts.

### 4.1 Standalone contract (preserve — today's behavior, now enforced)

- shebang present; `set -euo pipefail` (directly or via a sourced `common.sh`)
- **every required credential declared via `: "${VAR:?...}"`** so a missing var fails loudly with guidance
- **zero dependency on the OCEAN binary, repo, or env** — a pack that needs OCEAN to run is a contract violation
- deterministic exit codes: `0` satisfied/applied · non-zero otherwise
- relative self-reference only (`source "$(dirname "$0")/common.sh"`)

### 4.2 OCEAN-consumable contract (add — additive, never breaking)

Formalize the header comment ~95% of packs already carry into a machine-readable block. Comment-prefix agnostic (`#`, `//`, `--`), so it works across all pack types:

```bash
# HTH Pack Contract: v1
#   control: github-1.10
#   guide:   https://howtoharden.com/guides/github/#13-enable-saml-sso
#   profile: L2
#   mode:    read-only            # read-only | mutating
#   requires: GITHUB_TOKEN(read:org), GITHUB_ORG
```

Four fields do real work:
- **`control`** — binds the pack to a control id, giving OCEAN the join key that does not exist today
- **`mode`** — declares mutation class, feeding OCEAN's safety model *and* the default-deny execution gate. Validated against reality: a pack declaring `read-only` that contains `-X POST|PUT|PATCH|DELETE` is a **FAIL** (catches drift both ways across the 69 mutating packs)
- **`requires`** — declared credentials with least-privilege scope. **This one field serves four consumers**: `ocean modules validate`'s credential-requirements check, the 1Password **Environment variable set** (§5), the `.1password/environments.toml` mount config, and `NEEDS-CREDENTIALS` evidence
- **`profile`** — cross-checked against the guide's `**Profile Level:**`; mismatch is a FAIL

Additive output mode: `HTH_OUTPUT=json` emits a structured verdict for OCEAN to parse; unset keeps today's human-readable output. **Default behavior is unchanged** — that's what makes this backward-compatible.

### 4.3 Why this shape

It accommodates both `common.sh` dialects without rewriting either — the contract lives in the pack header, not the helper library. It is comment-only, so every existing pack stays byte-identical in behavior. And it makes the HTH↔OCEAN join real at the pack level even while control *definitions* migrate to OCEAN's schema (decision 3), so the two decisions don't collide.

**Rollout:** `WARN` in PR1 (report coverage: "412/1,128 packs carry a v1 contract"), flipping to `FAIL` only once coverage is complete — otherwise PR1 lands 1,128 failures and the gate is worthless.

---

## §5 — Credentials: the 1Password AI-security stack

Framed on 1Password's own four principles: **"secrets staying secret, deterministic authorization, auditability, and least privilege."** The problem statement is theirs too — *"When you supply these secrets in plaintext, they can leak into LLM context, source control, or config files."* Each of those three leak vectors gets a distinct mechanism below.

**The invariant, stated in SKILL.md as a hard rule:**

> The agent may read, write, and reason about **references and variable names**. The agent must never cause a resolved secret **value** to enter its context. No `op read` into a variable the agent echoes; no `op item get --reveal` in agent-run commands; no pasting a token into a prompt. If a value would become visible, stop and re-route through injection.

### 5.1 The five layers, mapped to surfaces

| Layer | Product | Role in this skill |
|---|---|---|
| **1. Secret storage + injection** | **1Password Environments** | Holds every vendor credential for validation runs. Generates a **locally-mounted `.env` that is a FIFO** — *"aren't tracked by Git or stored on disk, and are only available at the moment you access it."* This is the primary Code Pack execution path. |
| **2. Pre-execution enforcement** | **1Password Agent Hook** (`agent-hook-validate`) | Supports **Claude Code**, Cursor, Copilot, Windsurf. Validates that required `.env` mounts exist, are enabled, and are valid FIFOs *before the agent executes shell commands*; if not, **"the hook prevents the agent from executing"** and returns fix instructions. **This is the teeth** behind "never run a pack without proper credential setup" — Phase 0 requires it installed. |
| **3. MCP config protection** | `op run --environment` wrapper in `mcp.json` | Any credentialed MCP server the skill registers is wrapped so secrets resolve at runtime — *"nothing exposed in plaintext, mcp.json, or LLM context."* |
| **4. CLI auth** | **1Password Shell Plugins** (biometric) | Authenticates CLIs like Claude Code via the desktop app, *"eliminating the need to store plaintext API keys in your shell profile."* |
| **5. ClickOps browser sign-in** | **1Password for Claude** connector | Claude requests the credential; 1Password **fills the login directly on the page** — *"the password and any one-time code never enter Claude's context, memory, or Anthropic's systems."* Biometric approval per use; **Agentic Mode** locks the extension while the AI drives the browser, restricting to task-approved logins. Logins + TOTP only. |

**Explicitly NOT used: Agentic Autofill.** It is **Browserbase-only** during Early Access and requires Browserbase Director — incompatible with this repo's mandated Interceptor/real-local-Chrome doctrine. Recorded here so a future reader doesn't "fix" the plan by reaching for it. If cloud-browser ClickOps is ever wanted, that is the path, and it is a doctrine change.

### 5.2 Concrete setup

Repo-root config the Agent Hook reads (checked in — contains no secrets, only mount names):

```toml
# .1password/environments.toml
mount_paths = ["hth-validation.env"]
```

Execution, with variables resolved into the process and nothing on disk:

```bash
op run --environment <environmentID> -- bash packs/github/api/hth-github-1.10-verify-saml-sso-status.sh
```

The Environment's variable set is generated from the pack contract's `requires:` field (§4.2), so the credential requirement is declared once and consumed by the Environment, the hook config, OCEAN's module validation, and the findings ledger.

### 5.3 Fallbacks, in order

1. Already-authenticated first-party CLIs (`gh auth token`) — zero new secret material
2. **Service account** (`OP_SERVICE_ACCOUNT_TOKEN`) for CI and non-interactive runs
3. `$OCEAN_REPO/scripts/ocean-creds-from-keychain.sh` (**source it, don't reimplement** — it already handles `OKTA_API_KEY → OKTA_API_TOKEN` and tenant-slug normalization)
4. Interactive `read -rs` into a process-lifetime env var

**Windows:** FIFO mounts are Mac/Linux only, so Windows operators use layer 1 via service account + `op run` without local mounts. The skill states this rather than silently failing on a platform the repo otherwise supports.

**Never:** a repo file with real values, a CLI arg (visible in `ps`), or a committed `.env`.

### 5.5 Interceptor composition (cite, don't restate)

Interceptor and its LifeOS skill already define the browser-side security model. This plan **composes with it** and adds only what neither side can know alone.

**Already defined — reference, never re-specify:** real-session operation ("your cookies, logins, tabs, and context intact") · the bridge's **sensitive-frontmost-app denylist**, which rejects `type`/`keys`/`click x,y`/`drag` when 1Password, Keychain, Dashlane, LastPass, Bitwarden, System Settings, or a bank is frontmost, with the standing rule *"Surface the rejection — do not bypass"* (`TrustedInputGate.md`) · **password and credit-card fields auto-masked in recordings** as `***N***` with `# TODO` substitution markers (`RecordFlow.md` / `ReplayFlow.md`) · secure fields never emitted (`AXSecureTextField` returns `•••`) · destructive MCP ops opt-in via `--allow` · the zero-auth Unix socket caveat (`SKILL.md`).

**What this skill adds, because it sits at the seam:**

1. **The real-session model changes the default.** Because Interceptor drives the operator's already-authenticated Chrome, ClickOps validation normally has **no login step at all**. The 1Password for Claude connector (§5.1 layer 5) is the **exception path** — expired session, fresh profile, or a tenant the operator isn't signed into — not the routine one. Plan Phase 4 accordingly: assume authenticated, invoke 1Password only on a sign-in wall.
2. **The frontmost-app gate is a feature, not an obstacle.** It means the biometric approval step is **structurally un-automatable** — which is exactly what makes `VERIFIED-LIVE` trustworthy: a human approved each credential release. Working around that gate is added to the anti-suppression list (§7d).
3. **Never use `interceptor act <ref> "value" --os` for credentials.** `TestForm.md` documents it for password fields, and it is correct there — but it presupposes the agent holds a plaintext value, which violates §5's invariant. In *this* skill 1Password fills the field; the `--os` password path is out of scope.
4. **Evidence redaction — the genuine gap.** Interceptor masks *password fields*; it does not mask what a validation run actually captures: **API tokens in URLs, session cookies in `net log`, org/tenant identifiers, member emails, and on-screen customer data** in screenshots of an authenticated console. HTH is a **public repo whose product is published guides**, so: evidence lands only in gitignored `.hth-validation/`, never under `docs/` · `net log` output is never pasted into a finding — record request *shape* (method + path template + status), not the transcript · prefer `interceptor read` (AX tree) over pixels when the assertion is textual, because text is scrubbable and a screenshot is not · never commit a recording or replay plan produced from a live-tenant walkthrough.
5. **Concurrency caution during credentialed runs.** The Interceptor socket has no authentication — any local process running as the operator can drive the browser. A Tier 3 run against a live tenant is not the moment to have untrusted local processes running.

### 5.4 Operational rules

A `NEEDS-CREDENTIALS` finding records the **variable name, required scope, and Environment/reference path** — never a value. All output lands in gitignored `.hth-validation/`; Phase 5's exit condition includes `git status --porcelain` clean. Least privilege is stated per vendor *before* prompting (GitHub `read:org`; `admin:org` only on explicit mutating opt-in). **Mutation default-deny:** a pack whose contract says `mode: mutating` is `SKIPPED / MUTATING-PACK-NOT-EXECUTED` unless the operator names that file — grounded, since 69 packs mutate and 7 have `DRY_RUN`. Prefer a sacrificial tenant; production gets read-only packs only. Auditability (1P principle 3) comes free: Environment access is logged 1Password-side, and the ledger records which Environment served each run.

---

## §6 — OCEAN integration

### 6.1 Canonical-format consequence (control definitions only)

HTH's 74 `packs/{github,okta}/controls/*.yaml` are **deprecated**. The skill: reports all 74 as `MIGRATION-REQUIRED` with target OCEAN form · validates OCEAN's 69 `checks/**/*.check.yaml` via `ocean build --validate --source "$OCEAN_REPO/checks"` · still resolves each HTH control's `guide_url` anchor (a broken anchor is a real defect regardless of schema — defect 5) · does **not** fix the 12 schema violations in place; they are evidence for deprecation.

Three schemas exist: HTH `packs/schema/control.schema.json` (draft 2020-12, `github-1.7`) · OCEAN `schemas/control.schema.json` (draft-07, `iam.mfa.enforcement`) · OCEAN `schemas/check.schema.json` (`GH-1.01`, padded). HTH github is unpadded. **The padding divergence is what `hth-map.yaml` absorbs — never renumber HTH**, which breaks pack includes and inbound anchors (forbidden by `update-hth-guide` Phase 3). HTH does not own the map; read from `$OCEAN_REPO/controls/hth-map.yaml`, report `SKIPPED / HTH-MAP-ABSENT` until OCEAN lands it.

**Pack code is explicitly out of this deprecation** (decision 2) — it keeps the dual contract of §4.

### 6.2 Live execution

`ocean modules list` (18 today: github 9, okta 4, aws 2, mock 3) → `ocean modules validate` (credential requirements cross-checked against pack `requires:`) → `ocean observe <module> --no-store --format json` (`--no-store` keeps validation from polluting the evidence DB) → `ocean report --framework soc2 --checks-dir "$OCEAN_REPO/checks"` → `ocean harden <check-id>` **without `--apply`**, comparing the dry-run plan against the HTH pack's remediation for the same control; divergence is a FAIL against whichever side lacks a fetched vendor doc. **`--apply` is never issued by this skill.**

### 6.3 The lockout carve-out (hard refusal, not overridable)

Any safety classification may run **with typed confirmation naming the tenant** — with one exception confirmation cannot unlock. Before any `reversible`/`destructive` tester or mutating pack, run a **lockout pre-flight**. Refuse outright if the operation would:

- modify authentication/SSO/MFA config such that future authentication could fail (IdP config, SAML/OIDC settings, MFA enforcement, password policy, session/token revocation)
- remove or downgrade the last administrative principal, or the credential being used for the run
- delete a tenant, org, workspace, or directory
- alter network/IP allowlisting that could exclude the operator
- be irreversible with no documented restore path

**Refusal is unconditional** — not unlocked by `--confirm` or typed confirmation. Finding: `BLOCKED / LOCKOUT-RISK`, naming the operation and the mechanism by which access would be lost. Single exemption: the operator demonstrates an **independent, verified backup access path** (separate API key or break-glass admin, proven to work *before* the operation, verified in the same run and recorded in the ledger — never assumed).

---

## §7 — The fix→validate loop

Designed against the real failure mode: an agent reports once, says "these should be fixed," and stops.

**(a) Findings ledger with stable IDs.** `.hth-validation/findings.md`: `ID | TIER | SURFACE | SUBJECT | VERDICT | ATTEMPTS | EVIDENCE`. IDs are content-derived (`T0-COLLISION-github-api-5.8`) so a defect keeps its ID across runs — which makes "did this get fixed?" answerable instead of vibes.

**(b) Re-validation is a command, not a claim.**

> A finding closes only when the same command that produced it is re-run and no longer produces it. Paste the re-run's terminal line as closing evidence. "Fixed" without a re-run line is not a closed finding — it is an open finding with a claim attached.

Loop granularity is per-phase: fix a batch, re-run the phase command, take the new count.

**(c) BLOCKED taxonomy — exactly five classes, each with mandatory evidence.** No sixth class, no "other":

| Class | Required evidence |
|---|---|
| `NEEDS-CREDENTIALS` | env var name + least-privilege scope + Environment/reference path (never a value) |
| `NEEDS-TENANT` | vendor + the specific console surface required |
| `VENDOR-REMOVED` | fetched URL + quoted removal sentence |
| `UPSTREAM-DOC-GONE` | 404 **from a certified honest-404 host** + documented replacement search |
| `FETCHER-HOSTILE-HOST` | host + `link-host-policy.yml` behavior key + real-browser result |

**`VENDOR-REMOVED` is never terminal for the guide** — only for the validation. It opens an `update-hth-guide` task, because a guide asserting a nonexistent setting is exactly that skill's job. Say so, or agents file it and walk away.

**(d) Anti-suppression — enumerated forbidden moves.** A general "don't cheat" instruction reliably fails:

> A finding is never closed by: deleting the offending pack file; adding a path to any exclusion list; removing `**Profile Level:**` from a real control; widening a shellcheck exclusion beyond the single named code; adding an `HTH Pack Directive` to a file whose syntax error is real; changing a pack's `mode:` declaration to dodge check 14; disabling the 1Password Agent Hook to get past a credential gate; bypassing Interceptor's sensitive-frontmost-app gate; downgrading a FAIL to a WARN in the script; or narrowing scope so the finding falls out of range. Each is a validation failure disguised as a fix. If you believe the check is wrong, file a finding against the check and leave the original FAIL open.

**(e) Anti-infinite-loop.** Three fix attempts per finding. On the third failure, classify: a BLOCKED class with evidence, or escalate as `NEEDS-DECISION` describing all three. Never a fourth.

> **BLOCKED is a legitimate terminal state; FAIL is not. A run ends with zero FAIL — not with zero findings.**

---

## §8 — shellcheck / `bash -n` strategy

Measured: 77 findings at `-S warning` across 49 files.

| Code | n | Decision | Why |
|---|---|---|---|
| `SC1083` | 16 | **Exclude** | systematic false positive — gh-CLI literal `/orgs/{org}` |
| `SC2034` | 30 | **Exclude** | excerpt markers extract *subsets*; a var used outside the region reads unused |
| `SC1090/1091` | 2 | **Exclude** | `source "$(dirname "$0")/common.sh"` is the mandated idiom across 18 libs |
| `SC2148` | 2 | **FIX — do not exclude** | this *is* defect 6a |
| `SC1072/1073/…` | 14 | **Do not exclude** | parse errors from the 4 doc-snippets; handled by the directive |
| `SC2046/2155/2128/…` | 13 | **Keep. Fix them.** | genuine, cheap, exactly the loop's work |

**New convention — the doc-snippet directive.** A path allowlist rots; an in-file directive reusing the existing `HTH …:` marker family reads as native:

```bash
# HTH Pack Directive: doc-snippet — contains <digest> placeholders; not directly executable
```

**The directive is itself validated**, which stops it becoming a suppression hatch: once, in the first 10 lines · must carry a reason after the em dash · the file must contain a `<placeholder>` token *or* the reason must name a non-placeholder cause (a directive on a cleanly-parsing file is a FAIL — unnecessary suppression) · directive'd files remain subject to marker/shebang/ext/collision/contract checks · **the corpus-wide directive count prints every run.** It is 4 today; growth is visible, which is the social control.

---

## §9 — Sequencing

| PR | Contents | Effort | Catches |
|---|---|---|---|
| **1** | `validate-packs.sh` (14 checks) + `make validate-packs` + `.shellcheckrc` + `.gitignore` + `SKILL.md` + 5 routing updates | ~1.5d | **defects 1,2,3,4,6,7,8 — 7 of 8 — offline, in seconds** + contract coverage baseline |
| **2** | Fix what PR1 surfaces (its own first run produces the ledger) | ~1d | — |
| **3** | Wire `lint: lint-content validate-packs` + CI job | ~1h | regressions forever |
| **4** | Backfill `HTH Pack Contract: v1` headers across 1,128 packs; flip check 13 WARN→FAIL | ~2d | the OCEAN join at pack level |
| **5** | `validate-links.sh` + `link-host-policy.yml` + check 12 + weekly `link-check.yml` | ~1.5d | **defect 5** + rot across ~2,215 URLs |
| **6** | `validate-ocean.sh` (discovery, probe, `ocean build --validate`, migration report) | ~1d | cross-repo drift |
| **7** | Tier 3: 1Password Environment + Agent Hook setup, `op run` execution, Interceptor ClickOps, lockout pre-flight | ~1.5d | live truth |

**The first PR stops after PR1**, landing the validator **unwired** so its first run produces the defect ledger as a reviewable artifact ("8 real defects, found in 6 seconds") before anyone argues CI policy. Tradeoff accepted: one cycle with an unenforced validator, mitigated by PR3 immediately after — preferable to landing a red gate on `main`.

CI: `validate-packs` becomes a third parallel job in `test.yml` mirroring `lint-content` (python 3.12 + pyyaml). **`validate-links` gets a weekly cron workflow, not a PR gate** — 2,215 URLs against fetcher-hostile hosts is too flaky to block merges; PR-time link checking uses `--since`. `validate-ocean` never runs in CI (separate repo; always exit 3).

Deferred: `terraform validate` on 353 `.tf` (per-provider `terraform init` — expensive, low yield) · the `VERSIONS.md` gap in `verify-hth` Check 5 (belongs to that skill) · full `CONTRIBUTING.md` rewrite (PR1 adds one pointer line).

---

## Files to create

### `.claude/skills/validate-hth-guide/SKILL.md`

Flat single file, no supporting files — matches all four siblings. Target **78–82 lines / ~1,100 words**. Frontmatter: exactly `name` + `description`, house three-move shape (artifact+process → `USE WHEN` triggers → `NOT FOR` hand-offs to verify-hth / create-hth-guide / update-hth-guide / create-code-pack).

Body: `# Validate an HTH Guide` → orienting paragraph with `Companion standards:` and `../../../` links → six `## Phase N — {name} ({qualifier})` headings (em dash) → **bold leading keys** → each phase closes with `**Checkpoint:**` carrying its STOP/LOOP clause → terminal `## Gotchas` (7 bullets). **3 fenced bash blocks.**

- **Phase 0 — Scope and declare (before anything runs)** — subject + declarations: tenants, 1Password Environment + Agent Hook status, OCEAN path. Declaring nothing is valid → T0+T1. **Checkpoint:** a written scope line, or the literal `no tenants declared — Tier 0+1 only`.
- **Phase 1 — Corpus integrity (always, offline)** — `bash scripts/validate-packs.sh`
- **Phase 2 — Doc drift (always, networked)** — `bash scripts/validate-links.sh`
- **Phase 3 — OCEAN conformance (always; live if declared)** — `bash scripts/validate-ocean.sh`
- **Phase 4 — Live proof (only where declared)** — `op run --environment` pack execution + 1Password-mediated Interceptor ClickOps
- **Phase 5 — The fix→validate loop (until zero FAIL)** — §7

Closer: **Run the `verify-hth` skill** before committing any fix this loop produced.

### `scripts/validate-packs.sh` — Tier 0 workhorse

Structural clone of `scripts/validate-guides.sh`: bash + inline `python3 << 'PYEOF'` heredocs emitting `===SECTION===` blocks, same `fail()`/`warn()`/`pass()`, same counters, same cygpath/`PYTHONUTF8` shims, banner `═══ HTH Pack Validation ═══`, terminal `ALL TESTS PASSED`.

Fourteen checks: (1) `(section,type)` collisions · (2) control-YAML deprecation + anchor resolution · (3) filename↔id parity · (4) Sigma UUID uniqueness · (5) marker hygiene *(100% clean today — lock it in)* · (6) shebang · (7) `bash -n` with directive allowlist · (8) ext↔type table · (9) sync freshness *(strip `# Generated:`)* · (10) sync reachability · (11) include↔yml both directions · (12) host-policy ↔ SOURCES.md parity · **(13) dual-contract header presence + field validity (WARN in PR1)** · **(14) `mode:` declaration vs actual mutation verbs (FAIL on mismatch)**.

**Exit: `0` pass · `1` ≥1 FAIL · `2` a check could not run.** The `2` fixes the biggest existing gate gap — refuse to be green when unable to check.

### `scripts/validate-links.sh` + `scripts/link-host-policy.yml` — Tier 1

`link-host-policy.yml` is a machine-readable projection of SOURCES.md Rule 1:

```yaml
hosts:
  docs.cyberark.com: { behavior: fetcher-404-trap, verdict_on_404: BLOCKED }
  help.zscaler.com:  { behavior: spa-200-always, verify_via: sitemap }
  help.bamboohr.com: { behavior: spa-identical-body, verdict: UNVERIFIABLE }
  media.defense.gov: { behavior: 403-to-fetchers, verify_via: real-browser }
  mailchimp.com:     { behavior: honest-404 }
default:             { behavior: honest-404-assumed, verdict_on_404: FAIL }
```

Encodes SOURCES.md verbatim: *"A 404 from a documentation host that is plainly still in business is a verification failure, not a finding."* Non-honest-404 hosts → `BLOCKED / FETCHER-HOSTILE-HOST`. Concurrency 8, per-host serialized, `--since <git-rev>` / `--guide <slug>` so the default run is diff-scoped. Drift binds at **guide level + `doc_links.yml`**, never per-control (github.md §1.1 has zero in-control citations).

### `scripts/validate-ocean.sh` — Tier 2/3 bridge

Discovery: `$OCEAN_REPO` → sibling `../OCEAN` → `~/Code/grcengineering/OCEAN` → **prompt** → **offer to clone**. Binary: `target/release/ocean` → `target/debug/ocean` → `command -v ocean`, then **probe** `"$OCEAN_BIN" build --help` (the PATH binary fails this). Exit `0` / `1` FAIL / `3` OCEAN-ABSENT.

### Supporting

`.shellcheckrc` (§8) · `.1password/environments.toml` (mount names only, no secrets) · `.gitignore` += `.hth-validation/` — **non-negotiable before any credentialed tier ships**

---

## Verification

A clean-tree first run must produce **exactly** the eight defects:

1. `FAIL: 4 (section,type) collisions` naming all four
2. `FAIL: 7 control YAMLs` + `MIGRATION-REQUIRED: 74`
3. `FAIL: 5 … additionalProperties 'manual'` + `WARN: 'note' in 29 files`
4. `FAIL: duplicate sigma id c3d4e5f6-…` naming both files
5. `FAIL: 6 guide_url anchors unresolved`
6. `FAIL: 2 .sh without shebang` + `FAIL: 4 fail bash -n (0 carry HTH Pack Directive)`
7. `FAIL: 30 files violate the AGENTS.md type table`
8. `FAIL: 5 marked pack files unreachable by sync`

**Negative criteria** — the run must NOT: FAIL on `docs.cyberark.com` 404s (→ `BLOCKED / FETCHER-HOSTILE-HOST`) · PASS a `help.zscaler.com`/`help.bamboohr.com` URL on HTTP 200 alone · report a stale-yml diff caused only by `# Generated:` · flag the 16 `SC1083` or 30 `SC2034` findings · exit 0 when `python3` is absent (must exit 2) · **emit any resolved secret value into stdout, the ledger, or the transcript.**

**Contract criteria (§4):** a pack declaring `mode: read-only` containing a mutation verb → FAIL · a pack whose `profile:` disagrees with the guide → FAIL · **every pack still runs standalone with plain env vars and no OCEAN present** (spot-check 5 across api/cli/sdk/terraform/config) · the same pack is introspectable by contract header.

**Credential criteria (§5):** `op run --environment` executes a read-only pack with **no value in the transcript** · the mounted `.env` is a FIFO, absent from `git status` and from disk after the run · **the Agent Hook blocks execution** when a required mount is missing, and the agent surfaces the fix instructions rather than routing around it · a missing credential yields `BLOCKED / NEEDS-CREDENTIALS` naming var + scope + Environment path · ClickOps sign-in goes through the 1Password for Claude connector, never a typed password · Agentic Autofill is not used (Browserbase-only) · **no evidence artifact contains a token, cookie, tenant id, or member email** — grep `.hth-validation/` for the org slug and any `Bearer`/`token=` pattern before the run closes · a Tier 3 walkthrough leaves nothing recorded under `docs/` or staged in git.

**Loop criteria** — what separates this from a linter: given a seeded fixable defect, the agent fixes it, **re-runs the same command**, and pastes the new terminal line as closing evidence (reporting and stopping is a failed acceptance test) · given `NEEDS-CREDENTIALS`, produces `BLOCKED` with var + scope, does not attempt a fourth fix, mark it PASS, or delete the check.

**Manual smoke:** `make validate-packs` on a clean tree → exit 1 with the eight findings · add a fifth collision → count becomes 5 · bare `HTH Pack Directive` with no reason → FAIL · `OCEAN_REPO=/nonexistent bash scripts/validate-ocean.sh` → exit 3, renders `SKIPPED`, never `FAIL` · disable the Environment mount → Agent Hook blocks the next shell command.

---

## Files touched

**New:** `.claude/skills/validate-hth-guide/SKILL.md` · `scripts/validate-packs.sh` · `scripts/validate-links.sh` · `scripts/link-host-policy.yml` · `scripts/validate-ocean.sh` · `.shellcheckrc` · `.1password/environments.toml` · `.github/workflows/link-check.yml` (PR5)

**Modified:** `Makefile` (+4 targets, `.PHONY`) · `.gitignore` (+`.hth-validation/`) · `.github/workflows/test.yml` (+1 job, PR3) · `AGENTS.md:24,31` ("Four"→"Five", +row, + pack-contract section) · `CLAUDE.md:91` (+row) · `README.md:163,174,181` · `CONTRIBUTING.md:155-161` (+pointer) · `.claude/skills/verify-hth/SKILL.md` Gotchas (+reverse hand-off) · `.claude/skills/create-code-pack/SKILL.md` (Phase 3 gains the contract header) · **1,128 pack files** (contract header backfill, PR4 — comment-only, zero behavior change)

**Reused, not reinvented:** `scripts/validate-guides.sh` (structural template) · **1Password Environments + `op run --environment`** (shell credentials) · **1Password Agent Hook** (pre-execution enforcement) · **1Password Shell Plugins** (CLI biometric auth) · **1Password for Claude** (ClickOps sign-in, exception path only) · **Interceptor's frontmost-app gate, recording auto-masking, and real-session model** (browser security model — cited, not restated; §5.5) · `$OCEAN_REPO/scripts/ocean-creds-from-keychain.sh` (fallback) · `ocean build --validate` (check schema) · `ocean harden` dry-run default + `ocean test` confirm-gate (safety model) · `packs/schema/control.schema.json` (first-ever consumer, for the deprecation report)

**Deliberately NOT written** (already well-defined elsewhere — duplicating would create drift): browser automation recipes of any kind (Interceptor's `VerifyDeploy` / `TestForm` / `RecordFlow` workflows) · password-field input technique · screenshot/motion verification (`ScrubFlow`) · 1Password setup instructions (link to `1password.dev/get-started/secure-ai-access`) · OCEAN module authoring (OCEAN's own `CONTRIBUTING-CHECKS.md`).
