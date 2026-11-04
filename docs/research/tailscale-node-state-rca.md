# RCA: omitted Tailscale client identity-state protection

Investigation date: **2026-11-04**. Subject: the initial Tailscale guide at commit `b15058542be25738013798e42cb78a10e27cbbab`, merged by [PR #133](https://github.com/grcengineering/how-to-harden/pull/133). This change improves authoring workflows; it does not add a Tailscale control, change a pack, exercise a tenant or award a maturity status.

## Finding and causal chain

The authoring run selected a control inventory without completing an independent source-to-control reconciliation. Its later source/automation matrix was derived from those selected controls. The verification battery then checked that authored corpus. A missing candidate never entered the denominator, so good pack, rendering and CI results could not expose it.

The existing creation skill already required product-area research and agent/daemon configuration references. The authoring run fell short of that instruction. The improvement is to make the discovery boundary, candidates and unresolved decisions reviewable, rather than merely repeat “research more.”

## Evidence observed

| Evidence | Observation | What it establishes |
|---|---|---|
| [Original guide](https://github.com/grcengineering/how-to-harden/blob/b15058542be25738013798e42cb78a10e27cbbab/docs/_guides/tailscale.md) | Eighteen controls cover expiry, admission, policy, posture and other topics, but none covers protection of the locally stored Tailscale identity state. | An actual content omission, distinct from node-key expiry or Tailnet Lock. |
| [Published source and interface inventory](https://github.com/grcengineering/how-to-harden/blob/b15058542be25738013798e42cb78a10e27cbbab/docs/research/tailscale-source-evidence.md) | Rows are organized by those eighteen controls. Native configuration focuses on tailnet policy; CLI evidence names the interactive client, Funnel and Lock. The posture reference is cited as checked, but no state-protection candidate or exclusion is recorded. | No independently enumerated recommendation/disposition ledger is present. A complete provider index is not a complete product-security inventory. |
| Retained `research/fetch-sources.py` and `sources/ledger.json` | The initial bulk plan has 35 URLs: 15 successes and 20 errors. It does not include the feature index, dedicated state-protection page, daemon reference or system-policy reference. Best-practices and posture-page bulk fetches failed; the client CLI fetch succeeded. | The preserved fetch plan missed important entrypoints. The failed bulk attempts do not establish that later browser/web fallbacks never read those pages. |
| Original saved client-CLI HTML | Its anchors include `/docs/reference/tailscaled` and `/docs/features/tailscale-system-policies`. The text extractor preserved text but did not build an outgoing-link inventory; the raw HTML retained the links. | Relevant adjacent documentation was discoverable from a successfully captured source. Neither target appears in the preserved bulk plan. |
| Retained `research/author-guide.py` | A manually assembled `CONTROLS` list starts at line 6 and contains the eighteen selected controls. It has no state-protection candidate. Later manual edits mean this surviving intermediate script is not a byte-exact reproduction of the final guide. | The initial inventory was selected before the final source matrix; it was not extracted from an independent recommendation ledger. |
| Retained `research/finish-metadata.py` | Lines 9–17 parse controls from the guide; lines 110–115 emit interface/source rows for those controls. Source “verified” dates are parsed from authored citation lines, not reconciled with fetch receipts. | The matrix could restate support for selected controls but could not detect a security feature absent from the guide. Its generated date labels alone are not retrieval proof. |
| [Local verification report](https://github.com/grcengineering/how-to-harden/blob/b15058542be25738013798e42cb78a10e27cbbab/docs/research/tailscale-validation.md) and tests | Guide lint, mock transport tests, source-pack checks, browser counts and CI passed within their stated scope. The report preserved `ai-drafted` and claimed no live validation. | Those checks did not compare a source-derived candidate set with the guide. Their success was not evidence of exhaustive discovery. |

The original scratch scripts and bulk receipts are retained in the task workspace, not maintained as repository tooling. Their inspected SHA-256 values identify the evidence copies:

| Artifact | SHA-256 |
|---|---|
| `fetch-sources.py` | `9a45cff2af8e6f53cdead07de7a0a97dd6039baf8a4e4bd605c2b4d0743b1148` |
| `author-guide.py` | `8e63633716b2c546fd3222e9fe44728d140404c226833875a06b4d854ba43daf` |
| `finish-metadata.py` | `20599798be275e5e82c060c0c1519663963944760f618eb8a8078f51a9704799` |
| `sources/ledger.json` | `31f3b28512ec0268c162220ad917a7ca4de55492e68300b907deded8cb3fcfc3` |

## Public documentation cross-check

The [feature documentation](https://tailscale.com/docs/features/secure-node-state-storage) describes protection against copying a device's identity state, platform/version conditions, daemon/system-policy configuration, a posture signal and the absence of a graphical enablement setting. The [posture reference](https://tailscale.com/docs/features/device-posture/postures-and-attributes) lists `node:tsStateEncrypted`; the [daemon reference](https://tailscale.com/docs/reference/tailscaled) documents `--encrypt-state`. These are product-controlled identity protections, even though their implementation can use OS facilities or a TPM.

This was not a newly introduced feature after drafting: the vendor's [January 23, 2026 update](https://tailscale.com/blog/january-26-product-update) describes Windows/Linux returning to opt-in in 1.92.5. The current [feature index](https://tailscale.com/docs/features) links the topic. A [July 2026 vendor incident response](https://tailscale.com/blog/hugging-face-intrusion) also points managed fleets toward this protection; it is a discovery lead, not a substitute for configuration documentation or proof the control would have prevented that incident.

The [general security best-practices page](https://tailscale.com/docs/reference/best-practices/security) fetched for this investigation does not mention the state-protection feature. It would be inaccurate to say the omission was simply a skipped heading on that page. Its current contents and “last validated” label also do not reconstruct every page seen during the original run.

## Instruction gaps and confidence

| Gap in the pre-change workflow | Assessment |
|---|---|
| Creation encouraged broad research, but its closure emphasized the chosen control list and automation counts. No source-first disposition artifact was required. | **Direct process cause:** discovery and validation shared the guide's selected universe. The author's incomplete execution remains part of the cause. |
| Creation Phase 2 requested an exact console path for each candidate; Phase 4 required console steps. | **Confirmed instruction defect; causal contribution is an inference.** This can screen out real CLI/config-only controls. No retained artifact explicitly says this was why the feature was excluded. |
| Pack Phase 1 said “No verified doc” becomes “none, verified.” | **Confirmed evidence-status defect.** Unavailable or unresearched documentation cannot prove absence. The records do not show this exact sentence consciously determining the missing control. |
| The scope examples excluded infrastructure encryption without distinguishing protection of a product's own identity material. | **Ambiguity, not a recorded exclusion.** No specific evidence-backed decision excluded this feature as generic OS hardening. |
| Update research emphasized existing claims and changes since `last_updated`, with a zero-findings stop. | **Confirmed follow-up risk, not the cause of initial creation.** An older omission can survive a subsequent currency pass even if every written claim remains current. |
| Structural and runtime tests operated on authored controls/packs. | **Detection gap in the overall workflow.** The tests did not malfunction; they were never source-coverage tests. |

The complete original browsing/attention history is not preserved by the bulk ledger. It cannot prove whether the author never saw a clue, saw it without following it, or considered it and failed to record a decision. There is no evidence for a deliberate, justified exclusion. The high-confidence conclusion is premature closure of discovery and missing independent coverage reconciliation, rather than a claim about hidden model reasoning.

## Implemented prevention

- [Shared source-discovery workflow](../../.claude/skills/_shared/source-discovery.md): separate management planes, security-relevant linked-source follow-up, source-first candidates and covered/excluded/gap/unverified dispositions. Grouping remains allowed; no arbitrary one-setting/one-control requirement is introduced.
- Creation/update skills now reconcile that ledger before closure. Full updates seek older omissions independently of dates; narrowly scoped fixes remain narrow. Control-count guidance cannot justify dropping a relevant candidate.
- Pack research separates capability evidence from handle lifecycle, checks companion daemons/system policies, and retains unknowns instead of declaring absence.
- AGENTS.md, PHILOSOPHY.md and SOURCES.md now align on evidenced no-GUI handling and product identity-state protection. Generic infrastructure encryption and secret rotation remain excluded.
- Verification distinguishes source coverage from pack/render coverage. Documentation reconciliation remains separate from live proof and confers no maturity badge.

## Verification

The [behavioral regression cases](../../.claude/skills/_shared/evals/source-discovery/cases.md) contain fictional frozen vendor docs and three realistic requests: creation planning, full update and pack-surface research. Creation, full-update and pack research were each assessed in a fresh independent context, without the RCA, rubric, other requests or intended findings. The evaluators followed local documentation links and wrote their artifacts outside the repository. An earlier combined smoke-run is not counted as blind discovery evidence because its pack request named the target feature. No external calls, product actions or repository edits were part of the exercise.

| Observable decision | Result in the evaluator's artifacts |
|---|---|
| Follow an unmapped security attribute | Found `node:stateSealed`, followed its feature/setup links and distinguished the reported condition from configuration. |
| Separate administration planes | Distinguished interactive client, service daemon, central policy/console and managed-device policy. |
| Handle no GUI | Retained the control, documented no native GUI enablement, and used the actual reported-state review path without inventing a toggle. |
| Detect an older omission | Reported `OMISSION` even though introduction and default changes predated the existing guide's date. |
| Preserve conditional defaults and risk | Kept platform/package/version conditions, hardware requirements, restart and recovery; left ambiguous Apple wording qualified. |
| Retain unavailable evidence | Kept HTTP 403 API evidence unverified and proposed no fictitious endpoint. |
| Respect legitimate exclusions | Excluded generic host/database encryption while retaining product identity-state protection. |
| Bound completion claims | Kept missing deployment formats/read interfaces unresolved, avoided manufacturing controls for a count, and claimed neither whole-product completeness nor live validation. |

All eight decision checks were observed across the three isolated scenarios. These are controlled evaluations graded by the authoring agent against the published rubric, not a statistical comparison with prior agents, human review or a guarantee against future omissions. The recorded input-set fingerprint is `c14e55c62b930384aa60003ded3f735904937765004e0aad2dd53254c25b65d3` over 19 workflow/fixture files, including the CLI inventory consulted by the pack evaluator (sorted relative path, NUL, contents with final whitespace normalized to one LF, NUL; rubric and this report excluded). It is not a fingerprint of the complete execution environment.

Additional checks: the skill-creator validator passed all five modified skills; 64 local Markdown reference targets resolved across the 20 instruction/fixture/report files; repository guide lint passed with zero warnings. These are structural results, separate from the behavioral observations. No guide or pack source changed, so product execution and regenerated excerpt tests were not repeated for this instruction-only change.
