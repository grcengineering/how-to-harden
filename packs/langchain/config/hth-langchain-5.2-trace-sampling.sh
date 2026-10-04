#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: langchain-5.2
#   guide:   https://howtoharden.com/guides/langchain/#52-configure-tracing-sampling
#   profile: L1
#   mode:    read-only
#   requires: none (sets process environment for the langsmith SDK; no LangSmith tenant state changes)
# =============================================================================
# HTH LangChain Control 5.2: Configure Tracing Sampling
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 SI-12 | SOC 2 CC6.7
#
# Source: https://docs.langchain.com/langsmith/sample-traces
# The SDK reads TRACING_SAMPLING_RATE with the LANGSMITH_ (or legacy LANGCHAIN_) prefix
# (langsmith client.py: get_env_var("TRACING_SAMPLING_RATE")). The spelling
# LANGCHAIN_TRACING_SAMPLE_RATE is read by nothing: setting it samples nothing and
# every trace keeps shipping. Source this file in the service's start-up environment.

# HTH Guide Excerpt: begin config-trace-sampling-env
# Head-based sampling for every langsmith Client in the process: 0 = none, 1 = all
export LANGSMITH_TRACING=true
export LANGSMITH_TRACING_SAMPLING_RATE=0.1

# Fail fast on a value the SDK would reject (it must be a float between 0 and 1).
# This file is meant to be sourced (`. hth-langchain-5.2-trace-sampling.sh`), hence `return`.
if ! awk -v r="${LANGSMITH_TRACING_SAMPLING_RATE}" 'BEGIN { exit !(r ~ /^(0(\.[0-9]+)?|1(\.0+)?)$/) }'; then
  echo "LANGSMITH_TRACING_SAMPLING_RATE must be between 0 and 1" >&2
  return 1
fi
# HTH Guide Excerpt: end config-trace-sampling-env
