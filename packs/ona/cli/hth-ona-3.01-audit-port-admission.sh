#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-3.1
#   guide:   https://howtoharden.com/guides/ona/#31-restrict-port-admission-levels
#   profile: L1
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough)
# =============================================================================
# HTH Ona Control 3.1: Restrict Port Admission Levels — audit open ports
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 4.1, 12.2 | NIST 800-53 AC-3, SC-7 | SOC 2 CC6.6
# Source: https://ona.com/docs/ona/integrations/ports.md
#         https://ona.com/docs/ona/reference/cli.md
#
# WHY cli/: `ona environment port list` is the documented per-environment view of
# what is actually shared right now. The org-wide CAP (`maxPortAdmissionLevel`)
# is an API/Terraform surface and belongs to a different pack; a cap tells you
# what is permitted, this tells you what is exposed.
#
# WHAT IT DOES: enumerates environments, lists each one's open ports, and exits 1
# if ANY port is admitted to `everyone` (an unauthenticated public URL). It opens
# and closes nothing.
#
# -----------------------------------------------------------------------------
# THE FAIL-CLOSED FORM
# -----------------------------------------------------------------------------
#   ona environment port open 3000 --name my-app --admission creator_only
# The CLI already defaults to creator-only, but the default is not a guarantee:
# "If the runner is too old to enforce private access, the CLI opens the port for
# everyone instead and prints a warning to stderr." Passing --admission
# creator_only explicitly makes that case fail instead of silently going public.
# The same fallback exists in VS Code, which additionally "cannot request public
# access explicitly". Admission values: creator_only | organization | everyone.
#
# -----------------------------------------------------------------------------
# TRAPS
# -----------------------------------------------------------------------------
# T1  A WARNING ON STDERR IS THE ONLY SIGNAL of the public fallback, and it is
#     emitted at open time — long gone by the time you audit. That is exactly why
#     this pack reads the resulting admission level instead of trusting intent.
# T2  ADMISSION SPELLING DIFFERS BY SURFACE. The CLI flag takes `creator_only |
#     organization | everyone`; the API enum is `ADMISSION_LEVEL_CREATOR_ONLY |
#     _ORGANIZATION | _EVERYONE | _OWNER_ONLY | _UNSPECIFIED`. The JSON emitted by
#     `port list -o json` is not published, so the match below is a
#     case-insensitive test for "everyone" against either spelling.
# T3  ADMISSION_LEVEL_OWNER_ONLY IS DEPRECATED (vendor: "Use
#     ADMISSION_LEVEL_CREATOR_ONLY instead") but still appears in older data. It
#     is private, so it is not a finding — it is reported as legacy.
# T4  ORG POLICY CAN STILL BE LOOSER THAN THIS AUDIT. A clean run means nothing
#     is public *today*; without `maxPortAdmissionLevel` capped org-wide, the next
#     `--admission everyone` is one command away.
# T5  ON A RUNNER WITHOUT PORT AUTHENTICATION, access controls may be absent
#     entirely: "Until then, shared ports behave like `everyone`." Absence of an
#     admission value is therefore treated as public, never as compliant.
#
# Requires: `ona` on PATH and authenticated, jq. Reads only.
# Install:  brew install gitpod-io/tap/ona
# =============================================================================

set -euo pipefail

: "${ONA_TOKEN:?export ONA_TOKEN with a personal access token (Read-only is enough), then run: ona login}"

ONA_BIN="${ONA_BIN:-ona}"

command -v "${ONA_BIN}" >/dev/null 2>&1 || {
  echo "PRECONDITION: '${ONA_BIN}' not on PATH. brew install gitpod-io/tap/ona" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "PRECONDITION: jq required." >&2; exit 2; }
"${ONA_BIN}" whoami >/dev/null 2>&1 || {
  echo "PRECONDITION: not authenticated. Run 'ona login' or 'ona login --token \"\$ONA_TOKEN\"'." >&2
  exit 2; }

# HTH Guide Excerpt: begin cli-port-admission-audit
# Report every open port whose admission level is `everyone` — an unauthenticated
# public URL. Exit 1 on any finding. Nothing is opened or closed.
findings=0
ports_seen=0
envs_seen=0

# `-o json` is the documented machine-readable flag for any command. The envelope
# key is not published, so accept either {"environments":[…]} or a bare array.
env_ids="$("${ONA_BIN}" environment list -o json \
  | jq -r '(.environments? // .items? // .) | if type=="array" then .[] else empty end | .id // empty')"

if [ -z "${env_ids}" ]; then
  echo "COMPLIANT: no environments visible to this token — nothing is shared."
  exit 0
fi

while IFS= read -r env_id; do
  [ -n "${env_id}" ] || continue
  envs_seen=$((envs_seen + 1))

  # An environment that is stopped (or that this token cannot read ports on)
  # yields no port list; that is not a finding, so do not fail the whole run.
  ports_json="$("${ONA_BIN}" environment port list "${env_id}" -o json 2>/dev/null || true)"
  [ -n "${ports_json}" ] || continue

  # T2/T5: match "everyone" case-insensitively against both the CLI spelling and
  # the API enum, and treat a port carrying NO admission value as public, because
  # a runner without port authentication behaves like `everyone`.
  while IFS='|' read -r port admission; do
    [ -n "${port}${admission}" ] || continue
    ports_seen=$((ports_seen + 1))
    case "$(printf '%s' "${admission}" | tr 'A-Z' 'a-z')" in
      *everyone*)
        echo "FINDING: env …${env_id: -6} port ${port} admission=${admission} (public, unauthenticated)"
        findings=$((findings + 1))
        ;;
      ""|*unspecified*)
        echo "FINDING: env …${env_id: -6} port ${port} has no admission level — on a runner"
        echo "         without port authentication this behaves like 'everyone'."
        findings=$((findings + 1))
        ;;
      *owner_only*)
        echo "LEGACY:  env …${env_id: -6} port ${port} admission=${admission} (private, but the"
        echo "         OWNER_ONLY value is deprecated — reopen as creator_only)"
        ;;
      *)
        echo "ok:      env …${env_id: -6} port ${port} admission=${admission}"
        ;;
    esac
  done < <(printf '%s' "${ports_json}" \
    | jq -r '(.ports? // .items? // .) | if type=="array" then .[] else empty end
             | "\(.port // "?")|\(.admission // "")"')
done <<< "${env_ids}"

echo "---"
echo "environments checked: ${envs_seen} | open ports: ${ports_seen} | public findings: ${findings}"

if [ "${findings}" -gt 0 ]; then
  echo "Remediate by reopening each port fail-closed:"
  echo "  ona environment port open <port> --name <name> --admission creator_only"
  echo "or closing it: ona environment port close <port>"
  exit 1
fi
echo "COMPLIANT: no port is admitted to 'everyone'."
exit 0
# HTH Guide Excerpt: end cli-port-admission-audit
