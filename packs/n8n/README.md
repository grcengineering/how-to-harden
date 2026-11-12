# n8n code packs

Native self-hosted environment configuration and the installed official n8n audit CLI. Review license/version gates, existing exclusions, workflow compatibility and retention authorization before applying configuration. No pack installs software, updates an instance, rotates credentials, or runs a workflow. Run the audit from the existing deployment environment; a disconnected local CLI/database cannot establish production posture.

Cloud customers must use the guide's supported UI controls rather than these environment files. Documentation and syntax checked only; no live tenant validation.

Consume `.env` files with the deployment's environment-file mechanism (for example a container env-file), not by shell-sourcing them: `NODES_EXCLUDE` must reach n8n as a JSON array with its literal double quotes intact. Merge into the existing configuration rather than overwriting unrelated or stricter settings.
