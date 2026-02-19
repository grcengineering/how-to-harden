#!/usr/bin/env python3
# HTH Google Workspace Control 1.01: Check 2-Step Verification Enrollment
# Profile: L1 | NIST: IA-2(1), IA-2(6)
# Requires: pip install google-api-python-client google-auth

# HTH Guide Excerpt: begin sdk-check-2sv
# Enable 2SV enforcement via Admin SDK
from googleapiclient.discovery import build
from google.oauth2 import service_account

SCOPES = ['https://www.googleapis.com/auth/admin.directory.user']
SERVICE_ACCOUNT_FILE = 'service-account.json'

credentials = service_account.Credentials.from_service_account_file(
    SERVICE_ACCOUNT_FILE, scopes=SCOPES)
credentials = credentials.with_subject('admin@yourdomain.com')

service = build('admin', 'directory_v1', credentials=credentials)

# Check 2SV enrollment status for users
results = service.users().list(
    customer='my_customer',
    maxResults=100,
    orderBy='email',
    projection='full'
).execute()

users = results.get('users', [])
for user in users:
    email = user['primaryEmail']
    is_enrolled = user.get('isEnrolledIn2Sv', False)
    is_enforced = user.get('isEnforcedIn2Sv', False)
    print(f"{email}: Enrolled={is_enrolled}, Enforced={is_enforced}")
# HTH Guide Excerpt: end sdk-check-2sv
