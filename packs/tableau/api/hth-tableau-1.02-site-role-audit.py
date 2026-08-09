#!/usr/bin/env python3
# HTH Tableau Control 1.2: Implement Site Roles
# Profile: L1 | NIST 800-53: AC-3, AC-6
# https://howtoharden.com/guides/tableau/#12-implement-site-roles
#
# Audits Tableau Cloud/Server site-role assignments via the Tableau REST API.
#   Sign In (PAT):     POST /api/{version}/auth/signin
#                      https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_authentication.htm
#   Get Users on Site: GET /api/{version}/sites/{site-id}/users
#                      https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm
#   siteRole values: Creator, Explorer, ExplorerCanPublish, ServerAdministrator,
#                    SiteAdministratorExplorer, SiteAdministratorCreator,
#                    Unlicensed, ReadOnly, Viewer
#
# Environment: TABLEAU_SERVER (e.g. https://10ax.online.tableau.com),
#   TABLEAU_SITE (site contentUrl; empty string for the default site),
#   TABLEAU_PAT_NAME, TABLEAU_PAT_SECRET, TABLEAU_API_VERSION (default 3.26).
import os
import sys
import urllib.request
import xml.etree.ElementTree as ET
from collections import Counter

SERVER = os.environ["TABLEAU_SERVER"].rstrip("/")
SITE = os.environ.get("TABLEAU_SITE", "")
API_VERSION = os.environ.get("TABLEAU_API_VERSION", "3.26")

# Site roles that carry administrative reach and require explicit justification
ADMIN_ROLES = {"ServerAdministrator", "SiteAdministratorCreator", "SiteAdministratorExplorer"}


def api_request(path, token=None, data=None):
    req = urllib.request.Request(f"{SERVER}/api/{API_VERSION}/{path}", data=data)
    req.add_header("Content-Type", "application/xml")
    if token:
        req.add_header("X-Tableau-Auth", token)
    with urllib.request.urlopen(req) as resp:
        return ET.fromstring(resp.read())


# HTH Guide Excerpt: begin api-signin-pat
# Sign in with a personal access token; the response carries the session token
# (passed as X-Tableau-Auth on every later call) and the site id.
def sign_in():
    body = (
        '<tsRequest>'
        f'<credentials personalAccessTokenName="{os.environ["TABLEAU_PAT_NAME"]}"'
        f' personalAccessTokenSecret="{os.environ["TABLEAU_PAT_SECRET"]}">'
        f'<site contentUrl="{SITE}"/>'
        '</credentials></tsRequest>'
    )
    root = api_request("auth/signin", data=body.encode())
    creds = root.find("{*}credentials")
    return creds.get("token"), creds.find("{*}site").get("id")
# HTH Guide Excerpt: end api-signin-pat


# HTH Guide Excerpt: begin api-audit-site-roles
# Page through every user on the site and tally site roles. Administrative
# roles (ServerAdministrator, SiteAdministratorCreator/Explorer) are listed
# individually so each grant can be justified in an access review.
def audit_site_roles(token, site_id):
    roles = Counter()
    admins = []
    page = 1
    while True:
        root = api_request(
            f"sites/{site_id}/users?pageSize=1000&pageNumber={page}", token=token
        )
        users = root.findall(".//{*}user")
        for u in users:
            role = u.get("siteRole", "unknown")
            roles[role] += 1
            if role in ADMIN_ROLES:
                admins.append((u.get("name"), role, u.get("lastLogin", "never")))
        if len(users) < 1000:
            break
        page += 1

    print("Site role distribution:")
    for role, count in roles.most_common():
        print(f"  {role}: {count}")
    print(f"Administrative accounts ({len(admins)}):")
    for name, role, last_login in admins:
        print(f"  {role}\t{name}\tlastLogin={last_login}")
    return admins
# HTH Guide Excerpt: end api-audit-site-roles


def main():
    max_admins = int(os.environ.get("MAX_ADMINS", "3"))
    token, site_id = sign_in()
    try:
        admins = audit_site_roles(token, site_id)
    finally:
        api_request("auth/signout", token=token, data=b"")
    if len(admins) > max_admins:
        print(f"FAIL: {len(admins)} administrative accounts exceed threshold {max_admins}")
        sys.exit(1)
    print(f"PASS: administrative account count ({len(admins)}) within threshold ({max_admins})")


if __name__ == "__main__":
    main()
