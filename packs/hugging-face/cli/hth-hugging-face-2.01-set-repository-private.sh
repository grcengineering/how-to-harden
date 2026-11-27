#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: hugging-face-2.1
#   guide: https://howtoharden.com/guides/hugging-face/#21-make-sensitive-repositories-private
#   profile: L1
#   mode: mutating
#   requires: hf CLI, huggingface_hub or curl with Python 3, scoped Hub credentials
# HTH hugging-face 2.1: Make sensitive repositories private
# Profile: L1 (Crawl)
# Guide: https://howtoharden.com/guides/hugging-face/
# Reference: https://huggingface.co/docs/huggingface_hub/en/package_reference/cli
# HTH Guide Excerpt: begin set-repository-private
set -euo pipefail
: "${HF_REPO_ID:?Set org/repository}"
: "${HF_REPO_TYPE:?Set model, dataset or space}"
: "${HF_CONFIRM_PRIVATE:?Set to the exact approved repo ID}"
[[ "$HF_REPO_ID" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*/[A-Za-z0-9][A-Za-z0-9._-]*$ && "$HF_CONFIRM_PRIVATE" == "$HF_REPO_ID" ]]
case "$HF_REPO_TYPE" in model|dataset|space) ;; *) exit 2 ;; esac
hf repos settings --repo-type "$HF_REPO_TYPE" --private "$HF_REPO_ID"
# HTH Guide Excerpt: end set-repository-private
