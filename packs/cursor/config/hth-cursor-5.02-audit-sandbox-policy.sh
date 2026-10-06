#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-5.2
#   guide:   https://howtoharden.com/guides/cursor/#52-constrain-the-agents-approval-and-network-posture
#   profile: L2
#   mode:    read-only
#   requires: jq
# =============================================================================
# HTH Cursor Control 5.2: Constrain the Agent's Approval and Network Posture
# Profile Level: L2 (Walk) | NIST 800-53: SC-39, CM-7, SC-7
# Source: https://howtoharden.com/guides/cursor/#52-constrain-the-agents-approval-and-network-posture
#
# sandbox.json controls what a sandboxed terminal command can reach
# (https://cursor.com/docs/reference/sandbox). Two files merge, per-repo wins:
#   ~/.cursor/sandbox.json                 (per-user)
#   <workspace>/.cursor/sandbox.json       (per-repo, committed)
# Team-admin policy and Cursor's hardcoded rules layer on top and cannot be
# weakened by either file.
#
# Findings:
#   type = "insecure_none"               sandbox disabled entirely
#   networkPolicy.default = "allow"      all egress allowed when no rule matches
#   networkPolicy.allow contains "*"     any host
#   additionalReadwritePaths covers $HOME, "~", or "/"
#
# NOT READABLE HERE: the network MODE ("sandbox.json Only" / "sandbox.json +
# Defaults" / "Allow All") is an app setting, and "Allow All" ignores
# sandbox.json entirely. Confirm it in Settings > Agents > Approvals & Execution.
#
# Exit codes: 0 pass | 1 finding | 2 precondition
# =============================================================================

set -uo pipefail

command -v jq >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin cli-audit-sandbox-policy
FINDINGS=0
FILES_SEEN=0
for SB_FILE in "${HOME}/.cursor/sandbox.json" ".cursor/sandbox.json"; do
  [ -f "${SB_FILE}" ] || continue
  FILES_SEEN=$((FILES_SEEN + 1))
  if ! jq -e . "${SB_FILE}" >/dev/null 2>&1; then
    echo "ERROR: ${SB_FILE} is not valid JSON — Cursor will not apply it as written"
    exit 2
  fi
  echo "=== ${SB_FILE} ==="
  TYPE=$(jq -r '.type // "workspace_readwrite"' "${SB_FILE}")
  NET_DEFAULT=$(jq -r '.networkPolicy.default // "deny"' "${SB_FILE}")
  echo "  type=${TYPE}  networkPolicy.default=${NET_DEFAULT}"
  if [ "${TYPE}" = "insecure_none" ]; then
    echo "  FINDING: type=insecure_none disables the sandbox entirely"
    FINDINGS=$((FINDINGS + 1))
  fi
  if [ "${NET_DEFAULT}" = "allow" ]; then
    echo "  FINDING: networkPolicy.default=allow — any host not explicitly denied is reachable"
    FINDINGS=$((FINDINGS + 1))
  fi
  if jq -e '(.networkPolicy.allow // []) | index("*")' "${SB_FILE}" >/dev/null 2>&1; then
    echo "  FINDING: networkPolicy.allow contains \"*\""
    FINDINGS=$((FINDINGS + 1))
  fi
  while IFS= read -r P; do
    case "${P}" in
      "/"|\~|\~/|"${HOME}"|"${HOME}/"|'$HOME'|'${HOME}')
        echo "  FINDING: additionalReadwritePaths grants write to '${P}' — the agent can rewrite shell startup files and credentials"
        FINDINGS=$((FINDINGS + 1)) ;;
      *) echo "  readwrite: ${P}" ;;
    esac
  done < <(jq -r '(.additionalReadwritePaths // [])[]' "${SB_FILE}")
done

[ "${FILES_SEEN}" -gt 0 ] || echo "No sandbox.json found — Cursor's defaults apply (workspace read/write, network deny by default)"
echo "Also confirm the network mode is not 'Allow All' in Settings > Agents > Approvals & Execution — that mode ignores sandbox.json."
if [ "${FINDINGS}" -gt 0 ]; then
  echo "${FINDINGS} finding(s)"
  exit 1
fi
echo "PASS: no sandbox.json weakens the documented defaults"
exit 0
# HTH Guide Excerpt: end cli-audit-sandbox-policy
