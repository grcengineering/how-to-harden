# Niteshift Code Pack

Use these examples with the [Niteshift Hardening Guide](https://howtoharden.com/guides/niteshift/). This pack never contacts a Niteshift API or starts an agent.

| Control | Artifact | What it does |
|---------|----------|--------------|
| 2.2 | Internal services YAML | Shows an on-demand worker without a preview port or tunnel. Adapt the worker command and merge into a reviewed Config v2 manifest; do not replace unrelated entries. |
| 2.2 | Service status wrapper | Calls `ns services status` in an existing task. Status does not prove the absence of public exposure; review the whole manifest and the live pilot separately. |
| 3.2 | Paused automation generator | Writes candidate MDX to stdout only. Pass a dedicated low-privilege service-account handle. Review before saving under `<settingsDirectory>/automations/weekly-review.mdx`; check for key collisions. Both the definition and trigger are paused. |

The automation prompt is not a permission control. Enforce privileges outside the agent. Generation or offline parsing does not prove Niteshift accepted the configuration or enforced the pause.
