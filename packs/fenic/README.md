# Fenic Code Pack

Three packs support two of three controls in the [Fenic guide](https://howtoharden.com/guides/fenic/). Scope is the Python library's native configuration, not hosted Typedef or Factory tenant administration. Droid policy, SSO and keys do not configure these applications.

| Type/control | Operation | Inputs |
|--------------|-----------|--------|
| Config 1.1 | Disable future LLM response caching with `semantic.llm_response_cache: null` | Merge into actual SessionConfig; remove JSONC comments before strict loading |
| SDK 1.1 | Read local exported SessionConfig cache status | `FENIC_SESSION_CONFIG_FILE` absolute non-symlink regular JSON file, max 1 MiB; profile 2+ |
| SDK 2.1 | Emit one OpenRouter model/profile fragment with explicit providers, denied data collection and no fallbacks | `FENIC_OPENROUTER_MODEL`; `FENIC_APPROVED_PROVIDERS` JSON nonempty unique string array; profile 2+ |

Run SDK files with Python 3.10+ and official `fenic==0.13.0` from a trusted isolated environment. The SDK language is a necessary type-fit exception to the new-authoring Bun/TypeScript preference: no official TypeScript equivalent was verified. The released package needed explicit `tqdm==4.67.1` and `httpx==0.28.1` to satisfy otherwise missing runtime imports in this check. Dependency resolution was not a full supported-version matrix; review your actual environment.

Set `HTH_PROFILE_LEVEL` to 2, 3 or 4 (default 1 refuses). Exit 2 is unknown/not run and prints a generic error, never raw SDK exceptions/configuration. The cache reader returns 0 only for a disabled cache in the supplied export, 1 for a recognized enabled cache. Missing/incomplete fields, unknown cache keys including `enabled`, invalid JSON, oversized files and unsafe paths return 2. It does not validate the whole application or prove deployed state. Enabled-cache TTL is independently bounded to 1 second–30 days because the released validator does not consistently enforce its documented cap for seconds/minutes. Namespace values and credentials are never printed.

The routing generator returns 0 for a generated local fragment; review and merge it under an approved `semantic.language_models` alias and select the intended default separately. It reads no credentials, creates no Session or model-bearing SemanticConfig, and performs no model catalog/inference request. Whole SessionConfig model validation can fetch OpenRouter's live catalog, so that is intentionally excluded from these offline packs. `data_collection="deny"` is a routing request, not independently verified provider retention. Review embeddings, custom endpoints, every other profile, model fallback and PDF parser separately.

No pack installs a product, obtains a credential, changes a running app, starts MCP, purges cache/catalog files or proves physical deletion. The configuration candidate disables future native response-cache use only; it does not clear previous responses, DataFrame caches, catalogs, logs or provider storage. Native `enabled=False` is silently ignored in v0.13.0 and must not be used. The provider exclusion field is `ignore`, not the topic example's `exclude`.

Validate the actual SDK without credentials or model calls with `FENIC_PYTHON=/absolute/isolated/python bun test scripts/test-fenic-packs.test.ts`. Tests install no SDK and skip with an explicit report when the interpreter is not supplied. The repository workflow installs the pinned SDK and supplements then runs the real-class tests; these are not fake SDK fixtures. See [source coverage](../../docs/research/factory-source-coverage.md) and [validation](../../docs/research/factory-refresh-validation.md) for limits.
