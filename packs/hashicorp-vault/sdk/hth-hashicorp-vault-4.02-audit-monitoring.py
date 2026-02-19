#!/usr/bin/env python3
# HTH HashiCorp Vault Control 4.2: Configure Audit Log Alerting
# Profile: L1 | NIST: AU-2, AU-3
# https://howtoharden.com/guides/hashicorp-vault/#42-configure-audit-log-alerting

# HTH Guide Excerpt: begin sdk-audit-monitoring
import json
from collections import defaultdict
from datetime import datetime, timedelta

def detect_mass_secret_access(logs, threshold=100, window_minutes=5):
    """Detect unusual volume of secret reads"""
    access_counts = defaultdict(int)
    window_start = datetime.utcnow() - timedelta(minutes=window_minutes)

    for log in logs:
        if log.get('request', {}).get('path', '').startswith('secret/'):
            if log['request']['operation'] == 'read':
                accessor = log.get('auth', {}).get('accessor', 'unknown')
                access_counts[accessor] += 1

    alerts = []
    for accessor, count in access_counts.items():
        if count > threshold:
            alerts.append(f"High secret access: {accessor} read {count} secrets")

    return alerts

def detect_auth_failures(logs, threshold=10, window_minutes=5):
    """Detect brute force attempts"""
    failures = defaultdict(int)

    for log in logs:
        if log.get('type') == 'response':
            if not log.get('response', {}).get('succeeded', True):
                remote_addr = log.get('request', {}).get('remote_address', 'unknown')
                failures[remote_addr] += 1

    return [f"Auth failures from {ip}: {count}"
            for ip, count in failures.items() if count > threshold]
# HTH Guide Excerpt: end sdk-audit-monitoring
