#!/usr/bin/env python3
# HTH CyberArk Control 3.01: Secure API Authentication
# Profile: L1 | NIST: IA-5, SC-8
# Requires: pip install requests
# https://howtoharden.com/guides/cyberark/#31-secure-api-authentication

# HTH Guide Excerpt: begin sdk-cert-auth
# Secure CyberArk API authentication using certificate
import requests

PVWA_URL = "https://pvwa.company.com"
CERT_FILE = "/path/to/client.crt"
KEY_FILE = "/path/to/client.key"
CA_FILE = "/path/to/ca.crt"

def get_api_token():
    """Authenticate to CyberArk using certificate"""
    response = requests.post(
        f"{PVWA_URL}/PasswordVault/API/Auth/CyberArk/Logon",
        cert=(CERT_FILE, KEY_FILE),
        verify=CA_FILE,
        json={
            "username": "APIUser",
            "password": ""  # Certificate-based, no password
        }
    )
    return response.text.strip('"')

def get_credential(token, safe, account):
    """Retrieve credential securely"""
    response = requests.get(
        f"{PVWA_URL}/PasswordVault/API/Accounts?filter=safeName eq {safe}",
        headers={"Authorization": token},
        cert=(CERT_FILE, KEY_FILE),
        verify=CA_FILE
    )
    return response.json()
# HTH Guide Excerpt: end sdk-cert-auth
