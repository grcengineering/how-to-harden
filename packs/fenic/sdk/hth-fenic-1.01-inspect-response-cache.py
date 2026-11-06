#!/usr/bin/env python3
# HTH Pack Contract: v1
#   control: fenic-1.1
#   guide: https://howtoharden.com/guides/fenic/#11-disable-or-bound-the-native-llm-response-cache
#   profile: L2
#   mode: read-only
#   requires: official fenic==0.13.0; FENIC_SESSION_CONFIG_FILE(exported SessionConfig JSON); HTH_PROFILE_LEVEL=2+
# Source: https://github.com/typedef-ai/fenic/blob/v0.13.0/src/fenic/api/session/config.py
# Python is required by the only verified official SDK. This is not an admin API.
# Reads one local exported configuration. No Session, model catalog, provider call or deletion.
# 0 = exported cache disabled; 1 = cache enabled; 2 = unknown/not run.
# HTH Guide Excerpt: begin inspect-response-cache
import importlib.metadata
import json
import os
import stat
import sys


def unknown():
    print("Unknown: review profile, SDK version and exported SessionConfig JSON.", file=sys.stderr)
    raise SystemExit(2)


def main():
    profile = os.environ.get("HTH_PROFILE_LEVEL", "1")
    if profile not in {"2", "3", "4"}:
        unknown()
    if importlib.metadata.version("fenic") != "0.13.0":
        unknown()
    path = os.environ.get("FENIC_SESSION_CONFIG_FILE", "")
    if not os.path.isabs(path) or not hasattr(os, "O_NOFOLLOW"):
        unknown()
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | getattr(os, "O_NONBLOCK", 0))
    with os.fdopen(fd, "rb") as source:
        if not stat.S_ISREG(os.fstat(source.fileno()).st_mode):
            unknown()
        raw = source.read(1048577)
    if len(raw) > 1048576:
        unknown()
    config = json.loads(raw)
    if not isinstance(config, dict) or "semantic" not in config:
        unknown()
    semantic = config["semantic"]
    if semantic is None:
        cache = None
    elif isinstance(semantic, dict) and "llm_response_cache" in semantic:
        cache = semantic["llm_response_cache"]
    else:
        unknown()
    # Import actual public SDK classes, never Session or a model-bearing SemanticConfig.
    # Whole SessionConfig validation can fetch OpenRouter's model catalog.
    from fenic import LLMResponseCacheConfig, SemanticConfig

    if cache is None:
        if SemanticConfig(llm_response_cache=None).llm_response_cache is not None:
            unknown()
        print(json.dumps({"scope": "exported-config-only", "cache_enabled": False}))
        return 0
    if not isinstance(cache, dict) or set(cache) - set(LLMResponseCacheConfig.model_fields):
        unknown()  # Reject ignored `enabled` and other unknown keys, never call them compliant.
    parsed = LLMResponseCacheConfig(**cache)
    seconds = parsed.ttl_seconds()
    # The upstream validator's seconds/minutes branches do not enforce the documented cap.
    if not 1 <= seconds <= 2592000:
        unknown()
    print(json.dumps({"scope": "exported-config-only", "cache_enabled": True,
                      "ttl_seconds": seconds, "max_size_mb": parsed.max_size_mb}))
    return 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception:
        unknown()  # Do not print SDK errors, paths, raw configuration or credentials.
# HTH Guide Excerpt: end inspect-response-cache
