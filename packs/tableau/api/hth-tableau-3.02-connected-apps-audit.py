#!/usr/bin/env python3
# HTH Tableau Control 3.2: Embedding Security
# Profile: L2 | NIST 800-53: AC-21
# https://howtoharden.com/guides/tableau/#32-embedding-security
#
# Audits direct-trust Connected Apps via the Tableau REST API: flags enabled
# apps with unrestricted embedding or an empty domain safelist.
#   Sign In (PAT):       POST /api/{version}/auth/signin
#                        https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_authentication.htm
#   List Connected Apps: GET /api/{version}/sites/{site-id}/connected-apps/direct-trust
#                        (fields: clientId, name, enabled, domainSafelist,
#                         unrestrictedEmbedding, projectIds, createdAt)
#                        https://help.tableau.com/current/api/rest_api/en-us/REST/rest_api_ref_connected_app.htm
#
# Requires site administrator permissions.
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


def field(element, name):
    """Read a documented connected-app field from an XML attribute or child element."""
    value = element.get(name)
    if value is not None:
        return value
    child = element.find(f"{{*}}{name}")
    return child.text if child is not None else None


# HTH Guide Excerpt: begin api-audit-connected-apps
# List every direct-trust connected app and flag the two configurations that
# defeat domain restriction: unrestrictedEmbedding=true (any site may embed)
# and an enabled app with an empty domainSafelist.
def audit_connected_apps(token, site_id):
    root = api_request(f"sites/{site_id}/connected-apps/direct-trust", token=token)
    apps = [e for e in root.iter() if e.tag.endswith("connectedApplication")]
    findings = []
    print(f"Direct-trust connected apps: {len(apps)}")
    for app in apps:
        name = field(app, "name")
        enabled = (field(app, "enabled") or "").lower() == "true"
        unrestricted = (field(app, "unrestrictedEmbedding") or "").lower() == "true"
        safelist = (field(app, "domainSafelist") or "").strip()
        print(f"  {name}: enabled={enabled} unrestrictedEmbedding={unrestricted} "
              f"domainSafelist={safelist or '(empty)'}")
        if enabled and unrestricted:
            findings.append(f"{name}: unrestricted embedding — any domain may host this app")
        elif enabled and not safelist:
            findings.append(f"{name}: enabled with an empty domain safelist")
    for f in findings:
        print(f"  FINDING: {f}")
    return findings
# HTH Guide Excerpt: end api-audit-connected-apps


def main():
    token, site_id = sign_in()
    try:
        findings = audit_connected_apps(token, site_id)
    finally:
        api_request("auth/signout", token=token, data=b"")
    if findings:
        print("FAIL: connected apps with unrestricted or unsafelisted embedding")
        sys.exit(1)
    print("PASS: every enabled connected app restricts embedding to a domain safelist")


if __name__ == "__main__":
    main()
