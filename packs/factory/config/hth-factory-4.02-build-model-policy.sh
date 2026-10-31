#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: factory-4.2
#   guide: https://howtoharden.com/guides/factory/#42-approve-model-destinations-and-disable-unapproved-image-models
#   profile: L2
#   mode: read-only
#   requires: FACTORY_APPROVED_MODEL_IDS_FILE(reviewed nonempty JSON array of current model IDs), bash, jq, python3
# HTH Factory 4.2 — NIST AC-4, CM-7
# Source: https://docs.factory.com/enterprise/hierarchical-settings-and-org-control (available; verified 2026-10-30)
# Emits policy only. Unknown IDs may be silently dropped by Factory; verify the resolved catalog.
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin build-model-policy
hth_init 2
[[ -n "${FACTORY_APPROVED_MODEL_IDS_FILE:-}" ]] || hth_unknown 'provide FACTORY_APPROVED_MODEL_IDS_FILE'
python3 - "$FACTORY_APPROVED_MODEL_IDS_FILE" <<'PY'
import json
import sys
try:
    with open(sys.argv[1], encoding='utf-8') as source:
        ids = json.load(source)
    if not isinstance(ids, list) or not ids or any(
        not isinstance(x, str) or not x or x != x.strip() or len(x) > 256 or
        any(ord(c) < 32 for c in x) for x in ids
    ) or len(set(ids)) != len(ids):
        raise ValueError()
except (OSError, ValueError, TypeError):
    print('UNKNOWN: provide a nonempty array of unique current model IDs', file=sys.stderr)
    sys.exit(2)
print(json.dumps({
    'modelPolicy': {'allowedModelIds': ids, 'allowAllFactoryModels': False, 'allowCustomModels': False},
    'imageGenerationEnabled': False
}, indent=2))
PY
# HTH Guide Excerpt: end build-model-policy
