#!/usr/bin/env bash
# HTH LangChain Control 7.2: Use langsmith-cli for Reproducible Workspace Bootstrap
# Profile: L1 | NIST: CM-2
# https://howtoharden.com/guides/langchain/#72-langsmith-cli
#
# langsmith-cli (github.com/langchain-ai/langsmith-cli) is the official
# coding-agent-first CLI from langchain-ai for interacting with LangSmith.

set -euo pipefail

# HTH Guide Excerpt: begin cli-install-langsmith-cli
# Install the official LangSmith CLI from langchain-ai
pip install langsmith-cli

# Authenticate with a workspace-scoped Service Key (NOT a Personal Access Token)
export LANGSMITH_API_KEY="ls__sk_..."
export LANGSMITH_WORKSPACE_ID="..."
# HTH Guide Excerpt: end cli-install-langsmith-cli

# HTH Guide Excerpt: begin cli-langgraph-cli-deploy
# Deploy a LangGraph application using the official langgraph-cli
pip install -U langgraph-cli

# Validate graph definition before deploy
langgraph build --config langgraph.json

# Build container image (verify base image SHA pinning in Dockerfile)
langgraph build --tag myorg/myagent:$(git rev-parse --short HEAD)
# HTH Guide Excerpt: end cli-langgraph-cli-deploy
