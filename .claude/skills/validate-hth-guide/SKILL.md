---
name: validate-hth-guide
description: Actively validate that a How to Harden guide's ClickOps instructions, Code Packs, and OCEAN scanning/remediation actually work — a tiered fix→revalidate loop that runs until zero fixable failures, reporting VERIFIED-LIVE separately from DRIFT-CHECKED-ONLY and never conflating them, then adding the `ai-validated` status to the guide's maturity set when it earned it. USE WHEN validating a guide end-to-end, adding ai-validated to a guide, proving ClickOps steps against a live console, executing Code Packs against a real tenant, checking OCEAN control conformance, auditing pack corpus integrity, or diagnosing why hardening automation fails. NOT FOR pre-commit structural checks (use verify-hth), authoring guides (use create-hth-guide / update-hth-guide), or pack code (use create-code-pack).
---

# Validate an HTH Guide

A tiered validate-fix-revalidate process that asks what no other skill asks: **is this guidance true against the world, and does the code actually run?** `verify-hth` answers "does the repo render correctly" — structural, offline, seconds. This answers "does it work" — semantic, networked, credentialed, iterative. It is also the **only** thing in this repo permitted to add `ai-validated` to a guide's maturity set (Phase 6); every other path leaves a guide at `["ai-drafted"]`. Companion standards: [SOURCES.md](../../../SOURCES.md) (host-behavior rules), [AGENTS.md](../../../AGENTS.md) (pack type table), [verify-hth](../verify-hth/SKILL.md) (the boundary).

**Verdicts.** Six terminal states, and two invariants that make the report honest: `PASS` · `VERIFIED-LIVE` (observed against a real tenant) · `DRIFT-CHECKED-ONLY` (doc-level only, no tenant touched) · `SKIPPED` (precondition absent) · `BLOCKED` (failed, legitimately unfixable, with evidence) · `FAIL` (failed, fixable). **SKIPPED is never PASS** — a run is clean only when FAIL is 0 *and* every SKIPPED names its missing precondition. **VERIFIED-LIVE and DRIFT-CHECKED-ONLY never merge into one number.** That separation is not bookkeeping — Phase 6 spends `VERIFIED-LIVE` and only `VERIFIED-LIVE` to buy the `ai-validated` status, so collapsing the two mints the status out of nothing.

## Phase 0 — Scope and declare (before anything runs)

1. **Name the subject:** one guide, one vendor, or the whole corpus.
2. **Get three declarations from the operator:** which vendors have a live **tenant**; whether a **1Password Environment + Agent Hook** is configured (§Credentials); where **OCEAN** lives. Declaring nothing is valid and yields a Tier 0+1 run.
3. **Never infer a tenant.** An unverified assumption that a tenant exists produces a fake VERIFIED-LIVE, which is worse than a SKIPPED.
4. **Checkpoint:** a written scope line naming subject + declared tenants + credential source + OCEAN path — or the literal string `no tenants declared — Tier 0+1 only`.

## Phase 1 — Corpus integrity (always, offline, no credentials)

```bash
bash scripts/validate-packs.sh   # or: make validate-packs
```

1. Fourteen checks over the whole pack corpus: `(section,type)` collisions (the sync drops a file **silently**), control-YAML conformance, `guide_url` anchor resolution, Sigma id uniqueness, marker hygiene, shebangs, `bash -n`, the extension↔type table, generated-YAML freshness, sync reachability, include↔yml integrity both directions, and pack-contract coverage.
2. **Exit `2` means a check could not run** (missing `python3`/`pyyaml`) — that is not a pass. Install the dependency and re-run.
3. **Checkpoint:** every FAIL is in the ledger with a stable ID. Zero FAIL here before spending network or credentials on Phase 2.

## Phase 2 — Doc drift (always, networked, no credentials)

1. Re-fetch each cited Tier 1 doc and confirm the guide's transcribed console path still appears. Bind drift at **guide + `doc_links.yml`** level, never per-control — most controls carry no in-control citation.
2. **A 404 from a documentation host that is plainly still in business is a verification failure, not a finding** (SOURCES.md Rule 1). Roughly 30 hosts lie about status: SPA-200-always, 403-to-fetchers, and `docs.cyberark.com`, which 404s to every fetcher on every path including root. Only five hosts are certified honest-404.
3. Results are `DRIFT-CHECKED-ONLY` — never PASS, never VERIFIED-LIVE.
4. **Checkpoint:** each cited URL carries a verdict; every fetcher-hostile host is `BLOCKED`, not a link-rot FAIL.

## Phase 3 — OCEAN conformance (schema always; live only if declared)

1. **Find OCEAN in this order:** `$OCEAN_REPO` → sibling `../OCEAN` → `~/Code/grcengineering/OCEAN` → **prompt the operator for the path** → **offer to clone it**. Absent after all five → `SKIPPED / OCEAN-ABSENT`, never FAIL.
2. **Probe capability, do not trust the version.** Resolve the binary repo-first (`target/release/ocean`, then `target/debug`, then PATH) and confirm with `ocean build --help` — a PATH binary can be several subcommands out of date.
3. Validate OCEAN's checks (`ocean build --validate --source "$OCEAN_REPO/checks"`) and cross-check `ocean modules validate` credential requirements against each pack's declared `requires:`.
4. HTH's `packs/*/controls/*.yaml` are a **deprecated format** — report them `MIGRATION-REQUIRED` toward OCEAN's canonical schema. Do not patch them in place, and **never renumber an HTH control** to match: that breaks pack includes and inbound anchors.
5. **Checkpoint:** OCEAN located (or explicitly SKIPPED with reason), checks validate, migration debt counted.

## Phase 4 — Live proof (only where a tenant was declared)

1. **Code Packs** run through injection, never plaintext: `op run --environment <id> -- bash packs/<vendor>/<type>/<pack>.sh`. A pack declaring `mode: mutating` is `SKIPPED / MUTATING-PACK-NOT-EXECUTED` unless the operator names that exact file.
2. **ClickOps** runs through the Interceptor skill in the operator's real browser. Because that session is already authenticated, there is usually **no login step**; invoke 1Password only at an actual sign-in wall. Interceptor's own gates already handle the rest — do not re-specify them, and never bypass them.
3. **Lockout pre-flight, hard refusal.** Before any mutating pack or `reversible`/`destructive` tester, refuse outright if the operation could change auth/SSO/MFA config so future authentication fails, remove the last admin or the credential in use, delete a tenant/org/workspace, alter IP allowlisting to exclude the operator, or is irreversible with no restore path. **Confirmation does not unlock this** — `BLOCKED / LOCKOUT-RISK`. Sole exemption: an independent backup access path proven to work *before* the operation, in the same run.
4. **`ocean harden` runs dry-run only.** `--apply` is never issued by this skill; remediation is the operator's decision.
5. **Checkpoint:** each live result is `VERIFIED-LIVE` with evidence, or SKIPPED/BLOCKED with a named reason. No evidence artifact contains a token, cookie, tenant id, or member email.

## Phase 5 — The fix→validate loop (runs until zero FAIL)

1. **Re-validation is a command, not a claim.** A finding closes only when the same command that produced it is re-run and no longer produces it — paste that re-run's terminal line as closing evidence. "Fixed" without a re-run line is an open finding with a claim attached.
2. **Three attempts per finding.** On the third failure, stop editing and classify: a BLOCKED class with its required evidence, or escalate as `NEEDS-DECISION` describing all three attempts. Never a fourth.
3. **BLOCKED classes — exactly five, each with mandatory evidence:** `NEEDS-CREDENTIALS` (variable name + least-privilege scope + reference path, never a value) · `NEEDS-TENANT` (vendor + console surface) · `VENDOR-REMOVED` (fetched URL + quoted removal sentence) · `UPSTREAM-DOC-GONE` (404 from a certified honest-404 host + documented replacement search) · `FETCHER-HOSTILE-HOST` (host + behavior + real-browser result). No sixth class, no "other".
4. **`VENDOR-REMOVED` is terminal for the validation, never for the guide** — a guide asserting a setting the vendor deleted is exactly what `update-hth-guide` exists to correct. Open that task; do not file and walk away.
5. **A finding is never closed by:** deleting the offending pack; adding a path to an exclusion list; removing `**Profile Level:**` from a real control; widening a shellcheck exclusion beyond the single named code; adding an `HTH Pack Directive` to a file whose syntax error is real; changing a pack's `mode:` to dodge the check; disabling the 1Password Agent Hook or Interceptor's frontmost-app gate; downgrading a FAIL to a WARN; or narrowing scope until the finding falls out of range. Each is a validation failure disguised as a fix — if the check itself is wrong, file a finding **against the check** and leave the original FAIL open.
6. **Checkpoint:** `FAIL = 0`. **BLOCKED is a legitimate terminal state; FAIL is not. A run ends with zero FAIL — not with zero findings.**

**Run the `verify-hth` skill** before committing any fix this loop produced.

## Phase 6 — Add `ai-validated` (terminal; nothing else may write this status)

`ai-validated` asserts that **an AI agent exercised this guidance against a real tenant or console and the guidance survived that contact** — and, just as loudly, that **no human practitioner has reviewed it**. Maturity is a **matrix, not a ladder**: three stages (`drafted` → `reviewed` → `validated`) × two agents (`ai` = a machine, `ni` = natural intelligence, i.e. a person), and the six statuses are **not mutually exclusive**, so `maturity` is a list and this phase **adds a member to a set** rather than replacing a value. The full definition lives in [VERSIONS.md](../../../VERSIONS.md#maturity-statuses--the-matrix); do not restate it in the guide. This run is the only place the evidence for the `ai-validated` claim exists, which is why this is the only place allowed to write it.

1. **The gate has two halves.** Promote when **`FAIL = 0`** (Phase 5's checkpoint) **and at least one ledger result is `VERIFIED-LIVE`**. A clean Tier 0+1 run — no tenant declared, everything `DRIFT-CHECKED-ONLY` — satisfies the first half and promotes nothing. Zero-FAIL says the run is finished; live contact is what the status actually asserts. Missing either half → the guide keeps the maturity set it arrived with, and say so in the report rather than leaving the status unmentioned.
2. **Stamp the guide — add, never replace.** `maturity` is a list, so append: `["ai-drafted"]` becomes `["ai-drafted", "ai-validated"]`. Never overwrite the set with a bare `"ai-validated"`, and never drop the `*-drafted` status the guide already holds — Test 5b rejects a scalar outright and rejects a `*-validated` claim that does not rest on a `*-drafted` one, because nothing can be validated before it exists. Canonical order is stage ascending, `ai` before `ni`. A maturity change is **not** a version bump — leave `version` alone unless this run also changed content; re-stamp `last_updated` and the new changelog row to `date +%F` (AGENTS.md Rule 5). Test 5b enforces the shape and the spelling; it cannot enforce the truth.
3. **The changelog row names the run**, so the claim is auditable instead of asserted: date · version · the **full maturity set** as of that row, ` · `-joined (`ai-drafted · ai-validated` — the set widening, not one value replacing another) · what was exercised, against what, and how many controls came back live · author. A promotion row without that phrase is the same defect as a badge without `evidence=` — a mood where a fact belongs.
4. **Mark exactly the VERIFIED-LIVE surfaces — the unit is the surface, not the control.** Append the mark to the implementation heading whose artifact you actually exercised, on that same line:

   `#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="{what was actually exercised}" date="{YYYY-MM-DD}" %}`

   `#### Code Implementation{% include status-mark.html status="ai-validated" evidence="{what was actually exercised}" date="{YYYY-MM-DD}" %}`

   **Decompose the ledger per surface before stamping.** Walking a console and executing a pack are two different acts producing two different claims, and a single per-control badge averaged them into one — which is how buildkite `3.1` (Terraform applied to a live org, console never walked) and `1.1` (console-only, no code run) ended up wearing the same badge. Mark ClickOps when the console path was observed or corrected against the live UI; mark Code when the pack was actually **run**. A pack that only `validate`d, or that ran and hit a plan gate without applying, is not a Code mark — buildkite `1.2` is the worked example: its Terraform apply surfaced the plan gate, so it carries a ClickOps mark and no Code mark.

   A control may end with one mark, both, or neither, and **neither is a legitimate outcome**. Never add a mark to make a control look symmetrical: absence is the signal that makes presence worth anything.

   `evidence` is required in practice — it is what makes the mark falsifiable, so write what was run for *that surface* ("console path re-read on the live org"; "read-only API audit pack executed against a live tenant"), never a restatement of the control title. **The mark is icon only and must render no text node**: anything textual inside an `h4` lands in kramdown's anchor and in the string `cheat-sheet.html` matches against `'description'`/`'rationale'`, so a label silently breaks in-guide links and blanks cheat-sheet cells. The include's own comment block is the reference — read it before stamping the first mark.
5. **Forbidden marks — no exceptions, and each wrong for its own reason:**
   - `SKIPPED` — a precondition was absent, so nothing was exercised. The badge would assert an act that did not happen.
   - `BLOCKED` — the attempt was made and did not succeed. The badge would invert the result.
   - `DRIFT-CHECKED-ONLY` — this is the tempting one. A cited URL resolved 200 and the console path still appears on the vendor's page, so the control *reads* proven. No tenant was touched. Badging it collapses exactly the distinction this skill exists to keep, and does it on the control where a reader is least able to catch it.
   - Controls that inherit confidence from a neighbour — "2.2 was verified live and 2.3 is the same screen" is a guess about the console, not an observation of it.
6. **A partial promotion is the normal outcome, and it is honest.** A guide gaining `ai-validated` with 11 of 22 controls marked says precisely that: eleven requirements were exercised live, eleven were not, and the reader can see which is which. Do **not** mark the remainder to make the page look finished, and do not withhold the page-level status because coverage is partial. The page status is the sum of the marks; that is why they render the same glyph.
7. **Demote on contradiction.** `ai-validated` is a claim about the world, so it expires when the world moves. A later run (or an `update-hth-guide` currency pass) that finds a console path moved or a setting removed **removes** `ai-validated` from the set — back to `["ai-drafted"]` — and strips the marks that finding invalidated. Leaving a stale status standing is worse than never having added it.
8. **Never write any `ni-*` status, and never imply one is owed to this run.** `ni-drafted`, `ni-reviewed`, and `ni-validated` describe acts by a person; they are not machine observations and no run produces evidence for them. An agent may not set them, may not recommend a maintainer set them on the strength of this run, and may not describe `ai-validated` in the report as a partial, provisional, or equivalent `ni-reviewed`. The two live on different axes — `ai-validated` is not "most of the way to reviewed", it is a different claim entirely, and the honest sentence is that this guide still has **no** human status. As of now **no HTH guide holds any `ni-*` status at all**, so a report implying otherwise is inventing human review that does not exist anywhere in the corpus.
9. **Checkpoint — four commands, not four claims:**

```bash
grep -E '^maturity:' docs/_guides/{slug}.md                  # a LIST containing BOTH *-drafted and ai-validated
grep -c 'include status-mark.html' docs/_guides/{slug}.md   # == per-surface VERIFIED-LIVE count in the ledger
grep -cE '^ *```' docs/_guides/{slug}.md                    # still 0 (AGENTS.md Rule 2)
bash scripts/validate-guides.sh                             # ALL TESTS PASSED
```

   Paste the output. The badge count and the ledger's `VERIFIED-LIVE` count must be the same number — if they differ, one of them is lying and the guide is not promotable until you know which.


## Credentials — 1Password-first, zero plaintext in context

**The agent may read and reason about references and variable names; it must never cause a resolved secret value to enter its context.** No `op read` into an echoed variable, no `op item get --reveal`, no token pasted into a prompt. If a value would become visible, stop and re-route through injection.

Shell execution uses a **1Password Environment** (`op run --environment`), whose locally-mounted `.env` is a FIFO — not on disk, not git-trackable, available only at the moment of access (Mac/Linux; Windows uses a service account instead). The **1Password Agent Hook** validates those mounts *before* the agent runs shell commands and blocks execution when they are missing. Browser sign-in uses the **1Password for Claude** connector, which fills the page directly so the password and any one-time code never reach the model. Fallbacks, in order: an already-authenticated first-party CLI (`gh auth token`) → a service account → interactive `read -rs` into a process-lifetime variable. Never a repo file, a CLI argument, or a committed `.env`.

## Gotchas

- **The `ocean` on your PATH may be stale.** A PATH binary can silently lack `build` while the repo-built one has it — resolve repo-first and probe the subcommand, never the version string.
- **SKIPPED is not PASS, and DRIFT-CHECKED-ONLY is not VERIFIED-LIVE.** Collapsing either distinction is how a validation report starts lying. Print them as separate counts.
- **`sync-packs-to-data.sh` exits 0 even when a vendor fails**, and skips its only YAML check when `python3` is absent. Never treat its exit code as a gate — grep its output for `✗`.
- **Generated pack YAML carries a `# Generated:` timestamp**, so a naive regenerate-and-diff reports every file as stale. Strip that line from both sides before comparing.
- **Most packs mutate and almost none have a dry-run.** Default-deny execution; require the operator to name a mutating pack by path before it runs.
- **`.jsonc` packs are not parseable JSON** by design — multiple root objects plus `//` comments. Never run a JSON parser over them.
- **The mark is the status, retail.** `docs/_includes/status-mark.html` renders the same glyph as the page banner on purpose, so a mark on a surface nobody exercised does not read as a small slip — it reads to the viewer as the page-level claim, applied to that artifact. Stamp from the ledger, one mark per `VERIFIED-LIVE` surface, never from memory of what the run "basically covered".
- **`maturity` is a set, and sets are easy to clobber.** The failure mode is writing `maturity: "ai-validated"` — a scalar that both drops the guide's `ai-drafted` claim and breaks Test 5b. Read the existing list, append, write it back.
- **Evidence from a live tenant is an exfiltration surface.** Interceptor masks password fields; it does not mask tokens in URLs, cookies in a network log, tenant ids, or customer data on screen. Keep everything in gitignored `.hth-validation/`, record request *shape* rather than transcripts, and prefer the accessibility tree over pixels when the assertion is textual.
