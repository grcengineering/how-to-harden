# SF-IP-01: Restrict Gainsight API Access to Salesforce via IP Allowlisting

**Profile Level:** ☑ L1 (Baseline) | ☐ L2 (Hardened) | ☐ L3 (Maximum Security)

**Platforms Involved:** Salesforce (primary) → Gainsight (integration)

**Last Updated:** 2025-12-12 | **Status:** ☑ Active | ☐ Deprecated | ☐ Under Review

---

## Description

Configure Salesforce's Network Access controls to restrict Gainsight's API access to their documented static egress IP addresses. This ensures that even if Gainsight's OAuth tokens for your Salesforce org are compromised, attackers cannot use them to access your data from infrastructure outside Gainsight's production network.

---

## Rationale

### Why This Matters

Third-party SaaS integrations like Gainsight require persistent OAuth tokens to access your Salesforce data. When an integration vendor is breached, attackers gain access to these stored tokens and can impersonate the integration to exfiltrate your data.

**IP allowlisting creates a network-layer boundary** that prevents stolen tokens from being used outside the integration vendor's known infrastructure—even if the tokens themselves are valid.

### Risk If Not Implemented

**Without IP allowlisting:** When Gainsight is compromised, attackers can use stolen OAuth tokens to access your Salesforce org from anywhere on the internet.

**With IP allowlisting:** Attackers must compromise both the OAuth tokens AND Gainsight's production infrastructure (or proxy through it), significantly raising the attack cost.

### Attack Relevance

- **Gainsight Supply Chain Attack (November 2025):** Attackers compromised Gainsight's infrastructure and exfiltrated data from 200+ customer Salesforce orgs using stored OAuth tokens. Organizations without IP allowlisting were fully compromised.
  - Victims included: F5, GitLab, CrowdStrike, and others
  - Attack vector: Stolen OAuth tokens used from attacker infrastructure
  - **Okta was protected** because they had IP allowlisting configured

- **Salesloft/Drift Supply Chain Attack (August 2025):** Same threat actors, same technique—compromised integration vendor, stolen OAuth tokens, data exfiltration from 700+ Salesforce orgs.
  - Attackers specifically searched for AWS credentials, VPN configs, and sensitive support case data
  - Attack persisted for ~6 months before detection
  - IP allowlisting would have blocked unauthorized API access

**Blast Radius Reduction:** Limits attacker's ability to use compromised credentials from their own infrastructure.

---

## Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | None | End users don't interact with integration directly |
| **Integration Functionality** | Low | Gainsight uses static IPs; low risk of disruption |
| **Maintenance Burden** | Low | Quarterly verification recommended; Gainsight rarely changes IPs |
| **Rollback Difficulty** | Easy | Remove IP ranges from trusted list in <5 minutes |

**Potential Issues:**
- **Issue 1: Gainsight changes egress IPs without notice**
  - Likelihood: Low (they notify customers of infrastructure changes)
  - Mitigation: Subscribe to Gainsight status page; set calendar reminder for quarterly verification
  - Symptom: Gainsight sync failures; "API request from unauthorized IP" errors in Salesforce logs

- **Issue 2: Accidental IP range misconfiguration blocks legitimate traffic**
  - Likelihood: Medium (typos in IP entry)
  - Mitigation: Test integration after configuration; verify with Gainsight CSM before applying
  - Symptom: Immediate sync failures after configuration change

**Rollback Procedure:**
1. Navigate to Setup → Security → Network Access
2. Find Gainsight IP entries (use "Description" field to identify)
3. Click "Delete" next to each entry
4. Test Gainsight sync to verify normal functionality restored
5. Re-implement carefully after identifying misconfiguration

---

## Prerequisites

**Required Access/Licenses:**
- [x] Salesforce System Administrator profile or "Manage Login Access Policies" permission
- [x] Salesforce Enterprise Edition or higher (Network Access not available in lower tiers)
- [x] Gainsight active subscription with documented egress IPs

**Required Information:**
- [x] Gainsight's current static egress IP addresses (obtain from Gainsight support documentation)
- [x] Gainsight Connected App ID in your Salesforce org (to verify integration after configuration)

**Dependencies:**
- [x] None (this is an independent control)

---

## Audit Procedure

### ClickOps Method

**Step 1: Navigate to Network Access**
- Path: Setup (gear icon) → Quick Find: "Network Access" → Network Access
- Expected: See "Trusted IP Ranges" section

**Step 2: Check for Gainsight IPs**
- Look for entries with descriptions like "Gainsight Production" or matching known Gainsight IPs
- Expected state: **Compliant** - All Gainsight egress IPs are listed with recent verification dates
- Non-compliant: No entries for Gainsight, or entries missing known IPs, or verification dates >6 months old

**Visual Check:**
```
Trusted IP Ranges
────────────────────────────────────────────────────────────
Start IP          | End IP            | Description
────────────────────────────────────────────────────────────
35.166.202.113   | 35.166.202.113    | Gainsight Prod 1 - verified 2025-12-12
52.35.87.209     | 52.35.87.209      | Gainsight Prod 2 - verified 2025-12-12
34.221.135.142   | 34.221.135.142    | Gainsight Prod 3 - verified 2025-12-12
────────────────────────────────────────────────────────────
✓ COMPLIANT: All Gainsight IPs present with recent verification
```

### Code Method

**Using Salesforce CLI (sf):**
```bash
# Authenticate to your Salesforce org
sf org login web --alias prod-org

# Query network access settings
sf data query --query "SELECT Id, IpAddress, IsActive FROM SecurityCustomBaseline" \
  --target-org prod-org --json

# Expected output (compliant):
# Should include entries for all Gainsight IPs with IsActive=true
```

**Using Salesforce API (curl):**
```bash
# Set variables
ORG_URL="https://your-instance.salesforce.com"
ACCESS_TOKEN="your_access_token"  # Obtain via OAuth flow

# Query LoginIpRange (stores Network Access trusted IPs)
curl -X GET "${ORG_URL}/services/data/v59.0/query?q=SELECT+Id,StartAddress,EndAddress+FROM+LoginIpRange" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json"

# Expected response (compliant):
# {
#   "records": [
#     {"StartAddress": "35.166.202.113", "EndAddress": "35.166.202.113"},
#     {"StartAddress": "52.35.87.209", "EndAddress": "52.35.87.209"},
#     {"StartAddress": "34.221.135.142", "EndAddress": "34.221.135.142"}
#   ]
# }
```

**Using Python with simple-salesforce:**
```python
from simple_salesforce import Salesforce

# Authenticate
sf = Salesforce(
    username='admin@yourorg.com',
    password='yourpassword',
    security_token='yourtoken'
)

# Query trusted IP ranges
query = "SELECT Id, StartAddress, EndAddress FROM LoginIpRange"
results = sf.query(query)

# Gainsight's documented IPs (as of 2025-12-12)
gainsight_ips = [
    "35.166.202.113",
    "52.35.87.209",
    "34.221.135.142"
]

# Check compliance
configured_ips = [r['StartAddress'] for r in results['records']]
missing_ips = set(gainsight_ips) - set(configured_ips)

if missing_ips:
    print(f"❌ NON-COMPLIANT: Missing Gainsight IPs: {missing_ips}")
else:
    print("✅ COMPLIANT: All Gainsight IPs are allowlisted")
```

**Automated Audit Script:**
See `/automation/scripts/salesforce/audit-network-access.py` for comprehensive audit script that:
- Checks all configured IP ranges
- Compares against known integration vendor IPs
- Identifies stale entries (>6 months without verification)
- Outputs compliance report

---

## Remediation

### ClickOps Method

**Overview:** Add Gainsight's static egress IPs to Salesforce's Trusted IP Ranges via the Setup console.

**Step-by-Step Instructions:**

**1. Verify Current Gainsight IPs**
   - Navigate to: [Gainsight IP Documentation](https://support.gainsight.com/Gainsight_NXT/Integrations/IP_Addresses)
   - Or contact your Gainsight Customer Success Manager
   - Document the current IPs (as of 2025-12-12):
     - `35.166.202.113/32` (US Production 1)
     - `52.35.87.209/32` (US Production 2)
     - `34.221.135.142/32` (US Production 3)
   - ⚠️ **Important:** IP addresses may vary by Gainsight deployment region (US vs EU)

**2. Navigate to Network Access Settings**
   - Path: Setup (gear icon) → Quick Find: "Network Access" → Network Access
   - You should see "Trusted IP Ranges" section
   - Screenshot: [See `/static/images/salesforce/network-access-menu.png`]

**3. Add Each Gainsight IP Range**

   For EACH IP address:

   - Click **"New"** button in Trusted IP Ranges section
   - Enter values:
     - **Start IP Address:** `35.166.202.113`
     - **End IP Address:** `35.166.202.113` (same as start for single IP)
     - **Description:** `Gainsight Production 1 - verified 2025-12-12`
   - Click **"Save"**
   - Repeat for remaining IPs:
     - IP 2: `52.35.87.209` (Description: "Gainsight Production 2 - verified 2025-12-12")
     - IP 3: `34.221.135.142` (Description: "Gainsight Production 3 - verified 2025-12-12")

   💡 **Tip:** Include verification date in description for future maintenance tracking

**4. Verify Configuration**
   - You should now see 3 entries in Trusted IP Ranges list
   - Confirm each IP is correct (typos will break integration)
   - Screenshot: [See `/static/images/salesforce/network-access-configured.png`]

**5. Test Gainsight Integration**
   - Navigate to Gainsight dashboard
   - Trigger a manual sync with Salesforce (refer to Gainsight documentation)
   - Verify data synchronization completes successfully
   - Check for errors in Gainsight sync logs
   - If sync fails, double-check IP addresses for typos

**Time to Complete:** ~10 minutes

---

### Code Method

Choose one of the following approaches based on your tooling:

#### Option 1: Salesforce CLI

```bash
# Authenticate to org
sf org login web --alias prod-org

# Note: Salesforce CLI doesn't directly support Network Access configuration
# You'll need to use Metadata API or manual configuration
# See Option 2 (API) or Option 3 (Terraform) for programmatic approaches

# Alternative: Use sf data create with Custom Metadata Types if configured
# (requires custom implementation in your org)
```

⚠️ **Limitation:** Salesforce CLI doesn't have native commands for Network Access. Use API or Terraform instead.

#### Option 2: Salesforce API

```bash
# Set variables
ORG_URL="https://your-instance.salesforce.com"
ACCESS_TOKEN="your_access_token"  # Obtain via OAuth flow

# Gainsight IPs
GAINSIGHT_IPS=(
  "35.166.202.113:35.166.202.113:Gainsight Production 1"
  "52.35.87.209:52.35.87.209:Gainsight Production 2"
  "34.221.135.142:34.221.135.142:Gainsight Production 3"
)

# Create trusted IP range for each
for ip_entry in "${GAINSIGHT_IPS[@]}"; do
  IFS=':' read -r start end description <<< "$ip_entry"

  curl -X POST "${ORG_URL}/services/data/v59.0/sobjects/LoginIpRange" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
      "StartAddress": "'${start}'",
      "EndAddress": "'${end}'",
      "Description": "'${description}' - verified '$(date +%Y-%m-%d)'"
    }'

  echo "✓ Added ${start}"
done

# Verify
curl -X GET "${ORG_URL}/services/data/v59.0/query?q=SELECT+StartAddress,EndAddress,Description+FROM+LoginIpRange+WHERE+Description+LIKE+'%Gainsight%'" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

#### Option 3: Infrastructure-as-Code (Terraform)

**File:** `terraform/salesforce/network-access.tf`

```hcl
# Terraform Salesforce Provider
# https://registry.terraform.io/providers/hashicorp/salesforce/latest/docs

terraform {
  required_providers {
    salesforce = {
      source  = "hashicorp/salesforce"
      version = "~> 0.1"
    }
  }
}

provider "salesforce" {
  # Configure via environment variables:
  # SALESFORCE_USERNAME
  # SALESFORCE_PASSWORD
  # SALESFORCE_SECURITY_TOKEN
  # SALESFORCE_INSTANCE_URL
}

# Gainsight Production IPs (verified 2025-12-12)
# Source: https://support.gainsight.com/Gainsight_NXT/Integrations/IP_Addresses

locals {
  gainsight_ips = {
    "production_1" = {
      start       = "35.166.202.113"
      end         = "35.166.202.113"
      description = "Gainsight Production 1 - verified 2025-12-12"
    }
    "production_2" = {
      start       = "52.35.87.209"
      end         = "52.35.87.209"
      description = "Gainsight Production 2 - verified 2025-12-12"
    }
    "production_3" = {
      start       = "34.221.135.142"
      end         = "34.221.135.142"
      description = "Gainsight Production 3 - verified 2025-12-12"
    }
  }
}

# Create trusted IP range for each Gainsight IP
resource "salesforce_login_ip_range" "gainsight" {
  for_each = local.gainsight_ips

  start_address = each.value.start
  end_address   = each.value.end
  description   = each.value.description
}

# Outputs for verification
output "gainsight_trusted_ips" {
  description = "Configured Gainsight IP allowlist"
  value = {
    for k, v in salesforce_login_ip_range.gainsight :
    k => "${v.start_address} - ${v.description}"
  }
}

# Data source to verify configuration
data "salesforce_login_ip_ranges" "all" {
  depends_on = [salesforce_login_ip_range.gainsight]
}

# Validation check
output "total_trusted_ip_ranges" {
  description = "Total number of trusted IP ranges configured"
  value       = length(data.salesforce_login_ip_ranges.all.ranges)
}
```

**Apply:**
```bash
# Initialize Terraform
cd terraform/salesforce
terraform init

# Review changes
terraform plan -out=network-access.tfplan

# Apply configuration
terraform apply network-access.tfplan

# Verify output
terraform output gainsight_trusted_ips
```

**State Management:**
```bash
# Import existing IP ranges (if configured manually)
terraform import salesforce_login_ip_range.gainsight["production_1"] <existing-id>

# Check current state
terraform state show salesforce_login_ip_range.gainsight["production_1"]
```

#### Option 4: Python Script (for custom automation)

**File:** `automation/scripts/salesforce/configure-gainsight-ips.py`

```python
#!/usr/bin/env python3
"""
Configure Gainsight IP allowlisting in Salesforce Network Access.

Usage:
    python configure-gainsight-ips.py --verify-only  # Audit mode
    python configure-gainsight-ips.py --apply        # Configure IPs

Environment variables required:
    SF_USERNAME, SF_PASSWORD, SF_SECURITY_TOKEN, SF_INSTANCE_URL
"""

import os
import sys
from datetime import date
from simple_salesforce import Salesforce
from typing import List, Dict

# Gainsight's documented egress IPs (as of 2025-12-12)
# Source: https://support.gainsight.com/Gainsight_NXT/Integrations/IP_Addresses
GAINSIGHT_IPS = [
    {"start": "35.166.202.113", "end": "35.166.202.113", "name": "Production 1"},
    {"start": "52.35.87.209", "end": "52.35.87.209", "name": "Production 2"},
    {"start": "34.221.135.142", "end": "34.221.135.142", "name": "Production 3"},
]

def get_salesforce_connection() -> Salesforce:
    """Establish Salesforce connection using environment variables."""
    try:
        sf = Salesforce(
            username=os.environ['SF_USERNAME'],
            password=os.environ['SF_PASSWORD'],
            security_token=os.environ['SF_SECURITY_TOKEN'],
            instance_url=os.environ.get('SF_INSTANCE_URL', 'https://login.salesforce.com')
        )
        print(f"✓ Connected to Salesforce org: {sf.sf_instance}")
        return sf
    except KeyError as e:
        print(f"❌ Missing environment variable: {e}")
        print("Required: SF_USERNAME, SF_PASSWORD, SF_SECURITY_TOKEN")
        sys.exit(1)

def get_current_ip_ranges(sf: Salesforce) -> List[Dict]:
    """Query current trusted IP ranges."""
    query = "SELECT Id, StartAddress, EndAddress FROM LoginIpRange"
    result = sf.query(query)
    return result['records']

def verify_configuration(sf: Salesforce) -> bool:
    """Check if Gainsight IPs are properly configured."""
    current_ranges = get_current_ip_ranges(sf)
    configured_ips = {r['StartAddress'] for r in current_ranges}
    required_ips = {ip['start'] for ip in GAINSIGHT_IPS}

    missing = required_ips - configured_ips

    if missing:
        print(f"❌ MISSING IPs: {missing}")
        return False
    else:
        print("✅ All Gainsight IPs are configured")
        return True

def configure_ips(sf: Salesforce, dry_run: bool = False) -> None:
    """Add Gainsight IPs to trusted ranges."""
    current_ranges = get_current_ip_ranges(sf)
    configured_ips = {r['StartAddress'] for r in current_ranges}

    today = date.today().isoformat()

    for ip_config in GAINSIGHT_IPS:
        if ip_config['start'] in configured_ips:
            print(f"⊙ Already configured: {ip_config['start']} ({ip_config['name']})")
            continue

        if dry_run:
            print(f"[DRY RUN] Would add: {ip_config['start']} - Gainsight {ip_config['name']}")
            continue

        try:
            sf.LoginIpRange.create({
                'StartAddress': ip_config['start'],
                'EndAddress': ip_config['end'],
                'Description': f"Gainsight {ip_config['name']} - verified {today}"
            })
            print(f"✓ Added: {ip_config['start']} (Gainsight {ip_config['name']})")
        except Exception as e:
            print(f"❌ Failed to add {ip_config['start']}: {e}")

def main():
    import argparse

    parser = argparse.ArgumentParser(description='Configure Gainsight IP allowlisting')
    parser.add_argument('--verify-only', action='store_true', help='Audit mode (no changes)')
    parser.add_argument('--apply', action='store_true', help='Apply configuration')
    parser.add_argument('--dry-run', action='store_true', help='Show what would change')

    args = parser.parse_args()

    sf = get_salesforce_connection()

    if args.verify_only:
        verify_configuration(sf)
    elif args.apply:
        configure_ips(sf, dry_run=False)
        print("\n" + "="*60)
        verify_configuration(sf)
    elif args.dry_run:
        configure_ips(sf, dry_run=True)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
```

**Usage:**
```bash
# Install dependencies
pip install simple-salesforce

# Set environment variables
export SF_USERNAME="admin@yourorg.com"
export SF_PASSWORD="yourpassword"
export SF_SECURITY_TOKEN="yourtoken"

# Audit current state
python automation/scripts/salesforce/configure-gainsight-ips.py --verify-only

# Dry run (show what would change)
python automation/scripts/salesforce/configure-gainsight-ips.py --dry-run

# Apply configuration
python automation/scripts/salesforce/configure-gainsight-ips.py --apply
```

**Time to Complete:** ~5 minutes (excluding initial IaC/script setup)

---

## Validation & Testing

### Functional Testing

After implementing IP allowlisting, verify that Gainsight can still access your Salesforce org normally.

**Test Plan:**
1. [ ] **Trigger Gainsight manual sync**
   - Navigate to Gainsight admin panel
   - Initiate manual Salesforce data sync
   - Expected: Sync completes successfully without errors

2. [ ] **Verify data flow**
   - Check that recent Salesforce records appear in Gainsight
   - Check that updates from Gainsight write back to Salesforce (if bidirectional sync enabled)
   - Expected: Data flows normally in both directions

3. [ ] **Monitor Salesforce Event Logs** (if Shield enabled)
   - Navigate to Setup → Event Monitoring → Event Log Files
   - Download LoginHistory log
   - Filter for Gainsight Connected App
   - Expected: See successful API calls from allowlisted IPs, no failed login attempts

### Security Testing

Verify that the IP allowlist actually blocks unauthorized access.

**Attack Simulation:**

⚠️ **Requires OAuth token access** - This test validates that IP allowlisting works but should only be performed in a sandbox/test environment with appropriate authorization.

```bash
# Obtain valid Gainsight OAuth token for your Salesforce org
# (In real attack, this would be stolen from Gainsight's infrastructure)
TOKEN="<gainsight-oauth-token>"

# Attempt API call from unauthorized IP (your laptop, NOT Gainsight infrastructure)
curl -X GET "https://your-instance.salesforce.com/services/data/v59.0/sobjects/Account" \
  -H "Authorization: Bearer ${TOKEN}"

# Expected response:
# {
#   "error": "invalid_grant",
#   "error_description": "authentication failure - API request from unauthorized IP"
# }

# ✓ Success: Request blocked due to IP allowlist
# ✗ Failure: Request succeeds (allowlist not enforced - verify configuration)
```

**From Gainsight's Infrastructure (should succeed):**
- Trigger normal Gainsight sync
- Expected: Gainsight requests from allowlisted IPs succeed

---

## Monitoring & Maintenance

### Ongoing Monitoring

**Alert Configuration:**

**Alert 1: Blocked API Attempts from Gainsight OAuth App**
- **Trigger:** API authentication failures for Gainsight Connected App
- **Detection:**
  - Salesforce Shield Event Monitoring: Query LoginHistory for `Status = 'Failed'` AND `Application = 'Gainsight'`
  - OR Salesforce Reports: Create custom report on Login History filtered by app + failure status
- **Response:**
  1. Check if Gainsight announced IP changes (status page, email notifications)
  2. Verify current Gainsight IPs via support documentation
  3. Update allowlist if legitimate IP change
  4. If no legitimate change, investigate potential compromise attempt

**Alert 2: Successful API Calls from Non-Allowlisted IPs**
- **Trigger:** Successful API call for Gainsight app from IP NOT in your allowlist
- **Detection:** Event Monitoring query (requires Salesforce Shield)
- **Response:** CRITICAL - potential bypass or misconfiguration
  1. Immediately verify IP allowlist configuration
  2. Check if Gainsight is using undocumented IPs
  3. Contact Gainsight support to confirm
  4. Consider temporarily revoking OAuth token if suspicious

**Example SOQL Queries (Salesforce Shield Event Monitoring):**

```sql
-- Query 1: Check for failed login attempts from Gainsight
SELECT Id, LoginTime, SourceIp, Status, LoginType, Application
FROM LoginHistory
WHERE Application = 'Gainsight'
  AND Status = 'Failed'
  AND LoginTime = LAST_N_DAYS:7
ORDER BY LoginTime DESC

-- Query 2: Identify source IPs currently being used by Gainsight
SELECT SourceIp, COUNT(Id) NumLogins, MAX(LoginTime) LastLogin
FROM LoginHistory
WHERE Application = 'Gainsight'
  AND Status = 'Success'
  AND LoginTime = LAST_N_DAYS:30
GROUP BY SourceIp
ORDER BY COUNT(Id) DESC

-- Expected: Should only see allowlisted IPs (35.166.202.113, 52.35.87.209, 34.221.135.142)
```

### Maintenance Schedule

**Quarterly Review:**
```markdown
## Gainsight IP Allowlist Verification - Q[X] [YEAR]

**Date:** ___________
**Performed by:** ___________

### Steps:
1. [ ] Contact Gainsight CSM or check https://support.gainsight.com/Gainsight_NXT/Integrations/IP_Addresses
2. [ ] Document current Gainsight production IPs:
       - IP 1: _______________
       - IP 2: _______________
       - IP 3: _______________
3. [ ] Compare against configured Salesforce Network Access IPs
4. [ ] If IPs changed:
       - [ ] Add new IPs to allowlist
       - [ ] Test Gainsight sync
       - [ ] Remove old IPs after 7-day overlap period
       - [ ] Document change in security log
5. [ ] If IPs unchanged:
       - [ ] Update "verified [DATE]" in description field
       - [ ] Document review completion
6. [ ] Run Event Monitoring query to verify no unexpected source IPs
7. [ ] Sign off: ___________

### Findings:
_______________________________________________________________________
```

**Annual Deep Review:**
- Review all trusted IP ranges (not just Gainsight)
- Remove stale/obsolete entries
- Verify integration vendors still provide static IPs
- Consider additional integrations that should be IP-restricted

**Trigger-Based Maintenance:**
- **When Gainsight sends infrastructure change notification:** Immediate verification and update
- **When Gainsight sync starts failing:** Check for unannounced IP changes
- **After M&A activity** (Gainsight acquired, etc.): Verify IP ownership/changes

---

## Compliance Mappings

| Framework | Control ID | Control Description | Relevance |
|-----------|-----------|---------------------|-----------|
| **SOC 2 Trust Services** | CC6.6 | Logical access security measures protect against threats from outside system boundaries | Network layer access control |
| **SOC 2 Trust Services** | CC6.1 | Entity implements logical access security to prevent unauthorized access | Restricts OAuth token abuse |
| **NIST 800-53 Rev 5** | AC-3 | Access Enforcement | Enforces authorized access based on network origin |
| **NIST 800-53 Rev 5** | SC-7 | Boundary Protection | Creates network boundary for API access |
| **NIST 800-53 Rev 5** | SC-7(5) | Deny by Default / Allow by Exception | Only allowlisted IPs permitted |
| **CIS Controls v8** | 13.3 | Deploy Network Intrusion Detection | Detects/blocks unauthorized network access |
| **CIS Controls v8** | 13.6 | Deny Communications with Known Malicious IP Addresses | Restricts to known-good IPs |
| **ISO 27001:2022** | A.8.3 | Information security in supplier relationships | Limits third-party integration access |
| **ISO 27001:2022** | A.5.23 | Information security for use of cloud services | Secures cloud integration |
| **PCI DSS v4.0** | 1.3.1 | Inbound traffic to CDE restricted | If Salesforce contains cardholder data |

**Audit Evidence to Collect:**
1. Screenshot of Salesforce Network Access configuration showing Gainsight IPs
2. Gainsight official IP documentation (dated)
3. Quarterly verification logs (see Maintenance Schedule checklist)
4. Event Monitoring query results showing successful logins only from allowlisted IPs
5. Incident response runbook for handling IP allowlist failures

---

## Related Patterns

**Complementary Controls** (implement together for defense-in-depth):

- [SF-OAUTH-01: Reduce Gainsight Connected App OAuth Scopes](../oauth-scoping/salesforce-gainsight-scopes.md)
  - Why: Even with IP allowlisting, limit *what data* Gainsight can access via least-privilege scoping
  - Combined effect: Network layer (IP) + authorization layer (OAuth scopes) defense

- [SF-MONITOR-01: Enable Salesforce Shield Event Monitoring for API Anomalies](../behavioral-monitoring/salesforce-shield-event-monitoring.md)
  - Why: Detect abnormal API usage patterns even from allowlisted IPs
  - Combined effect: Preventive (IP allowlist) + detective (anomaly monitoring)

- [SF-SESSION-01: Enforce Short-Lived Session Tokens for Connected Apps](../../platforms/salesforce/session-management.md)
  - Why: Even if IP bypass occurs, short session lifetime limits exposure window
  - Combined effect: Multiple time-bound controls

**Alternative Controls** (if IP allowlisting isn't feasible):

- **Certificate-Based Mutual Authentication** (Salesforce supports this for Connected Apps)
  - When to use: If integration vendor supports client certificates
  - Tradeoff: More complex setup, but stronger authentication than IP allowlisting
  - Salesforce doc: [Certificate and Key Management](https://help.salesforce.com/articleView?id=security_keys_about.htm)

- **API Gateway with Additional Authentication**
  - When to use: If Gainsight can route through your corporate API gateway
  - Tradeoff: Requires infrastructure investment, adds latency
  - Benefit: Centralized policy enforcement point

**Why IP Allowlisting is Preferred for this Use Case:**
- Gainsight uses static IPs (low maintenance)
- Salesforce native feature (no additional infrastructure)
- Effective against supply chain compromise (proven in Okta case)
- Low operational overhead

**Next Steps After Implementation:**

1. [Extend IP allowlisting to other third-party integrations](./salesforce-integration-ip-matrix.md) (Drift, HubSpot, etc.)
2. [Implement OAuth scope reduction for Gainsight](../oauth-scoping/salesforce-gainsight-scopes.md)
3. [Set up behavioral monitoring for API anomalies](../behavioral-monitoring/salesforce-shield-event-monitoring.md)

---

## Platform-Specific Notes

### Salesforce Edition Requirements

| Edition | Network Access Support | Notes |
|---------|----------------------|-------|
| Developer | ❌ | Not available |
| Essentials | ❌ | Not available |
| Professional | ❌ | Not available |
| Enterprise | ✅ | Full support |
| Unlimited | ✅ | Full support |
| Performance | ✅ | Full support + Shield event monitoring |

**If you're on Professional Edition or lower:**
- Upgrade to Enterprise (contact Salesforce account team)
- OR implement alternative controls:
  - Certificate-based mutual auth (if Gainsight supports)
  - More aggressive OAuth token rotation
  - Enhanced behavioral monitoring via third-party CASB/SSPM tools

### Salesforce Shield Considerations

**With Shield ($25/user/month add-on):**
- Event Monitoring provides detailed API access logs
- Can create real-time alerts on blocked IP attempts
- Field-level encryption for additional data protection

**Without Shield:**
- Still can implement IP allowlisting
- Monitoring limited to basic Login History (90-day retention)
- Consider third-party tools (AppOmni, Adaptive Shield, Obsidian) for enhanced monitoring

### Known Limitations

**Limitation 1: IP allowlisting applies org-wide**
- Description: Cannot selectively apply IP restrictions to only Gainsight (all API access affected unless using Login Hours/IP restrictions by profile)
- Workaround: Use Profile-based IP restrictions if needed for more granular control
- Salesforce doc: [Restrict Login IP Ranges by Profile](https://help.salesforce.com/articleView?id=admin_loginipranges.htm)

**Limitation 2: IPv6 support**
- Description: Salesforce Network Access currently supports IPv4 only
- Workaround: Ensure Gainsight is configured for IPv4 connectivity
- Impact: None (Gainsight currently uses IPv4)

**Limitation 3: No CIDR notation in UI**
- Description: Must enter individual IPs or ranges (cannot use CIDR like "35.166.202.0/24")
- Workaround: Convert CIDR to start/end IP notation before configuration
- Tool: Use [CIDR to IP Range converter](https://www.ipaddressguide.com/cidr)

**Limitation 4: No auto-update mechanism**
- Description: If Gainsight changes IPs, no automatic notification/update in Salesforce
- Workaround: Implement quarterly review process (see Maintenance Schedule)
- Enhancement: Consider building automation that polls Gainsight API/documentation for IP changes

---

## References

**Official Salesforce Documentation:**
- [Restrict Login IP Ranges](https://help.salesforce.com/articleView?id=admin_loginipranges.htm&type=5)
- [Connected Apps and OAuth](https://help.salesforce.com/articleView?id=connected_app_overview.htm&type=5)
- [Event Monitoring for API Usage](https://help.salesforce.com/articleView?id=event_monitoring.htm&type=5)

**Gainsight Documentation:**
- [Gainsight IP Addresses for Allowlisting](https://support.gainsight.com/Gainsight_NXT/Integrations/IP_Addresses)
- [Salesforce Integration Setup](https://support.gainsight.com/Gainsight_NXT/Integrations/Salesforce_Integration)

**Supply Chain Incident Reports:**
- [Okta: The Salesloft Incident - A Wake-Up Call for SaaS Security and IPs](https://www.okta.com/newsroom/articles/the-salesloft-incident--a-wake-up-call-for-saas-security-and-ips/)
- [Mandiant: UNC6395 Supply Chain Compromise Campaign](https://www.mandiant.com/resources/blog/unc6395-supply-chain-compromise)
- [Gainsight Security Incident Post-Mortem (November 2025)](https://status.gainsight.com/incidents/[incident-id])

**Community Resources:**
- [Salesforce Architects: Third-Party App Security Best Practices](https://architect.salesforce.com/design/decision-guides/integration-security)
- [AppOmni Blog: SaaS Supply Chain Attack Prevention](https://appomni.com/blog/saas-supply-chain-security/)

**Discussion:**
- GitHub Discussion: [#1 - Salesforce + Gainsight IP Allowlisting Implementation Experiences](https://github.com/[yourproject]/how-to-harden/discussions/1)

---

## Changelog

| Date | Version | Change | Author |
|------|---------|--------|--------|
| 2025-12-12 | 1.0 | Initial recommendation based on Gainsight/Drift incidents | [@your-github-handle] |

---

## Metadata (for tooling)

```yaml
---
id: sf-ip-01-salesforce-restricting-gainsight
title: "Restrict Gainsight API Access to Salesforce via IP Allowlisting"
platforms:
  primary: salesforce
  secondary: gainsight
profile_level: L1
attack_relevance:
  - incident: "salesloft-drift-2025"
    mitigation_type: "preventive"
  - incident: "gainsight-2025"
    mitigation_type: "preventive"
  - incident: "okta-survival-2025"
    mitigation_type: "successful-defense"
control_type:
  - ip-allowlisting
  - network-boundary
  - api-access-control
priority: high
effort: low
impact: low
automation_available: true
requires_paid_tier: true  # Salesforce Enterprise+ required
last_verified: "2025-12-12"
status: active
contributors:
  - "@your-github-handle"
compliance:
  soc2: ["CC6.6", "CC6.1"]
  nist_800_53: ["AC-3", "SC-7", "SC-7(5)"]
  cis_controls: ["13.3", "13.6"]
  iso_27001: ["A.8.3", "A.5.23"]
  pci_dss: ["1.3.1"]
---
```
