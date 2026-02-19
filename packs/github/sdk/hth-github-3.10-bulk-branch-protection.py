#!/usr/bin/env python3
# HTH GitHub Control 3.10: Bulk Branch Protection
# Profile: L1 | NIST: CM-3
# Requires: pip install PyGithub

# HTH Guide Excerpt: begin sdk-bulk-protect
from github import Github
import os

g = Github(os.environ['GITHUB_TOKEN'])
org = g.get_organization(os.environ.get('GITHUB_ORG', 'your-org'))

PROTECTED_BRANCHES = ['main', 'master', 'production', 'release']

for repo in org.get_repos():
    print(f"Processing: {repo.name}")

    for branch_name in PROTECTED_BRANCHES:
        try:
            branch = repo.get_branch(branch_name)

            # Apply protection
            branch.edit_protection(
                strict=True,
                contexts=["ci/test"],
                enforce_admins=True,
                dismiss_stale_reviews=True,
                require_code_owner_reviews=True,
                required_approving_review_count=1
            )

            print(f"  Protected: {branch_name}")
        except Exception as e:
            print(f"  Skipped {branch_name}: {e}")
# HTH Guide Excerpt: end sdk-bulk-protect
