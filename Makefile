# How to Harden — Test & Build Targets
#
# Local dev and GitHub Actions call the same targets.
# Run `make help` to see available targets.
#
# Prerequisites:
#   - Python 3 (content validation)
#   - Rust toolchain with clippy + rustfmt (CLI tests)
#   - Ruby + Bundler (Jekyll build — CI only unless installed locally)

.PHONY: help test lint lint-content lint-rust test-unit test-build \
        test-build-jekyll test-build-sync

# ─── Default ──────────────────────────────────────────────────────────────────

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ─── Top-level ────────────────────────────────────────────────────────────────

test: lint test-unit test-build-sync ## Run all tests (local-safe: skips Jekyll if no Ruby)

test-all: lint test-unit test-build ## Run all tests including Jekyll build (requires Ruby)

# ─── Lint ─────────────────────────────────────────────────────────────────────

lint: lint-content lint-rust ## Run all linters

lint-content: ## Validate guide formatting, frontmatter, tables (7 checks)
	@bash scripts/validate-guides.sh

lint-rust: ## Clippy warnings-as-errors + rustfmt check
	@cd cli && cargo fmt --all -- --check
	@cd cli && cargo clippy --workspace -- -D warnings

# ─── Unit / Integration Tests ─────────────────────────────────────────────────

test-unit: ## Rust unit + integration tests (178 tests)
	@cd cli && cargo test --workspace

# ─── Build Verification ───────────────────────────────────────────────────────

test-build: test-build-sync test-build-jekyll ## Full build verification (sync + Jekyll)

test-build-sync: ## Sync packs to Jekyll data and validate YAML
	@bash scripts/sync-packs-to-data.sh

test-build-jekyll: ## Jekyll build — catches Liquid/kramdown/YAML errors
	@cd docs && bundle exec jekyll build --strict_front_matter 2>&1
