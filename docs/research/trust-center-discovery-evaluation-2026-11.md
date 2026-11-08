# Trust Center discovery workflow — evidence and evaluation

Checked 2026-11-06. Base: `09e9bcdcbbed4c7953582caa75f8394552742b99` (main after Anthropic PR #140). The branch was then fast-forwarded to main 4e4031d8b9a9d07781a3c57d5dd5320623cf53aa (the independently merged Factory refresh); it changes none of the evaluated skill/source instructions. Scope: agent instructions/source-admission policy and offline evaluation fixtures; no product guide, code pack, tenant, credentials or vendor access settings changed. This checkout has no `.agents/skills`; its canonical playbooks are under `.claude/skills`.

## Observed gap and change

The Anthropic research initially followed a linked Cowork resource without enumerating the Trust Center catalog broadly enough to find the public Government configuration guide before a user supplied the public catalog URL. That sequence establishes a discovery omission; it does not establish the agent's internal reason.

The pre-change instructions contain a contributing policy defect: create-hth-guide Phase 1 says to reject Trust Centers on sight, while SOURCES.md excludes `trust.vendor.com` and limits Tier 1 to the docs domain. The shared discovery workflow has no explicit Trust Center catalog checkpoint. These rules conflate source admission with discovery and can discourage reading real customer configuration documents hosted by a Trust Center. This is an evidence-backed mechanism, not a claim that wording was the only cause of the incident.

The change requires portal/catalog/document discovery and reconciliation, with one shared reference linked from creation, update, pack research, verification and validation. AGENTS.md and SOURCES.md now distinguish a portal/assurance page from a customer configuration document. The workflow covers known public structured indexes, categories/pagination, adjacent editions, actual body verification, dated instructions, access boundaries and honest incomplete outcomes. It does not admit assurance-only documents, authorize gated access, or promise every vendor has a complete public catalog.

## Current public-source check

Anonymous public reads used curl with curlrc disabled, no credentials/cookies or access requests:

- [Anthropic public catalog](https://trust.anthropic.com/json): observed `resources.categories[].items[]`; the returned capture contains 16 categories and 69 metadata entries (48 public, 21 restricted). This describes that response, not a guaranteed complete or permanent inventory. The portal HTML identifies Vanta assets; `/json` is recorded as a verified example/known lead, not a universal provider contract.
- The catalog's FedRAMP category advertises **Claude for Government (C4G) FedRAMP Secure Configuration Guide**, separately from its Enterprise certification-package overview and the Cowork/FISMA best-practices resources. The latter being in another category demonstrates why a single linked resource is insufficient.
- [Public C4G document](https://trust.anthropic.com/doc/trust?rid=6ab43afba6eead3d68716b5c&r=iz673w96495gyjer8h78n&download=true): downloaded and read via text extraction; 22 pages, v2.1, July 16, 2026, scoped to C4G on claude.fedstart.com and FedRAMP Rev. 5. Body includes customer SSO/SCIM, roles and Required/Recommended configuration material. SHA-256: `14f136620284835af0d72e3a546c3f18082da21237368e316599aad1612a8e9c`. It qualifies by substance; it is not a commercial Enterprise/20x baseline. No restricted catalog document was downloaded.

The raw live catalog and PDFs are not committed. They are source observations for the workflow example, not new vendor-guide coverage or live validation.

## Independent offline behavioral evaluation

Fresh evaluators received the updated skill, its relevant shared references and one realistic request with frozen inputs. They were not given the case rubric, Anthropic miss or intended findings. They could write only temporary assessment artifacts; no network, repository edits, credentials, live systems, commits or publication were authorized. Root reviewed the output ledgers, findings and read traces against the [Trust Center cases](../../.claude/skills/_shared/evals/trust-center-discovery/cases.md) and [earlier source-discovery cases](../../.claude/skills/_shared/evals/source-discovery/cases.md).

| Evaluation | Observed decisions | Result within stated boundary |
|------------|--------------------|-------------------------------|
| Lumen full currency pass | Followed portal → advertised catalog → two pages, six categories, seven entries. Read the Government configuration and federal client bodies beyond the initial collaboration resource. Used the current client reference for commercial applicability and removed-variable handling; retained hardware/restart/recovery/no-GUI conditions. Excluded Government-only roles/header/host, assurance and certification overview/count as configuration. Kept restricted 401 and HTTP-200 sign-in 501 unverified. | Required catalog/source/applicability/access behaviors observed. Three source-supported omissions; not a complete whole-product claim. Ledger: 18 candidates, 3 covered, 3 gaps, 6 excluded, 6 unverified. |
| Lumen partial catalog | Used only the partial resolver, recorded page 2's 503 and incomplete catalog coverage, and did not substitute the full page body or infer a negative inventory. Continued the available identity/audit/client sources and reported older omissions, restricted access and false-PDF gaps. | Required partial-coverage behavior observed; no broad catalog-completeness claim. |
| RelayMesh legacy full update | Followed the posture attribute to identity-state protection; retained client/daemon/system-policy distinctions, older omission, conditional defaults, prerequisites/recovery and documented no-GUI outcome. Excluded generic host-volume encryption; API capture stayed unverified. No Trust Center was evidenced in the supplied capture set, and none was invented. | Earlier discovery regression behaviors preserved, including bounded no-portal reporting. |

Temporary artifacts were produced under `/tmp/hth-trust-eval-full/`, `/tmp/hth-trust-eval-partial/` and `/tmp/hth-trust-eval-legacy/`; reviewer-reproducible prompts, captures and rubric are committed, while bulky generated assessment files are not. All evaluators reported unchanged fixture inputs and no prohibited operations. A non-operative SOURCES.md example-table caption was reworded during evaluation; the partial evaluator recorded the initial/current instruction hashes as external drift. Fixture bytes and the operative shared workflow did not change. These are bounded post-change observations, not a controlled before/after experiment or a statistically established success rate.

## Mechanical verification and limits

- `make test-source-discovery-fixtures`: six Bun tests, 284 assertions passed. They check capture routes/local paths, reserved domains, page linkage, partial/error fixtures, decoy JSON and Markdown reference integrity. They do **not** grade model behavior or contact vendors.
- Skill creator's quick validator passed for all five existing SKILL.md entrypoints; their names/descriptions/invocation policy remain unchanged.
- Guide lint passed with zero warnings; strict Jekyll build and `git diff --check` passed. No guide/pack content or maturity was changed, so tenant validation and rendering of newly authored controls are not applicable.
- The fixture PDFs are supplied text captures, not tests of real PDF/OCR/browser extraction. The live public C4G example supplies a separate actual-download check.
- The behavioral runs exercise update/source discovery; they do not independently run every create/pack/validation entrypoint or every Trust Center provider, locale, authentication model or document format. The creation/handoff case remains available for later workflow changes. Link checks confirm routing, not that every model follows it.
- No exhaustive inventory or guaranteed future recall is claimed. Public/gated content, provider schemas and routes can change; agents must re-verify them and report research limits. Remote CI results belong to the PR record.
