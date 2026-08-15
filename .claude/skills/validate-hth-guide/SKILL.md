---
name: validate-hth-guide
description: Actively validate that a How to Harden guide's ClickOps instructions, Code Packs, and OCEAN scanning/remediation actually work — a tiered fix→revalidate loop that runs until zero fixable failures, reporting VERIFIED-LIVE separately from DRIFT-CHECKED-ONLY and never conflating them. USE WHEN validating a guide end-to-end, proving ClickOps steps against a live console, executing Code Packs against a real tenant, checking OCEAN control conformance, auditing pack corpus integrity, or diagnosing why hardening automation fails. NOT FOR pre-commit structural checks (use verify-hth), authoring guides (use create-hth-guide / update-hth-guide), or pack code (use create-code-pack).
---

# Validate an HTH Guide

A tiered validate-fix-revalidate process that asks what no other skill asks: **is this guidance true against the world, and does the code actually run?** `verify-hth` answers "does the repo render correctly" — structural, offline, seconds. This answers "does it work" — semantic, networked, credentialed, iterative. Companion standards: [SOURCES.md](../../../SOURCES.md) (host-behavior rules), [AGENTS.md](../../../AGENTS.md) (pack type table), [verify-hth](../verify-hth/SKILL.md) (the boundary).

**Verdicts.** Six terminal states, and two invariants that make the report honest: `PASS` · `VERIFIED-LIVE` (observed against a real tenant) · `DRIFT-CHECKED-ONLY` (doc-level only, no tenant touched) · `SKIPPED` (precondition absent) · `BLOCKED` (failed, legitimately unfixable, with evidence) · `FAIL` (failed, fixable). **SKIPPED is never PASS** — a run is clean only when FAIL is 0 *and* every SKIPPED names its missing precondition. **VERIFIED-LIVE and DRIFT-CHECKED-ONLY never merge into one number.**

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
- **Evidence from a live tenant is an exfiltration surface.** Interceptor masks password fields; it does not mask tokens in URLs, cookies in a network log, tenant ids, or customer data on screen. Keep everything in gitignored `.hth-validation/`, record request *shape* rather than transcripts, and prefer the accessibility tree over pixels when the assertion is textual.
