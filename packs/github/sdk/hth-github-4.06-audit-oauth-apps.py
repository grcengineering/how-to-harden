#!/usr/bin/env python3
# HTH GitHub Control 4.06: Audit OAuth Apps
# Profile: L1 | NIST: AC-6
# https://howtoharden.com/guides/github/#41-audit-and-restrict-oauth-app-access

# HTH Guide Excerpt: begin sdk-audit-oauth-apps
from github import Github
import os

g = Github(os.environ['GITHUB_TOKEN'])
org = g.get_organization('your-org')

print("Authorized OAuth Apps:")
print("=" * 60)

# Note: GitHub API doesn't provide full OAuth app list
# This must be done via UI or GraphQL API
# Placeholder for manual review tracking

apps = [
    {"name": "CircleCI", "last_used": "2025-12-01", "keep": True},
    {"name": "Old-CI-Tool", "last_used": "2023-06-15", "keep": False},
]

for app in apps:
    status = "Keep" if app["keep"] else "Revoke"
    print(f"{status}: {app['name']} (last used: {app['last_used']})")
# HTH Guide Excerpt: end sdk-audit-oauth-apps
