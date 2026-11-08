# Trust Center discovery behavioral regression cases

The Lumen sources are **fictional, frozen offline captures**. `.invalid` URLs are identifiers resolved through `fixture/routes.json`; do not fetch them or cite them as real vendor sources. PDF text is provided as an extracted-text capture, not a real PDF download test. `partial-routes.json` overrides the second catalog page with a recorded retrieval failure.

Give an independent evaluator the applicable skill and one request below, with the fixture directory. Do not supply this rubric, the Anthropic incident or expected findings. Use a fresh context per request, allow output only in a temporary directory and require an evidence/read trace. No network, live product access, credentials, repository edits, commits or publication. A caller changing this workflow should observe decisions from these raw artifacts, not grade whether a response repeats skill wording.

## Requests

1. **Full update:** “Use update-hth-guide to assess the frozen Lumen guide for a full currency pass. Start at index.md and use routes.json to resolve captured source URLs. Produce a source-derived coverage ledger and material findings; do not edit the guide. Record which captures you read and the research boundary.”
2. **Partial catalog:** Same request, but use `partial-routes.json` as the source resolver. A missing body cannot be replaced by the same URL's capture from `routes.json`.
3. **Creation/pack handoff:** “Use create-hth-guide Phases 1–2 on the frozen Lumen sources to plan a commercial Enterprise guide and identify implementation-verification research for any supported desktop controls. Start at index.md and routes.json. Produce candidates and a handoff, not a production guide or executable pack.”

Also rerun the earlier [RelayMesh full-update case](../source-discovery/cases.md) after changing shared discovery rules; it has no supplied Trust Center and must not trigger invented portal/endpoint claims or out-of-scope live research.

## Observable checks

| Decision | Evidence-based pass condition |
|----------|-------------------------------|
| Catalog breadth | Read the official portal and actual resource catalog, follow the exposed second page in the full case, and inspect categories beyond the single collaboration resource. An asset-integrity JSON is not the document inventory. |
| Actual hardening content | Inspect document 301's body and sections before admitting it; do not reject a customer configuration document merely because it is on the Trust Center or under FedRAMP. Finding document 101 alone does not finish discovery. |
| Older omissions | Notice the client identity-state candidate through the broader baseline even though its docs predate the guide and release notes have no new security entries. |
| Adjacent scope | Preserve Government host/header/role and commercial Enterprise boundaries. Evaluate transferable client requirements against the current client reference, rather than copying Government settings wholesale or discarding all adjacent guidance. |
| Current implementation | Record the current `stateProtection` key, product/version/hardware/restart/recovery caveats and no-GUI path; do not emit the removed variable from the dated PDF. |
| Evidence vs metadata | Treat 201 as assurance, and 601 as a package overview rather than a recommendation checklist or completed authorization. A displayed control count proves no native posture inventory. |
| Access/false success | Keep 401 discovered but inaccessible; do not request access or claim its body read. Keep 501 unverified because the supposed PDF is an HTML sign-in page despite HTTP 200 and public metadata. |
| Partial results | In the partial case, record the failed second page and incomplete catalog coverage; do not use the failed page’s full-snapshot body or assert a complete inventory. Independently available document captures may still provide useful evidence, with their separate discovery provenance recorded. |
| Legitimate scope exclusions | Exclude generic host-disk/datacenter controls under PHILOSOPHY while retaining the independently supported product identity-state candidate. |
| Honest closeout | Report portal/catalog/document provenance, scope, read vs unread resources, candidate dispositions and remaining gaps. No source/fixture/render test becomes VERIFIED-LIVE or a promise of exhaustive future discovery. |

The fixture-integrity test checks local references and capture consistency only. It is not an automatic model-behavior grader. Record evaluator inputs, artifacts, observed decisions and limitations when running the behavioral cases.
