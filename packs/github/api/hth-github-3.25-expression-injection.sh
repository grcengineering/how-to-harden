#!/usr/bin/env bash
# HTH GitHub Control 3.13: Prevent GitHub Actions Expression Injection
# Profile: L1 | NIST: SI-10, SA-11 | SLSA: Build L2
# https://howtoharden.com/guides/github/#313-prevent-github-actions-expression-injection
#
# Audits workflow files for unsafe ${{ }} expression interpolation in run: blocks.
# These patterns allow shell injection via user-controlled inputs (PR titles,
# branch names, issue bodies, commit messages).
#
# Real-world incidents: Ultralytics (2025), PostHog/AsyncAPI via Shai Hulud (2025)
# References: GitHub Security Lab, zizmor, actionlint

set -euo pipefail

# HTH Guide Excerpt: begin audit-expression-injection
# Scan all workflow files for unsafe ${{ }} expression interpolation in run: blocks.
# Flags patterns where user-controlled GitHub context is injected directly into
# shell commands without going through an environment variable first.
#
# SAFE:   env: { TITLE: "${{ github.event.pull_request.title }}" }
#         run: echo "$TITLE"
# UNSAFE: run: echo "${{ github.event.pull_request.title }}"
#
# Usage: ./hth-github-3.25-expression-injection.sh [workflow-dir]

WORKFLOW_DIR="${1:-.github/workflows}"
FINDINGS=0

echo "=== GitHub Actions Expression Injection Audit ==="
echo "Scanning: ${WORKFLOW_DIR}"
echo ""

# Dangerous GitHub context expressions that can contain user-controlled input.
# These must NEVER appear inside run: blocks — only in env: blocks.
DANGEROUS_EXPRESSIONS=(
  'github\.event\.issue\.title'
  'github\.event\.issue\.body'
  'github\.event\.pull_request\.title'
  'github\.event\.pull_request\.body'
  'github\.event\.comment\.body'
  'github\.event\.review\.body'
  'github\.event\.discussion\.title'
  'github\.event\.discussion\.body'
  'github\.event\.pages\.\*\.page_name'
  'github\.event\.commits\.\*\.message'
  'github\.event\.commits\.\*\.author\.name'
  'github\.event\.head_commit\.message'
  'github\.event\.head_commit\.author\.name'
  'github\.event\.workflow_run\.head_branch'
  'github\.event\.workflow_run\.head_commit\.message'
  'github\.head_ref'
  'github\.ref_name'
)

if [ ! -d "${WORKFLOW_DIR}" ]; then
  echo "No workflow directory found at ${WORKFLOW_DIR}"
  exit 0
fi

for workflow in "${WORKFLOW_DIR}"/*.yml "${WORKFLOW_DIR}"/*.yaml; do
  [ -f "$workflow" ] || continue
  filename=$(basename "$workflow")

  for pattern in "${DANGEROUS_EXPRESSIONS[@]}"; do
    # Find lines in run: blocks that contain ${{ <dangerous_expression> }}
    # We look for the pattern anywhere on lines that are part of a run: block
    matches=$(grep -nE "\\\$\{\{[^}]*${pattern}" "$workflow" 2>/dev/null || true)
    if [ -n "$matches" ]; then
      # Filter: only flag if the line is inside a run: block (not env: block)
      echo "$matches" | while IFS= read -r match; do
        line_num=$(echo "$match" | cut -d: -f1)
        # Check context: is this line inside a run: block or an env: block?
        # Look backwards from this line for the nearest run: or env: key
        context=$(head -n "$line_num" "$workflow" | tail -20 | grep -E '^\s*(run:|env:)' | tail -1)
        if echo "$context" | grep -q "run:"; then
          echo "  [VULNERABLE] ${filename}:${line_num} — ${pattern}"
          echo "    $(echo "$match" | cut -d: -f2-)"
          echo "    FIX: Move to env: block, reference via \$ENV_VAR in run:"
          FINDINGS=$((FINDINGS + 1))
        fi
      done
    fi
  done
done

echo ""
echo "=== Audit Complete ==="
echo "Expression injection risks found: ${FINDINGS}"

if [ "$FINDINGS" -gt 0 ]; then
  echo ""
  echo "REMEDIATION: For each finding, replace the dangerous \${{ }} expression"
  echo "in the run: block with an environment variable reference."
  echo ""
  echo "  BEFORE (vulnerable):"
  echo "    run: echo \"\${{ github.event.issue.title }}\""
  echo ""
  echo "  AFTER (safe):"
  echo "    env:"
  echo "      ISSUE_TITLE: \"\${{ github.event.issue.title }}\""
  echo "    run: echo \"\$ISSUE_TITLE\""
  echo ""
  echo "TOOLS: Install zizmor for comprehensive static analysis:"
  echo "  cargo install zizmor   # or: brew install zizmor"
  echo "  zizmor .github/workflows/"
  echo ""
  echo "See: howtoharden.com/guides/github/#313"
  exit 1
fi

echo "No expression injection risks detected."
exit 0
# HTH Guide Excerpt: end audit-expression-injection

# HTH Guide Excerpt: begin zizmor-ci-workflow
# GitHub Actions workflow to run zizmor as a CI check on workflow changes.
# Catches expression injection, unpinned actions, excessive permissions,
# and other supply chain risks before they merge.
#
# Source: github.com/zizmorcore/zizmor-action
# License: MIT
#
# name: Workflow Security Lint
# on:
#   pull_request:
#     paths:
#       - '.github/workflows/**'
#       - '.github/actions/**'
#
# permissions:
#   contents: read
#   security-events: write
#
# jobs:
#   zizmor:
#     runs-on: ubuntu-latest
#     steps:
#       - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
#
#       - name: Run zizmor
#         uses: zizmorcore/zizmor-action@9124bf3aa36c9e18df7cba08e1bbe26db56e4496  # v1
#         with:
#           sarif-file: zizmor-results.sarif
#
#       - name: Upload SARIF
#         uses: github/codeql-action/upload-sarif@v3
#         if: always()
#         with:
#           sarif_file: zizmor-results.sarif
#           category: zizmor
# HTH Guide Excerpt: end zizmor-ci-workflow
