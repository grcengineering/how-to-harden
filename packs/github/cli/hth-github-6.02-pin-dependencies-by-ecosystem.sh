#!/usr/bin/env bash
# HTH GitHub Control 6.02: Audit Lockfiles for Pinned Dependencies
# Profile: L2 | SLSA: Build L3
# https://howtoharden.com/guides/github/#62-pin-dependencies-to-specific-versions-hash-verification
#
# Uses the gh CLI (GitHub's first-party CLI) to check each repository manifest for
# the lockfile that pins it by hash. Read-only; exits 1 when a lockfile is missing.
set -euo pipefail
: "${GITHUB_ORG:?Set GITHUB_ORG}"
: "${GITHUB_REPO:?Set GITHUB_REPO}"

# HTH Guide Excerpt: begin cli-audit-lockfiles
# Fail closed: an auth or network error must not read as "manifest absent"
gh api "/repos/${GITHUB_ORG}/${GITHUB_REPO}" --silent || {
  echo "ERROR: cannot read ${GITHUB_ORG}/${GITHUB_REPO} (gh auth or repository name)" >&2
  exit 2
}

# manifest:lockfile pairs; a manifest without its lockfile installs unpinned versions
MISSING=0
for pair in package.json:package-lock.json go.mod:go.sum Pipfile:Pipfile.lock pyproject.toml:poetry.lock; do
  manifest=${pair%%:*}; lockfile=${pair##*:}
  if gh api "/repos/${GITHUB_ORG}/${GITHUB_REPO}/contents/${manifest}" --silent 2>/dev/null; then
    if gh api "/repos/${GITHUB_ORG}/${GITHUB_REPO}/contents/${lockfile}" --silent 2>/dev/null; then
      echo "OK: ${manifest} is pinned by ${lockfile}"
    else
      echo "MISSING: ${manifest} has no ${lockfile}"
      MISSING=$((MISSING + 1))
    fi
  fi
done
[ "${MISSING}" -eq 0 ] || exit 1
# HTH Guide Excerpt: end cli-audit-lockfiles
