# HTH Pack Contract: v1
#   control: glean-2.1
#   guide: https://howtoharden.com/guides/glean/#21-verify-custom-datasource-access-before-rollout
#   profile: L1
#   mode: read-only
#   requires: glean-indexing-sdk and custom datasource-scoped index token
# HTH Glean 2.1: Read custom datasource indexing status before testing access
# Profile: L1 (Crawl)
# Guide: https://howtoharden.com/guides/glean/
# Reference: https://developers.glean.com/libraries/indexing-sdk/status-and-debugging
# HTH Guide Excerpt: begin read-custom-datasource-status
import os
import re

from glean.indexing.push import StatusClient

base = os.environ["GLEAN_SERVER_URL"]
if not re.fullmatch(r"https://[A-Za-z0-9][A-Za-z0-9-]*-be\.glean\.com/?", base):
    raise SystemExit("Specify the verified Glean-hosted backend URL.")
if not os.environ["GLEAN_INDEXING_API_TOKEN"]:
    raise SystemExit("Use an approved datasource-scoped token.")
client = StatusClient(datasource=os.environ["GLEAN_DATASOURCE"])
print(client.get_datasource_status())
# HTH Guide Excerpt: end read-custom-datasource-status
