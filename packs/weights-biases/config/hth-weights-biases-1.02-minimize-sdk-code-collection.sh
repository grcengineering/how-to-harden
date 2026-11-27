#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: weights-biases-1.2
#   guide: https://howtoharden.com/guides/weights-biases/#12-disable-automatic-source-code-saving-by-default
#   profile: L2
#   mode: mutating
#   requires: bash, approved workload process environment
# This sets the W&B SDK environment in the current shell. Source it rather than
# launching it; then start the reviewed SDK workload from that same shell.
# HTH weights-biases 1.2: Disable automatic source code saving by default
# Profile: L2 (Walk)
# Source: https://github.com/wandb/docs/blob/main/models/track/environment-variables.mdx
# HTH Guide Excerpt: begin minimize-sdk-code-collection
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf '%s\n' 'Source this configuration in the workload shell before starting Python.' >&2
  exit 2
fi
export WANDB_DISABLE_CODE=true
export WANDB_DISABLE_GIT=true
# HTH Guide Excerpt: end minimize-sdk-code-collection
