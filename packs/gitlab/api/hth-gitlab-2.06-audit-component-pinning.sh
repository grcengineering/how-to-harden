#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: gitlab-2.6
#   guide:   https://howtoharden.com/guides/gitlab/#26-pin-and-vet-cicd-catalog-components
#   profile: L2
#   mode:    read-only
#   requires: GITLAB_TOKEN(personal access token, read_api scope; Reporter role or higher on the project), PROJECT_ID, REF(optional)
# =============================================================================
# HTH GitLab Control 2.6: Pin and Vet CI/CD Catalog Components
# Profile: L2 | NIST: SR-3, CM-7
# https://howtoharden.com/guides/gitlab/#26-pin-and-vet-cicd-catalog-components
#
# Read-only audit. Every call is a GET:
#   GET /projects/:id                                       default_branch, ci_config_path
#   GET /projects/:id/repository/files/:file_path/raw?ref=  the CI configuration,
#                                                           and every local file it includes
# Docs: docs.gitlab.com/api/repository_files, docs.gitlab.com/ci/components
#
# A component reference is <fqdn>/<project-path>/<component>@<version>. GitLab
# resolves <version> as: a commit SHA, a tag, a branch, ~latest, or a partial
# semantic version that selects the latest match. Only a full commit SHA is
# immutable.
#
# Scope: the project's CI configuration file plus every `include: local` file
# it reaches, recursively, at the same ref. Any include this pack cannot follow
# -- `project:`, `remote:`, `template:`, a local path built from a variable or
# a wildcard, a flow-style include list, or a nested `include:` such as a child
# pipeline's `trigger: include:` -- may pull in components the pack never saw,
# so the run ends UNKNOWN (exit 2) and names each one. It never reports clean
# on a configuration it only partly read.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (a file could not be
# read, the configuration lives outside this project, or an include was not
# followed).
# =============================================================================
source "$(dirname "$0")/common.sh"

PROJECT_ID="${PROJECT_ID:-${1:-}}"
: "${PROJECT_ID:?Set PROJECT_ID or pass as first argument}"

banner "2.6: Pin and Vet CI/CD Catalog Components (Project: ${PROJECT_ID})"
should_apply 2 || { increment_skipped; summary; exit 0; }

# HTH Guide Excerpt: begin api-audit-component-pinning
PROJECT=$(gl_get "/projects/${PROJECT_ID}") || {
  fail "2.6 GET /projects/${PROJECT_ID} failed -- check PROJECT_ID and token"; summary; exit 2; }
REF="${REF:-$(printf '%s' "${PROJECT}" | jq -r '.default_branch // empty')}"
CONFIG_PATH=$(printf '%s' "${PROJECT}" | jq -r '.ci_config_path // empty')
CONFIG_PATH="${CONFIG_PATH:-.gitlab-ci.yml}"
case "${CONFIG_PATH}" in
  *@*|*://*) fail "2.6 CI configuration lives outside this project (${CONFIG_PATH}) -- audit that project instead"; summary; exit 2 ;;
esac
ENC_REF=$(jq -rn --arg r "${REF}" '$r | @uri')

read_raw() {  # <repository path> -> file content at REF
  local enc
  enc=$(jq -rn --arg p "$1" '$p | @uri')
  gl_get "/projects/${PROJECT_ID}/repository/files/${enc}/raw?ref=${ENC_REF}"
}

# One "<kind><TAB><value>" line per include entry in a CI file. Kinds: local,
# component, project, remote, template, string (a bare path or URL), flow (an
# inline [..] or {..} include), nested (an indented include:, e.g. trigger:include).
list_includes() {
  awk -v q="'" '
    function indent(s) { match(s, /^ */); return RLENGTH }
    function strip(v) {
      sub(/[ \t]+#.*$/, "", v); gsub(/^[ \t]+|[ \t]+$/, "", v)
      if (substr(v, 1, 1) == "\"" || substr(v, 1, 1) == q) v = substr(v, 2, length(v) - 2)
      return v
    }
    { sub(/\r$/, "") }
    /^[ \t]*(#|$)/ { next }
    /^include:/ {
      v = $0; sub(/^include:[ \t]*/, "", v); v = strip(v)
      if (v == "") { inblk = 1; dash = -1; keycol = -1; next }
      if (v ~ /^[[{]/) print "flow\t" v; else print "string\t" v
      inblk = 0; next
    }
    /^[^ \t-]/ { inblk = 0 }
    !inblk && /^[ \t]+include:/ { v = $0; gsub(/^[ \t]+/, "", v); print "nested\t" v; next }
    inblk {
      ind = indent($0); line = $0; sub(/^ */, "", line)
      if (dash < 0 && keycol < 0) {
        if (line ~ /^-/) { dash = ind; t = line; sub(/^- */, "", t); keycol = ind + length(line) - length(t) }
        else keycol = ind
      }
      entry = ""
      if (dash >= 0 && ind == dash && line ~ /^-/) { entry = line; sub(/^- */, "", entry) }
      else if (ind == keycol) entry = line
      else next
      if (entry ~ /^(local|project|remote|template|component):/) {
        k = entry; sub(/:.*/, "", k); v = entry; sub(/^[a-z]+:[ \t]*/, "", v); print k "\t" strip(v)
      } else if (dash >= 0 && ind == dash && entry != "" && entry !~ /^[A-Za-z_]+:/) {
        print "string\t" strip(entry)
      }
    }'
}

FINDINGS=0; PINNED=0; FILES=0; MAX_FILES=50
QUEUE="${CONFIG_PATH}"   # newline-separated local files still to read
SEEN=""                  # newline-separated local files already read
UNFOLLOWED=""            # newline-separated includes this pack could not follow

scan_components() {  # <file label> <content>
  local ref version
  while IFS= read -r ref; do
    case "${ref}" in */*) ;; *) continue ;; esac   # a component reference always has a path
    version="${ref##*@}"
    if [ "${version}" = "${ref}" ]; then
      fail "2.6 ${ref}: no version ($1)"; FINDINGS=$((FINDINGS + 1))
    elif [[ "${version}" =~ ^[0-9a-f]{40}$ ]]; then
      pass "2.6 ${ref}: pinned to a commit SHA ($1)"; PINNED=$((PINNED + 1))
    elif [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
      warn "2.6 ${ref}: release tag -- acceptable fallback, a commit SHA is immutable ($1)"; PINNED=$((PINNED + 1))
    elif [ "${version}" = "~latest" ]; then
      fail "2.6 ${ref}: ~latest floats to every new release ($1)"; FINDINGS=$((FINDINGS + 1))
    elif [[ "${version}" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      fail "2.6 ${ref}: partial version floats to the latest matching release ($1)"; FINDINGS=$((FINDINGS + 1))
    else
      fail "2.6 ${ref}: '${version}' is a branch or other moving reference ($1)"; FINDINGS=$((FINDINGS + 1))
    fi
  done < <(printf '%s\n' "$2" | grep -oE "component:[[:space:]]*[\"']?[^\"'[:space:]#]+" \
            | sed -E "s/^component:[[:space:]]*[\"']?//")
}

while [ -n "${QUEUE}" ]; do
  FILE=$(printf '%s\n' "${QUEUE}" | head -n 1)
  QUEUE=$(printf '%s\n' "${QUEUE}" | sed '1d')
  if printf '%s\n' "${SEEN}" | grep -qxF -- "${FILE}"; then continue; fi
  SEEN=$(printf '%s\n%s' "${SEEN}" "${FILE}")
  FILES=$((FILES + 1))
  if [ "${FILES}" -gt "${MAX_FILES}" ]; then
    UNFOLLOWED=$(printf '%s\n%s' "${UNFOLLOWED}" "more than ${MAX_FILES} local files; stopped at ${FILE}")
    break
  fi
  CONTENT=$(read_raw "${FILE}") || {
    fail "2.6 Could not read ${FILE} at ref '${REF}'"; summary; exit 2; }
  scan_components "${FILE}" "${CONTENT}"
  while IFS=$'\t' read -r kind value; do
    case "${kind}" in
      component) ;;   # audited from the file text by scan_components
      local|string)
        case "${value}" in
          http://*|https://*) UNFOLLOWED=$(printf '%s\n%s' "${UNFOLLOWED}" "remote: ${value} (in ${FILE})") ;;
          *'$'*|*'*'*|'')     UNFOLLOWED=$(printf '%s\n%s' "${UNFOLLOWED}" "local: '${value}' (in ${FILE}; variable, wildcard, or empty path)") ;;
          *)                  QUEUE=$(printf '%s\n%s' "${QUEUE}" "${value#/}") ;;
        esac ;;
      *) UNFOLLOWED=$(printf '%s\n%s' "${UNFOLLOWED}" "${kind}: ${value} (in ${FILE})") ;;
    esac
  done < <(printf '%s\n' "${CONTENT}" | list_includes)
  QUEUE=$(printf '%s\n' "${QUEUE}" | sed '/^$/d')
done

NOT_FOLLOWED=$(printf '%s\n' "${UNFOLLOWED}" | sed '/^$/d' | wc -l | tr -d ' ')
info "2.6 ${FILES} file(s) read at '${REF}': ${PINNED} pinned, ${FINDINGS} floating component reference(s), ${NOT_FOLLOWED} include(s) not followed"
if [ "${NOT_FOLLOWED}" -gt 0 ]; then
  while IFS= read -r item; do
    [ -n "${item}" ] && fail "2.6 Not followed -- components in it were NOT audited: ${item}"
  done < <(printf '%s\n' "${UNFOLLOWED}")
fi
# HTH Guide Excerpt: end api-audit-component-pinning

if [ "${FINDINGS}" -gt 0 ]; then increment_failed; else increment_applied; fi
summary
[ "${NOT_FOLLOWED}" -eq 0 ] || exit 2
[ "${FINDINGS}" -eq 0 ] || exit 1
