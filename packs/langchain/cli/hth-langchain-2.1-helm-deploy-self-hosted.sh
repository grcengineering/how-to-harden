#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: langchain-2.1
#   guide:   https://howtoharden.com/guides/langchain/#21-self-host-langsmith-for-sensitive-data
#   profile: L3
#   mode:    mutating
#   requires: KUBECONFIG(cluster-admin on the target namespace), LANGSMITH_VERSION(pinned chart version), helm >= 3.12, the hardened values file from config/hth-langchain-2.1-helm-values-hardened.yml
# =============================================================================
# HTH LangChain Control 2.1: Self-Host LangSmith for Sensitive Data
# Profile Level: L3 (Run)
# Frameworks: CIS Controls 13.6 | NIST 800-53 SC-7, SC-28, AC-4
# Dependencies: helm (Kubernetes Helm, not an unrelated `helm` binary), kubectl
#
# Official chart repository: https://langchain-ai.github.io/helm/ (source github.com/langchain-ai/helm)
# Self-hosted LangSmith requires the Enterprise Self-Hosted add-on (license key).
#
# TRAPS
#  1. The chart ships no values.schema.json, so helm silently ignores any key it does
#     not know. `helm template` + the key check below catches a mistyped hardening key
#     before it reaches the cluster.
#  2. Pin LANGSMITH_VERSION to a version that `helm search repo langsmith --versions`
#     actually lists. CVE-2026-25750's advisory names 0.12.71, which the published
#     index does not contain (the 0.12.x line ends at 0.12.37); take the latest stable.

set -euo pipefail

: "${LANGSMITH_NAMESPACE:=langsmith}"
: "${LANGSMITH_VERSION:?Set LANGSMITH_VERSION to a published stable chart, e.g. 0.16.34 (as of 2026-09-24)}"
: "${LANGSMITH_VALUES:=hth-langchain-2.1-helm-values-hardened.yml}"

# HTH Guide Excerpt: begin cli-helm-add-repo
# Add the official LangChain Helm repository and list published chart versions
helm repo add langchain https://langchain-ai.github.io/helm/
helm repo update
helm search repo langchain/langsmith --versions | head -10
# HTH Guide Excerpt: end cli-helm-add-repo

# HTH Guide Excerpt: begin cli-helm-render-check
# Render first: prove the hardened values changed what they claim to change
helm template langsmith langchain/langsmith \
  --version "${LANGSMITH_VERSION}" \
  --namespace "${LANGSMITH_NAMESPACE}" \
  --values "${LANGSMITH_VALUES}" > rendered.yaml
grep -q 'type: LoadBalancer' rendered.yaml && { echo "FAIL: a LoadBalancer Service is still rendered"; exit 1; }
grep -q 'CORS_ALLOWED_ORIGINS: "\*"' rendered.yaml && { echo "FAIL: CORS still allows any origin"; exit 1; }
grep -q 'allowPrivilegeEscalation: false' rendered.yaml || { echo "FAIL: container securityContext did not render"; exit 1; }
echo "render check passed"
# HTH Guide Excerpt: end cli-helm-render-check

# HTH Guide Excerpt: begin cli-helm-deploy-langsmith
# Deploy LangSmith with the hardened values file (config pack for this control)
kubectl create namespace "${LANGSMITH_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install langsmith langchain/langsmith \
  --version "${LANGSMITH_VERSION}" \
  --namespace "${LANGSMITH_NAMESPACE}" \
  --values "${LANGSMITH_VALUES}" \
  --wait \
  --timeout 15m
# HTH Guide Excerpt: end cli-helm-deploy-langsmith
