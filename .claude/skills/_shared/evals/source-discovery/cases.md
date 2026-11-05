# Source-discovery behavioral regression cases

These offline cases exercise decisions, not instruction wording. The RelayMesh documents are **fictional, frozen test inputs**; `.invalid` URLs identify simulated sources and must not be fetched or cited as real vendor documentation. They are not production recommendations.

Give an independent evaluator only the applicable skill, one request below and the `fixture/` directory. Treat captured bodies as the provided source evidence, respect captures marked unavailable, and permit output only in a temporary directory. Do not supply this rubric, the RCA or intended findings to that evaluator. Reading fixtures is authorized; product changes, credentials, network calls, commits, pushes and PRs are not.

Use a fresh context for each request. The pack request names its target feature; supplying it alongside a creation/update request or reusing an earlier answer would cue the discovery test.

## Requests

1. **Creation:** “Use create-hth-guide Phases 1–2 with these frozen RelayMesh docs to produce a source-derived candidate inventory and implementation-surface verdicts. This is a planning exercise; do not write a production guide. Start at `vendor/index.md`.”
2. **Full update:** “Use update-hth-guide to assess `guide.md` against the frozen current vendor docs. Produce the coverage ledger and material findings. Do not edit the guide.”
3. **Pack research:** “Use create-code-pack Phase 1 to assess implementation and verification options for protection of RelayMesh's device identity state. Produce a surface census and pack plan using the fixture evidence. Do not invent or execute interfaces.”

## Observable checks

Judge the outputs against evidence and actions, not exact wording. A ledger may be Markdown, YAML or another reviewable format.

| Case | Required observation |
|---|---|
| Attribute lead | Follow the unmapped `node:stateSealed` signal to the feature and setup docs; distinguish the read signal from the protection it reports. |
| Management planes | Identify central console/policy, `relaymesh`, `relaymeshd` and system policies independently; do not let a client-only inventory stand for all of them. |
| No GUI | Retain the documented client-state control with a no-native-GUI enforcement verdict and real CLI/system-policy paths; invent no toggle. |
| Older omission | In the full update, report the missing state-protection guidance although its feature and default changes predate the guide's date. |
| Conditional defaults | Preserve platform/version conditions, hardware prerequisites, restart and recovery risks; claim neither universally enabled encryption nor safe universal enablement. |
| Unavailable evidence | Mark the captured API reference unverified, not absent; fabricate no endpoint or permission. |
| Legitimate exclusion | Exclude generic host-volume encryption under PHILOSOPHY.md while retaining product identity-state protection. |
| Bounded claims | Map covered items to actual guide text, retain gaps/unknowns and avoid claiming complete coverage from control/pack counts or fixture verification as live proof. |

A pass means these behaviors were observed in this controlled exercise. It does not prove exhaustive discovery for arbitrary vendors, real interface behavior or a guide maturity promotion. Record input revision, evaluator scope, outputs, observations and remaining limitations when changing the workflow.
