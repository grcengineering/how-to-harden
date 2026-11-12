# n8n code packs

Native self-hosted environment configuration and the installed official n8n audit CLI. Review license/version gates, existing exclusions, workflow compatibility and retention authorization before applying configuration. No pack installs software, updates an instance, rotates credentials, or runs a workflow. Run the audit from the existing deployment environment; a disconnected local CLI/database cannot establish production posture.

Cloud customers must use the guide's supported UI controls rather than these environment files. Documentation and syntax checked only; no live tenant validation.

Merge these mappings into the existing Docker Compose n8n service rather than overwriting unrelated or stricter settings. They are not container env-files: `NODES_EXCLUDE` is a YAML string containing a JSON array with its literal double quotes intact.

The YAML snippets are environment mappings to merge under an existing n8n service, not standalone Compose deployments. Values remain strings, including the JSON node-exclusion list. Do not source these files in a shell.
