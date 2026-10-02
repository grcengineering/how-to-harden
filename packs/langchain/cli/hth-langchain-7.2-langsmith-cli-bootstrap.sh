#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: langchain-7.2
#   guide:   https://howtoharden.com/guides/langchain/#72-use-the-official-langsmith-cli-and-langgraph-cli-for-reproducible-bootstrap
#   profile: L1
#   mode:    read-only
#   requires: network access to github.com and PyPI; LANGSMITH_API_KEY(workspace-scoped lsv2_sk_ service key, only for commands that call LangSmith)
# =============================================================================
# HTH LangChain Control 7.2: Use the Official langsmith-cli and langgraph-cli for Reproducible Bootstrap
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 CM-2, CM-6
# Dependencies: curl, shasum, tar, python/pip; docker for `langgraph build`
#
# `mode: read-only` = installs local tooling and builds a local image; no LangSmith
# tenant state is changed by this file.
#
# Sources:
#   https://github.com/langchain-ai/langsmith-cli  (README: install script, Homebrew tap
#     langchain-ai/tap/langsmith-cli, `go install .../cmd/langsmith`); release assets
#     langsmith_<os>_<arch>.tar.gz + checksums.txt
#   https://github.com/langchain-ai/langgraph/tree/main/libs/cli  (`langgraph validate`,
#     `langgraph build` requires -t/--tag)
#
# TRAPS
#  1. LOOK-ALIKE PACKAGE. The PyPI project named `langsmith-cli` is published from
#     github.com/gigaverse-app/langsmith-cli, a third party. langchain-ai's CLI is a Go
#     binary and is not on PyPI. `pip install langsmith-cli` is exactly the
#     typosquatting-shaped risk this control exists to prevent.
#  2. `langgraph build` without --tag exits 2 ("Missing option '--tag'"). Validation is
#     its own command: `langgraph validate`.
#  3. Keys start `lsv2_sk_` (service) or `lsv2_pt_` (personal); `ls__` keys stopped
#     working on 2024-10-22.

set -euo pipefail

# HTH Guide Excerpt: begin cli-install-langsmith-cli
# Install the OFFICIAL langsmith CLI (Go binary from github.com/langchain-ai/langsmith-cli),
# pinned to one release and verified against that release's checksums.txt.
# Do NOT `pip install langsmith-cli`: that PyPI name belongs to a third party.
LANGSMITH_CLI_VERSION="0.2.59"
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$(uname -m)" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; *) ARCH=$(uname -m) ;; esac
ASSET="langsmith_${OS}_${ARCH}.tar.gz"
BASE="https://github.com/langchain-ai/langsmith-cli/releases/download/v${LANGSMITH_CLI_VERSION}"

curl -fsSLO "${BASE}/${ASSET}"
curl -fsSLO "${BASE}/checksums.txt"
grep " ${ASSET}\$" checksums.txt | shasum -a 256 -c -   # aborts on a missing or mismatched hash
tar -xzf "${ASSET}" langsmith
./langsmith --version
# Package-manager alternatives from the same README:
#   brew install langchain-ai/tap/langsmith-cli
#   go install github.com/langchain-ai/langsmith-cli/cmd/langsmith@v${LANGSMITH_CLI_VERSION}

# Authenticate with a workspace-scoped service key (lsv2_sk_...) injected by your
# secrets manager at run time, never a personal access token and never a literal here.
# HTH Guide Excerpt: end cli-install-langsmith-cli

# HTH Guide Excerpt: begin cli-langgraph-cli-deploy
# Validate, then build, a LangGraph application with the official langgraph-cli
# (for CI, hash-pin langgraph-cli in the control 7.1 requirements.in instead)
pip install "langgraph-cli==0.4.32"

langgraph validate --config langgraph.json

# Build a container image tagged with the commit (pin the base image by digest in langgraph.json)
langgraph build --config langgraph.json --tag "myorg/myagent:$(git rev-parse --short HEAD)"
# HTH Guide Excerpt: end cli-langgraph-cli-deploy
