#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: github-3.11
#   guide: https://howtoharden.com/guides/github/#311-require-codeowners-approval-for-workflow-changes
#   profile: L2
#   mode: read-only
#   requires: bash; manually merge stdout into existing CODEOWNERS
# Source: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners (2026-11-12)
# Emits native CODEOWNERS syntax; NEVER overwrites existing ownership rules.
set -euo pipefail
# HTH Guide Excerpt: begin config-codeowners-cicd
: "${SECURITY_OWNER:?Set an existing owner such as @your-org/security-team}"
[[ "$SECURITY_OWNER" =~ ^@[A-Za-z0-9_-]+(/[A-Za-z0-9_-]+)?$ ]] || { echo 'Invalid GitHub owner' >&2; exit 2; }
for path in \
  /.github/CODEOWNERS /.github/workflows/ /.github/actions/ \
  /.github/dependabot.yml /renovate.json /renovate.json5 \
  '**/.vscode/' '**/.claude/' '**/.cursor/' '**/.gemini/' \
  '**/.mcp.json' '**/AGENTS.md' '**/CLAUDE.md' '**/GEMINI.md' \
  /package.json /package-lock.json /pnpm-lock.yaml /yarn.lock \
  /pyproject.toml /uv.lock; do
  printf '%-30s %s\n' "$path" "$SECURITY_OWNER"
done
# Merge after broader rules: the LAST matching CODEOWNERS pattern wins.
# Add nested manifests and other tool-specific paths your repository actually uses.
# Enforce code-owner review in branch protection/rulesets; a file alone does not block merges.
# HTH Guide Excerpt: end config-codeowners-cicd
