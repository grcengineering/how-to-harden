#!/usr/bin/env bash
# HTH LangChain Control 2.1: Self-Host LangSmith for Sensitive Data
# Profile: L3 | NIST: SC-7, SC-28
# https://howtoharden.com/guides/langchain/#21-self-host-langsmith
#
# Official LangChain Helm charts: github.com/langchain-ai/helm
# Self-hosted LangSmith requires the Enterprise Self-Hosted add-on.

set -euo pipefail

: "${LANGSMITH_NAMESPACE:=langsmith}"
: "${LANGSMITH_VERSION:?Set LANGSMITH_VERSION (e.g., 0.13.4)}"

# HTH Guide Excerpt: begin cli-helm-add-repo
# Add the official LangChain Helm repository
helm repo add langchain https://langchain-ai.github.io/helm/
helm repo update

# Inspect available LangSmith chart versions before upgrade
helm search repo langsmith --versions | head -10
# HTH Guide Excerpt: end cli-helm-add-repo

# HTH Guide Excerpt: begin cli-helm-deploy-langsmith
# Deploy LangSmith with hardened values
kubectl create namespace "${LANGSMITH_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install langsmith langchain/langsmith \
  --version "${LANGSMITH_VERSION}" \
  --namespace "${LANGSMITH_NAMESPACE}" \
  --values langsmith-values.hardened.yaml \
  --wait \
  --timeout 15m
# HTH Guide Excerpt: end cli-helm-deploy-langsmith
