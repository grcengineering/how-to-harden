#!/usr/bin/env bash
# HTH Cursor Control 4.02: Scan for Secrets in Code Before AI Processing
# Profile: L2 | NIST: IA-5
# https://howtoharden.com/guides/cursor/#42-scan-for-secrets-in-code-before-ai-processing

set -euo pipefail

# --------------------------------------------------------------------------
# Install pre-commit hooks to detect secrets before they reach AI context
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-install-secret-scanning
# Install pre-commit
pip install pre-commit

# Create .pre-commit-config.yaml
cat > .pre-commit-config.yaml <<EOF
repos:
  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.63.0
    hooks:
      - id: trufflehog
        args: ['--max-depth=1']
EOF

# Install hook
pre-commit install
# HTH Guide Excerpt: end cli-install-secret-scanning
