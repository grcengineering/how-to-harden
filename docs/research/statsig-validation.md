---
layout: default
title: "Statsig validation — 2026-11-05"
permalink: /research/statsig-validation/
---

# Statsig validation — 2026-11-05

Scope:13-guide controls,9 numbered packs supporting7 controls,5 types. Research and offline checks do not establish tenant enforcement or mark this guide as operationally validated. No Statsig credential, setting, integration, recording or deletion request was created.

| Check | Actual result |
|-------|---------------|
| `bun install --ignore-scripts` in packs/statsig/sdk | PASS; exact @statsig/web-analytics3.33.7 and locked dependencies installed, no SDK initialization |
| `bun test --timeout 30000 scripts/test-statsig-packs.test.ts` | PASS11tests,95assertions in2.23s after peer-review fixes; same component source copied with SHA-256 manifest to `/tmp/hth-statsig-component-T59CAk` and exact locked SDK freshly installed with `--frozen-lockfile --ignore-scripts`. Direct worktree attempts stalled on SDK file reads and were stopped, not counted as passes. An earlier fixture used the wrong request-ID environment name and was corrected |
| Transport/identity boundary | Fake curl only; checked fixed HTTPS origins/methods, credential stdin rather than argv, no redirects/origin override, profile refusal before requests, malformed/denied responses and secret projection |
| Completeness/privacy | Tested multipage keys, malicious/duplicate pagination, duplicate key fingerprints, incomplete totals, false review flags, private mode0600 evidence and existing file/symlink preservation |
| Native parameters/lifecycle | Tested private-user object moves and conflicting/unsupported shapes, bounded version-only CLI, read-only deletion status PENDING/COMPLETE versus UNKNOWN; no deletion submission |
| Actual SDK | Imported and constructed the released AutoCapture plugin and used its actual released metadata builder with synthetic browser state. Normal native page accepted; query-injected pageUrl/page_url/current_url, forged fields, mismatched browser location and missing browser denied. No client initialization, browser recorder or network |
| ShellCheck | PASS all seven Bash files including structural helper (six entrypoints) |
| `terraform fmt -check -recursive` | PASS |
| Provider installation | Initial sandbox DNS failure; escalated public download of exact2.2.1 succeeded, developer signature verified by Terraform, lock retained |
| `terraform validate` | PASS with real2.2.1 Darwinarm64 provider. Initial sandbox plugin handshake failed; same command passed with local plugin IPC allowed |
| `terraform test` | PASS5mocked plan tests: default no-op, explicit closed project without rename, empty project refusal, preserving other review flags, rejecting Warehouse-only flags for Cloud. Initial sandbox provider IPC failed; escalated mock-only run passed |

Generated YAML, whole-guide lint, Jekyll build and rendered page/pack inspection are integrated into the OpenAI-family validation record after handoff. Their results must not be inferred from this component record. No live environment checks or real provider plan/apply occurred. Tenant edition/rollout, SSO/SCIM recovery, complete key visibility, audit export contract, application consent/payloads/storage/fallback and warehouse-specific setup remain deployment checks. No complete audit schema or production SIEM mapping was obtained.

Independent peer review caught three prepublication defects: a nonnative SDK URL fixture that missed query-spoofed metadata, incomplete consent guidance about disabled-event buffering/replay, and silently dropped JavaScript magic keys in the private-user generator. The filter now binds authorization to actual browser location and matching native fields, the guide explicitly gates initialization/event generation when consent requires it, and the generator rejects magic keys as a documented local restriction. Regression fixtures exercise the actual released metadata builder and the rejected primitive `__proto__` case. No tenant behavior or general consent enforcement is inferred from those checks.
