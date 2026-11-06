#!/usr/bin/env python3
# HTH Pack Contract: v1
#   control: fenic-2.1
#   guide: https://howtoharden.com/guides/fenic/#21-restrict-provider-identities-and-data-destinations
#   profile: L2
#   mode: mutating
#   requires: official fenic==0.13.0; FENIC_OPENROUTER_MODEL; FENIC_APPROVED_PROVIDERS(JSON nonempty string array); HTH_PROFILE_LEVEL=2+
# Sources: https://docs.fenic.ai/latest/topics/openrouter/
# https://github.com/typedef-ai/fenic/blob/v0.13.0/src/fenic/api/session/config.py
# Available in v0.13.0; Python-only official SDK exception. Emits a candidate, never deploys.
# Does not read provider credentials, construct a Session/SemanticConfig, fetch models or call inference.
# HTH Guide Excerpt: begin build-provider-routing-candidate
import importlib.metadata
import json
import os
import re
import sys


def unknown():
    print("Unknown: review profile, SDK version, model and approved provider inputs.", file=sys.stderr)
    raise SystemExit(2)


def main():
    if os.environ.get("HTH_PROFILE_LEVEL", "1") not in {"2", "3", "4"}:
        unknown()
    if importlib.metadata.version("fenic") != "0.13.0":
        unknown()
    model = os.environ.get("FENIC_OPENROUTER_MODEL", "")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._:/-]{1,199}", model):
        unknown()
    providers = json.loads(os.environ.get("FENIC_APPROVED_PROVIDERS", ""))
    if not isinstance(providers, list) or not 1 <= len(providers) <= 20:
        unknown()
    if any(not isinstance(p, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9 ._/-]{0,79}", p)
           for p in providers) or len(set(providers)) != len(providers):
        unknown()
    from fenic import OpenRouterLanguageModel

    candidate = OpenRouterLanguageModel(
        model_name=model,
        profiles={"approved": OpenRouterLanguageModel.Profile(
            models=[],
            provider=OpenRouterLanguageModel.Provider(only=providers, data_collection="deny"))},
        default_profile="approved",
    )
    # A model fragment, to merge under the reviewed SemanticConfig.language_models alias.
    print(candidate.model_dump_json(indent=2, exclude_none=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception:
        unknown()  # Do not expose raw SDK exceptions or injected inputs.
# HTH Guide Excerpt: end build-provider-routing-candidate
