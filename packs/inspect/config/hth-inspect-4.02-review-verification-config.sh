#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: inspect-4.2
#   guide: https://howtoharden.com/guides/inspect/#42-review-the-exact-revision-and-verification-gaps
#   profile: L1
#   mode: read-only
#   requires: python3; trusted repository with tested review/verification skills
# Sources (2026-11-17): https://docs.inspect.com/pull-requests/review-agent
# https://docs.inspect.com/pull-requests/verification-agent
# Status: documented public configuration; no live review or verification run.
# Emits JSON (valid YAML) to stdout for ONE selected vendor-native config file.
# review -> .inspect/reviews/rules.yml ; verification -> .inspect/verification/config.yml
# No file writes and no API calls. Review the candidate and merge with existing
# settings via a PR, rather than overwriting existing rules. Protect configuration
# and skill changes: Inspect reads review rules from the PR head commit.
# A local skill file's existence is not evidence it is safe, correct, or tested.
# Roll back through version control; restart/re-run agents on the intended SHA.
# HTH Guide Excerpt: begin review-verification-config
set -euo pipefail
python3 - "$@" <<'PY'
import argparse
import json
from pathlib import Path
import re

p = argparse.ArgumentParser(description='Emit a review or verification candidate without applying it.')
p.add_argument('kind', choices=['review', 'verification'])
p.add_argument('--repo', required=True, help='Trusted repository root')
p.add_argument('--skill', required=True, help='Review: local skill slug. Verification: repository-relative SKILL.md path')
a = p.parse_args()
root = Path(a.repo).resolve()
if not root.is_dir():
    p.error('repo must be an existing directory')
if a.kind == 'review':
    if not re.fullmatch(r'[a-z0-9][a-z0-9-]*', a.skill):
        p.error('review skill must be a local non-namespaced slug')
    relative = Path('.claude') / 'skills' / a.skill / 'SKILL.md'
else:
    relative = Path(a.skill)
    if relative.is_absolute() or '..' in relative.parts or relative.name != 'SKILL.md':
        p.error('verification skill must be a repository-relative SKILL.md path without parent traversal')
resolved = (root / relative).resolve()
try:
    resolved.relative_to(root)
except ValueError:
    p.error('skill resolves outside the repository')
if not resolved.is_file():
    p.error('required local skill does not exist; create and test it before generating configuration')
if a.kind == 'review':
    config = {'version': 1, 'rules': [{'id': 'hth-security', 'skill': a.skill}]}
else:
    config = {
        'skill': relative.as_posix(),
        'model': 'auto',
        'instructions': 'Check changed authorization and failure behavior. Report each claim as verified, failed, or skipped with evidence tied to the pushed commit; do not present skipped checks as proof.',
    }
print(json.dumps(config, indent=2))
PY
# HTH Guide Excerpt: end review-verification-config
