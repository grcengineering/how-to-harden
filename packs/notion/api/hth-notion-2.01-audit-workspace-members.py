#!/usr/bin/env python3
# =============================================================================
# HTH Notion Control 2.1: Configure Workspace Access
# Profile: L1 | CIS Controls: 5.4 | NIST 800-53: AC-6
# https://howtoharden.com/guides/notion/#21-configure-workspace-access
#
# Audits workspace membership via the Notion REST API: lists every user,
# separates person users from bot (integration) users, and flags members
# whose email domain is outside the allowed corporate domains.
# Endpoint: GET https://api.notion.com/v1/users (paginated with
# start_cursor/page_size; response carries results/has_more/next_cursor).
# The integration must have user information capabilities to see emails —
# a 403 means the capability is missing.
# Docs: https://developers.notion.com/reference/get-users
# =============================================================================
import os

import requests

NOTION_TOKEN = os.environ["NOTION_TOKEN"]  # internal integration secret
ALLOWED_DOMAINS = {
    d.strip().lower()
    for d in os.environ.get("ALLOWED_EMAIL_DOMAINS", "example.com").split(",")
}

# HTH Guide Excerpt: begin api-audit-workspace-members
headers = {
    "Authorization": f"Bearer {NOTION_TOKEN}",
    "Notion-Version": "2026-03-11",
}

people, bots, flagged = [], [], []
cursor = None
while True:
    params = {"page_size": 100}
    if cursor:
        params["start_cursor"] = cursor
    response = requests.get(
        "https://api.notion.com/v1/users", headers=headers, params=params
    )
    response.raise_for_status()
    data = response.json()

    for user in data["results"]:
        if user["type"] == "bot":
            bots.append(user.get("name"))
        else:
            email = (user.get("person") or {}).get("email") or ""
            people.append(email)
            domain = email.split("@")[-1].lower() if "@" in email else ""
            if domain not in ALLOWED_DOMAINS:
                flagged.append(f"{user.get('name')} <{email or 'email not visible'}>")

    if not data.get("has_more"):
        break
    cursor = data["next_cursor"]

print(f"{len(people)} person user(s), {len(bots)} bot/integration user(s)")
for name in bots:
    print(f"  bot: {name}")
if flagged:
    print(f"\nWARN: {len(flagged)} member(s) outside allowed email domains:")
    for entry in flagged:
        print(f"  {entry}")
    print("Remove unauthorized members and restrict allowed email domains (control 2.1).")
# HTH Guide Excerpt: end api-audit-workspace-members
