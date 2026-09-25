#!/usr/bin/env python3
# HTH GitHub Control 4.06: Audit OAuth App Credential Authorizations
# Profile: L1 | NIST: AC-6
# https://howtoharden.com/guides/github/#41-audit-and-restrict-oauth-app-access
#
# Requires GitHub Enterprise Cloud with SAML SSO: the credential-authorizations
# endpoint is the only API that lists OAuth app authorizations for an organization.

# HTH Guide Excerpt: begin sdk-audit-oauth-apps
import os

from github import Auth, Github

g = Github(auth=Auth.Token(os.environ["GITHUB_TOKEN"]))
org_login = os.environ["GITHUB_ORG"]

# GET /orgs/{org}/credential-authorizations (paginated, 100 per page)
page = 1
oauth = []
while True:
    headers, data = g.requester.requestJsonAndCheck(
        "GET",
        f"/orgs/{org_login}/credential-authorizations",
        parameters={"per_page": 100, "page": page},
    )
    if not data:
        break
    oauth += [a for a in data if "oauth" in a.get("credential_type", "").lower()]
    page += 1

print(f"OAuth app authorizations in {org_login}: {len(oauth)}")
print("=" * 60)
for a in oauth:
    print(f"{a['login']}: scopes={a.get('scopes')} "
          f"authorized={a.get('credential_authorized_at')} "
          f"last_used={a.get('credential_accessed_at')}")
# HTH Guide Excerpt: end sdk-audit-oauth-apps
