#!/usr/bin/env python3
# =============================================================================
# HTH Notion Control 3.1: Configure Sharing Controls
# Profile: L1 | CIS Controls: 3.3 | NIST 800-53: AC-3
# https://howtoharden.com/guides/notion/#31-configure-sharing-controls
#
# Finds pages published to the open web. The Notion page object carries a
# public_url field: "The public page URL if the page has been published to
# the web. Otherwise, null." Enumerates pages via POST /v1/search with the
# object=page filter. Search only returns pages shared with the integration,
# so grant the auditing integration access to the content you need audited.
# Docs: https://developers.notion.com/reference/page
#       https://developers.notion.com/reference/post-search
# =============================================================================
import os

import requests

NOTION_TOKEN = os.environ["NOTION_TOKEN"]  # internal integration secret

# HTH Guide Excerpt: begin api-audit-public-pages
headers = {
    "Authorization": f"Bearer {NOTION_TOKEN}",
    "Notion-Version": "2026-03-11",
}

public_pages = []
scanned = 0
payload = {
    "filter": {"property": "object", "value": "page"},
    "page_size": 100,
}
while True:
    response = requests.post(
        "https://api.notion.com/v1/search", headers=headers, json=payload
    )
    response.raise_for_status()
    data = response.json()

    for page in data["results"]:
        scanned += 1
        if page.get("public_url"):
            public_pages.append(page)

    if not data.get("has_more"):
        break
    payload["start_cursor"] = data["next_cursor"]

print(f"scanned {scanned} page(s) shared with this integration")
if not public_pages:
    print("PASS: no pages published to the web")
else:
    print(f"WARN: {len(public_pages)} page(s) reachable by anyone on the internet:")
    for page in public_pages:
        print(
            f"  {page['id']}\tlast_edited={page.get('last_edited_time')}\t"
            f"{page['public_url']}"
        )
    print("Unpublish any page not deliberately public (control 3.1).")
# HTH Guide Excerpt: end api-audit-public-pages
