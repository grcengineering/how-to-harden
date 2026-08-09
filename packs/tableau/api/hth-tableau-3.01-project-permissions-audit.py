#!/usr/bin/env python3
# HTH Tableau Control 3.1: Workbook Protection
# Profile: L1 | NIST 800-53: SC-28
# https://howtoharden.com/guides/tableau/#31-workbook-protection
#
# Audits project permission posture via the Tableau REST API: flags projects
# whose permissions are NOT locked to the project, and permission grants made
# to the broad "All Users" group.
#   Sign In (PAT):        POST /api/{version}/auth/signin
#                         https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_authentication.htm
#   Query Projects:       GET /api/{version}/sites/{site-id}/projects
#                         (contentPermissions: LockedToProject, ManagedByOwner,
#                          LockedToProjectWithoutNested)
#                         https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_projects.htm
#   Query Project Permissions: GET /api/{version}/sites/{site-id}/projects/{project-id}/permissions
#                         https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_permissions.htm
#   Query Groups:         GET /api/{version}/sites/{site-id}/groups
#                         https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_users_and_groups.htm
#
# Environment: TABLEAU_SERVER, TABLEAU_SITE, TABLEAU_PAT_NAME,
#   TABLEAU_PAT_SECRET, TABLEAU_API_VERSION (default 3.26).
import os
import sys
import urllib.request
import xml.etree.ElementTree as ET

SERVER = os.environ["TABLEAU_SERVER"].rstrip("/")
SITE = os.environ.get("TABLEAU_SITE", "")
API_VERSION = os.environ.get("TABLEAU_API_VERSION", "3.26")


def api_request(path, token=None, data=None):
    req = urllib.request.Request(f"{SERVER}/api/{API_VERSION}/{path}", data=data)
    req.add_header("Content-Type", "application/xml")
    if token:
        req.add_header("X-Tableau-Auth", token)
    with urllib.request.urlopen(req) as resp:
        return ET.fromstring(resp.read())


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


def paged(token, site_id, resource, tag):
    page = 1
    while True:
        root = api_request(
            f"sites/{site_id}/{resource}?pageSize=1000&pageNumber={page}", token=token
        )
        items = root.findall(f".//{{*}}{tag}")
        yield from items
        if len(items) < 1000:
            break
        page += 1


# HTH Guide Excerpt: begin api-flag-unlocked-projects
# Projects whose contentPermissions is ManagedByOwner let content owners
# re-open access through per-workbook overrides; LockedToProject prevents that.
def find_unlocked_projects(token, site_id):
    projects = []
    for p in paged(token, site_id, "projects", "project"):
        projects.append((p.get("id"), p.get("name"), p.get("contentPermissions")))
    unlocked = [p for p in projects if p[2] == "ManagedByOwner"]
    print(f"Projects: {len(projects)} total, {len(unlocked)} not locked to project")
    for pid, name, mode in unlocked:
        print(f"  UNLOCKED: {name} (contentPermissions={mode})")
    return projects, unlocked
# HTH Guide Excerpt: end api-flag-unlocked-projects


# HTH Guide Excerpt: begin api-flag-all-users-grants
# Any capability granted to the built-in "All Users" group exposes the project
# to the entire site. Resolve the group id, then scan every project's
# granteeCapabilities for grants against it.
def find_all_users_grants(token, site_id, projects):
    all_users_ids = {
        g.get("id")
        for g in paged(token, site_id, "groups", "group")
        if g.get("name") == "All Users"
    }
    findings = []
    for pid, name, _mode in projects:
        root = api_request(f"sites/{site_id}/projects/{pid}/permissions", token=token)
        for grantee in root.findall(".//{*}granteeCapabilities"):
            group = grantee.find("{*}group")
            if group is None or group.get("id") not in all_users_ids:
                continue
            for cap in grantee.findall(".//{*}capability"):
                findings.append((name, cap.get("name"), cap.get("mode")))
    print(f'"All Users" group grants across projects: {len(findings)}')
    for project_name, cap_name, mode in findings:
        print(f"  ALL-USERS GRANT: project={project_name} capability={cap_name} mode={mode}")
    return findings
# HTH Guide Excerpt: end api-flag-all-users-grants


def main():
    token, site_id = sign_in()
    try:
        projects, unlocked = find_unlocked_projects(token, site_id)
        findings = find_all_users_grants(token, site_id, projects)
    finally:
        api_request("auth/signout", token=token, data=b"")
    if unlocked or findings:
        print("FAIL: unlocked projects or All Users grants require review")
        sys.exit(1)
    print("PASS: all projects locked and no All Users grants found")


if __name__ == "__main__":
    main()
