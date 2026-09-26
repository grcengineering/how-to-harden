#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: langchain-7.1
#   guide:   https://howtoharden.com/guides/langchain/#71-pin-and-verify-langchain-package-integrity
#   profile: L1
#   mode:    read-only
#   requires: python >= 3.10 in an isolated virtualenv, network access to PyPI (no LangSmith credential)
# =============================================================================
# HTH LangChain Control 7.1: Pin and Verify LangChain Package Integrity
# (also rendered by control 3.1, Pin LangChain Dependencies)
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 16.4 | NIST 800-53 SA-12, CM-6
# Dependencies: pip, pip-tools; langchain-cli is the first-party CLI from langchain-ai
#
# `mode: read-only` = no LangSmith tenant state is touched; this installs into the
# active virtualenv only.
#
# Every pin clears the advisories this guide lists in 3.2 and 3.6 (floors from
# api.github.com/repos/langchain-ai/{langchain,langgraph,langsmith-sdk}/security-advisories,
# 2026-09-24). Re-check them at every refresh; a pin is only as current as its review.
#
# TRAPS
#  1. `pip install --require-hashes "pkg==x"` on the command line always fails:
#     a command-line requirement cannot carry a hash. Put every tool, including
#     langchain-cli, in requirements.in so pip-compile hashes it.
#  2. Exact pins must resolve together: langchain 0.3.x requires langsmith<0.4, so
#     pairing it with a patched langsmith floor is ResolutionImpossible.

set -euo pipefail

# HTH Guide Excerpt: begin cli-pip-hashes
# Generate hash-pinned requirements with pip-compile (pip-tools)
pip install --quiet pip-tools

cat > requirements.in <<'EOF'
langchain==1.4.2            # > 1.3.8 (CVE-2026-55443), >= 0.3.30 (CVE-2026-45134)
langchain-core==1.6.5       # >= 1.3.3 (CVE-2026-44843), >= 1.2.28 (CVE-2026-40087), >= 1.2.22 (CVE-2026-34070)
langchain-community==0.4.2
langchain-openai==1.6.6     # >= 1.1.14 (CVE-2026-41488)
langgraph==1.2.12           # >= 1.0.10 (CVE-2026-28277)
langgraph-checkpoint>=4.1.1 # CVE-2026-48775 (<= 4.1.0), CVE-2026-27794 (< 4.0.0)
langgraph-sdk>=0.4.4        # GHSA-fvww-7h3r-vfhp (0.1.45 - 0.4.3), CVE-2026-48776 (<= 0.3.14)
langsmith>=0.8.18,<1.0.0    # CVE-2026-59152 (< 0.8.18, critical) is the highest floor in 3.2
langchain-cli==0.0.37       # first-party CLI, hash-pinned with everything else
EOF

# Compile with hashes for reproducible, integrity-verified installs
pip-compile --generate-hashes --output-file requirements.txt requirements.in
# HTH Guide Excerpt: end cli-pip-hashes

# HTH Guide Excerpt: begin cli-pip-install-verified
# Install ONLY from the pinned, hashed requirements file
pip install --require-hashes --no-deps -r requirements.txt
# HTH Guide Excerpt: end cli-pip-install-verified

# HTH Guide Excerpt: begin cli-langchain-cli-install
# langchain-cli arrived hash-verified with the rest of the tree; confirm it runs
langchain --version
# HTH Guide Excerpt: end cli-langchain-cli-install
