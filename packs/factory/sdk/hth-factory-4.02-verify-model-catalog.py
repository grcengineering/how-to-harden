#!/usr/bin/env python3
# HTH Pack Contract: v1
#   control: factory-4.2
#   guide: https://howtoharden.com/guides/factory/#42-approve-model-destinations-and-disable-unapproved-image-models
#   profile: L2
#   mode: read-only
#   requires: Python 3.10+, official droid-sdk and Droid CLI, authenticated CLI or injected FACTORY_API_KEY, FACTORY_PROJECT_DIR(trusted absolute repository), FACTORY_APPROVED_MODEL_IDS_FILE, FACTORY_MODEL_OUTPUT(new private file)
# HTH Factory 4.2 — NIST AC-4, CM-7
# Source: https://docs.factory.com/sdk/python (available; verified 2026-10-30)
# list_models discovers the catalog without creating a session or making a model call.
import asyncio
import json
import os
from pathlib import Path
import sys


def unknown(message):
    print('UNKNOWN: ' + message, file=sys.stderr)
    raise SystemExit(2)


# HTH Guide Excerpt: begin verify-model-catalog
async def main():
    level = os.environ.get('HTH_PROFILE_LEVEL', '1')
    if level not in ('1', '2', '3', '4') or int(level) < 2:
        unknown('requires HTH_PROFILE_LEVEL >= 2')
    project = Path(os.environ.get('FACTORY_PROJECT_DIR', ''))
    output = os.environ.get('FACTORY_MODEL_OUTPUT', '')
    if not project.is_absolute() or not project.is_dir() or not output:
        unknown('provide a trusted absolute FACTORY_PROJECT_DIR and new FACTORY_MODEL_OUTPUT')
    try:
        with open(os.environ['FACTORY_APPROVED_MODEL_IDS_FILE'], encoding='utf-8') as source:
            approved = json.load(source)
        if not isinstance(approved, list) or not approved or any(
            not isinstance(x, str) or not x or x != x.strip() for x in approved
        ) or len(set(approved)) != len(approved):
            raise ValueError()
    except (KeyError, OSError, ValueError, TypeError):
        unknown('provide a nonempty JSON array of unique approved model IDs')
    try:
        from droid_sdk import list_models
        models = await asyncio.wait_for(list_models(include_disabled=True, cwd=project), timeout=60)
        if not isinstance(models, list) or any(
            not isinstance(m.id, str) or not m.id or type(m.disabled) is not bool for m in models
        ) or len({m.id for m in models}) != len(models):
            raise ValueError()
    except Exception:
        unknown('SDK discovery failed; check supported versions, authentication and policy')
    available = {m.id for m in models if not m.disabled}
    report = {'approved': approved, 'available': sorted(available),
              'unapproved': sorted(available - set(approved)),
              'missingOrDisabled': sorted(set(approved) - available)}
    try:
        fd = os.open(output, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    except OSError:
        unknown('output must be a new file in a trusted existing directory')
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as target:
            json.dump(report, target, indent=2)
            target.write('\n')
    except OSError:
        os.unlink(output)
        unknown('could not save complete catalog evidence')
    if report['unapproved'] or report['missingOrDisabled']:
        print('DRIFT: selectable models differ from the reviewed list; inspect private evidence.')
        return 1
    print('MATCH: selectable model IDs match the reviewed list in this account and project.')
    return 0


if __name__ == '__main__':
    sys.exit(asyncio.run(main()))
# HTH Guide Excerpt: end verify-model-catalog
