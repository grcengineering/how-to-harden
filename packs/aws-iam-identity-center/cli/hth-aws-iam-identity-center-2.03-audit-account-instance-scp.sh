#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: aws-iam-identity-center-2.3
#   guide:   https://howtoharden.com/guides/aws-iam-identity-center/#23-restrict-account-instances-of-iam-identity-center
#   profile: L2
#   mode:    read-only
#   requires: AWS_REGION; AWS credentials in the Organizations management (or delegated policy administrator) account with organizations:ListRoots, organizations:ListPolicies, organizations:DescribePolicy, organizations:ListTargetsForPolicy, sso:ListInstances, sso:DescribeInstance
# =============================================================================
# HTH AWS IAM Identity Center Control 2.3: Restrict Account Instances of IAM Identity Center
# Profile: L2 | NIST: CM-7, AC-3 | Frameworks: CIS Controls 4.1, 6.8
# https://howtoharden.com/guides/aws-iam-identity-center/#23-restrict-account-instances-of-iam-identity-center
# Dependencies: aws (CLI v2), jq
#
# What "restricted" means here, per AWS ("Use Service Control Policies to control
# account instance creation"): an SCP that Denies sso:CreateInstance is attached
# somewhere in the organization, AND SCPs are enabled on the root -- an SCP on a
# root where the SERVICE_CONTROL_POLICY type is disabled enforces nothing.
# An action pattern counts when it matches sso:CreateInstance under IAM wildcard
# rules (sso:CreateInstance, sso:Create*, sso:*). NotAction statements are not
# evaluated and are reported for manual review rather than counted.
source "$(dirname "$0")/common.sh"

banner "2.3: Restrict Account Instances of IAM Identity Center"

should_apply 2 || { increment_skipped; summary; }

# HTH Guide Excerpt: begin cli-audit-account-instance-scp
# 1. SCPs must be enabled on the organization root.
ROOTS=$(aws_json organizations list-roots) || {
  fail "2.3 Cannot list organization roots (organizations:ListRoots) -- run from the management account"
  increment_failed
  summary
}
SCP_STATUS=$(echo "${ROOTS}" | jq -r '[(.Roots // [])[].PolicyTypes[]?
  | select(.Type == "SERVICE_CONTROL_POLICY") | .Status][0] // "DISABLED"')
if [ "${SCP_STATUS}" != "ENABLED" ]; then
  fail "2.3 Service control policies are ${SCP_STATUS} on the root -- no SCP can restrict account instances"
  increment_failed
  summary
fi

# 2. Find SCPs whose Deny statements cover sso:CreateInstance, and where they attach.
POLICIES=$(aws_json organizations list-policies --filter SERVICE_CONTROL_POLICY) || {
  fail "2.3 Cannot list SCPs (organizations:ListPolicies)"
  increment_failed
  summary
}
DENYING=0; ATTACHED=0; READ_ERRORS=0; NOTACTION=0
for POLICY_ID in $(echo "${POLICIES}" | jq -r '(.Policies // [])[].Id'); do
  DOC=$(aws_json organizations describe-policy --policy-id "${POLICY_ID}") || {
    fail "2.3 Cannot read SCP ${POLICY_ID} (organizations:DescribePolicy)"
    READ_ERRORS=$((READ_ERRORS + 1)); continue
  }
  NAME=$(echo "${DOC}" | jq -r '.Policy.PolicySummary.Name')
  VERDICT=$(echo "${DOC}" | jq -r '
    def arr: if type == "array" then . else [.] end;
    def glob: "^" + (gsub("\\*"; ".*") | gsub("\\?"; ".")) + "$";
    (.Policy.Content | fromjson | .Statement | arr | map(select(.Effect == "Deny"))) as $deny
    | if any($deny[]; (.Action // [] | arr | any(.[]; . as $p | "sso:CreateInstance" | test($p | glob; "i"))))
      then "deny"
      elif any($deny[]; has("NotAction")) then "notaction"
      else "none" end')
  case "${VERDICT}" in
    deny)
      DENYING=$((DENYING + 1))
      TARGETS=$(aws_json organizations list-targets-for-policy --policy-id "${POLICY_ID}") || {
        fail "2.3 Cannot list targets of SCP '${NAME}' (organizations:ListTargetsForPolicy)"
        READ_ERRORS=$((READ_ERRORS + 1)); continue
      }
      TARGET_SUMMARY=$(echo "${TARGETS}" | jq -r '(.Targets // []) | group_by(.Type)
        | map("\(length) \(.[0].Type)") | join(", ")')
      if [ -n "${TARGET_SUMMARY}" ]; then
        pass "2.3 SCP '${NAME}' denies sso:CreateInstance and is attached to: ${TARGET_SUMMARY}"
        ATTACHED=$((ATTACHED + 1))
      else
        warn "2.3 SCP '${NAME}' denies sso:CreateInstance but is attached to nothing"
      fi ;;
    notaction)
      NOTACTION=$((NOTACTION + 1))
      warn "2.3 SCP '${NAME}' uses NotAction in a Deny -- review manually for sso:CreateInstance" ;;
  esac
done
# HTH Guide Excerpt: end cli-audit-account-instance-scp

if [ "${READ_ERRORS}" -gt 0 ]; then
  fail "2.3 ${READ_ERRORS} SCP read(s) failed -- the audit is incomplete, not clean"
  increment_failed
elif [ "${ATTACHED}" -gt 0 ]; then
  pass "2.3 Account-instance creation is restricted by ${ATTACHED} attached SCP(s)"
  increment_applied
else
  fail "2.3 No attached SCP denies sso:CreateInstance -- member accounts can create account instances (${DENYING} unattached, ${NOTACTION} NotAction to review)"
  increment_failed
fi

# HTH Guide Excerpt: begin cli-report-multi-account-permissions
# Report whether multi-account permissions are enabled on the organization instance.
# UpdateInstance accepts only PermissionSetsEnabled=true: once on, it cannot be turned off.
INSTANCE=$(sso_admin describe-instance) || {
  fail "2.3 Cannot describe the IAM Identity Center instance (sso:DescribeInstance)"
  increment_failed
  summary
}
info "2.3 Multi-account permissions (PermissionSetsEnabled): $(echo "${INSTANCE}" \
  | jq -r 'if has("PermissionSetsEnabled") then (.PermissionSetsEnabled | tostring) else "not reported" end')"
# HTH Guide Excerpt: end cli-report-multi-account-permissions

summary
