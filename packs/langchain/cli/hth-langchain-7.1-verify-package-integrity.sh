#!/usr/bin/env bash
# HTH LangChain Control 7.1: Pin and Verify LangChain Package Integrity
# Profile: L1 | NIST: SA-12, CM-6
# https://howtoharden.com/guides/langchain/#71-pin-and-verify-langchain-package-integrity
#
# LangChain ships as a constellation of PyPI packages: langchain, langchain-core,
# langchain-community, langchain-openai, langchain-anthropic, langgraph, langsmith, etc.
# All must be pinned and integrity-verified to prevent supply chain attacks.

set -euo pipefail

# HTH Guide Excerpt: begin cli-pip-hashes
# Generate hash-pinned requirements with pip-compile (pip-tools)
pip install --quiet pip-tools

cat > requirements.in <<'EOF'
langchain==0.3.18
langchain-core==0.3.50
langchain-community==0.3.20
langchain-openai==0.3.5
langgraph==0.3.4
langsmith>=0.6.3,<1.0.0  # CVE-2026-25528 fix in 0.6.3
EOF

# Compile with hashes for reproducible, integrity-verified installs
pip-compile --generate-hashes --output-file requirements.txt requirements.in
# HTH Guide Excerpt: end cli-pip-hashes

# HTH Guide Excerpt: begin cli-pip-install-verified
# Install ONLY from the pinned, hashed requirements file
pip install --require-hashes --no-deps -r requirements.txt
# HTH Guide Excerpt: end cli-pip-install-verified

# HTH Guide Excerpt: begin cli-langchain-cli-install
# Install the official langchain-cli for app/template scaffolding
pip install --require-hashes "langchain-cli==0.0.36"

# Verify
langchain --version
# HTH Guide Excerpt: end cli-langchain-cli-install
