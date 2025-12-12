# [Recommendation ID]: [Title]

**Profile Level:** [ ] L1 (Baseline) | [ ] L2 (Hardened) | [ ] L3 (Maximum Security)

**Platforms Involved:** [Primary Platform] → [Integration/Secondary Platform]

**Last Updated:** YYYY-MM-DD | **Status:** [ ] Active | [ ] Deprecated | [ ] Under Review

---

## Description

[2-3 sentences describing WHAT to configure. Be specific about the control being implemented.]

Example: "Configure IP allowlisting on Salesforce API access to restrict third-party integrations to their documented egress IP ranges. This prevents compromised integrations from accessing your Salesforce data from attacker-controlled infrastructure."

---

## Rationale

### Why This Matters
[Explain the security benefit and threat model]

### Risk If Not Implemented
[Specific attack scenario that this prevents/mitigates]

### Attack Relevance
[Map to real-world incidents where this control would have helped]

Example:
- **Salesloft/Drift Supply Chain Attack (Aug 2025):** Attackers exfiltrated data from 700+ Salesforce orgs using stolen OAuth tokens. Okta was protected because they had IP allowlisting configured.
- **Attack Vector Blocked:** Prevents OAuth token abuse from non-approved infrastructure
- **Blast Radius Reduction:** Limits damage if integration vendor is compromised

---

## Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | [None / Low / Medium / High] | [What users will notice] |
| **Integration Functionality** | [None / Low / Medium / High] | [What might break] |
| **Maintenance Burden** | [Low / Medium / High] | [Ongoing effort required] |
| **Rollback Difficulty** | [Easy / Moderate / Complex] | [How to undo if needed] |

**Potential Issues:**
- [Issue 1]: [Description and mitigation]
- [Issue 2]: [Description and mitigation]

**Rollback Procedure:**
[Quick steps to disable this control if it causes problems]

---

## Prerequisites

**Required Access/Licenses:**
- [ ] [Specific admin role needed]
- [ ] [Platform edition/tier required, e.g., "Salesforce Enterprise Edition or higher"]
- [ ] [Feature flags that must be enabled]

**Required Information:**
- [ ] [Data you need to gather before implementing, e.g., "Integration vendor's static egress IP addresses"]

**Dependencies:**
- [ ] [Other controls that must be configured first]

---

## Audit Procedure

### ClickOps Method

**Step 1:** [Navigation path in console]
[Screenshot placeholder or detailed click-path]

**Step 2:** [What to look for]
Expected state: [Description of secure configuration]

**Example:**
```
Setup → Security → Network Access → Trusted IP Ranges
✓ Expected: See entries for [Integration Name] IPs
✗ Non-compliant: No trusted IP ranges configured
```

### Code Method

**Using [Platform CLI]:**
```bash
# Check current IP allowlist configuration
[CLI command to audit]

# Expected output:
[Sample output showing compliant state]
```

**Using [Platform API]:**
```bash
curl -X GET "https://[platform-api-endpoint]/network-access" \
  -H "Authorization: Bearer $TOKEN"

# Expected response (compliant):
[JSON showing secure configuration]
```

**Using Terraform:**
```hcl
# Check current state
terraform state show [resource.name]

# Expected attributes:
[Relevant terraform state fields]
```

**Automated Audit Script:**
[Link to script in `/automation/scripts/` that checks compliance]

---

## Remediation

### ClickOps Method

**Overview:** [One sentence describing the GUI-based approach]

**Step-by-Step Instructions:**

1. **Navigate to [Console Section]**
   - Path: [Exact navigation path]
   - Screenshot: [Link or placeholder]

2. **[Action Description]**
   - Click [Button/Menu]
   - Enter the following values:
     - **Field Name:** `[value]`
     - **Field Name:** `[value]`
   - Screenshot: [Link or placeholder]

3. **Verify Configuration**
   - [How to confirm it worked]
   - Expected result: [What you should see]

4. **Test Integration**
   - [How to verify integration still works]
   - [Expected behavior]

**Time to Complete:** ~[X] minutes

### Code Method

Choose one of the following approaches based on your tooling:

#### Option 1: Platform CLI

```bash
# Set configuration via CLI
[CLI command with inline comments explaining each flag]

# Example:
# salesforce network create trusted-ip \
#   --start-ip 35.166.202.113 \
#   --end-ip 35.166.202.113 \
#   --description "Gainsight Production - verified 2025-12-12"

# Verify
[CLI command to check]
```

#### Option 2: Platform API

```bash
# Using curl (adapt for your API client)
curl -X POST "https://[platform-api]/network-access/trusted-ips" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "startIpAddress": "35.166.202.113",
    "endIpAddress": "35.166.202.113",
    "description": "Gainsight Production - verified 2025-12-12"
  }'

# Verify
curl -X GET "https://[platform-api]/network-access/trusted-ips" \
  -H "Authorization: Bearer $TOKEN"
```

#### Option 3: Infrastructure-as-Code (Terraform)

**File:** `terraform/salesforce/network-access.tf`

```hcl
# Terraform configuration
resource "salesforce_network_access" "gainsight_ips" {
  for_each = toset([
    "35.166.202.113/32",
    "52.35.87.209/32",
    "34.221.135.142/32"
  ])

  ip_range    = each.value
  description = "Gainsight Production - verified 2025-12-12"
}

# Outputs for verification
output "trusted_ip_ranges" {
  value = [for range in salesforce_network_access.gainsight_ips : range.ip_range]
}
```

**Apply:**
```bash
terraform plan -out=network-access.tfplan
terraform apply network-access.tfplan
```

#### Option 4: Configuration-as-Code (Ansible/Python/etc.)

```python
# Python example using platform SDK
import salesforce_api

client = salesforce_api.Client(token=os.getenv('SF_TOKEN'))

# Define trusted IPs
gainsight_ips = [
    {"start": "35.166.202.113", "end": "35.166.202.113", "description": "Gainsight Production 1"},
    {"start": "52.35.87.209", "end": "52.35.87.209", "description": "Gainsight Production 2"},
    {"start": "34.221.135.142", "end": "34.221.135.142", "description": "Gainsight Production 3"}
]

# Create trusted IP ranges
for ip in gainsight_ips:
    client.network_access.create_trusted_ip(**ip)
    print(f"✓ Added {ip['start']}")

# Verify
current_ips = client.network_access.list_trusted_ips()
print(f"Total trusted IPs configured: {len(current_ips)}")
```

**Time to Complete:** ~[X] minutes (excluding IaC setup)

---

## Validation & Testing

### Functional Testing
[How to verify the integration still works after implementing the control]

**Test Plan:**
1. [ ] [Specific test action 1]
2. [ ] [Specific test action 2]
3. [ ] [Expected result]

### Security Testing
[How to verify the control is actually enforcing security]

**Attack Simulation:**
```bash
# Attempt API access from non-allowlisted IP
# Expected: Request should be blocked

[Command to test]

# Expected response:
[Error message indicating blocking]
```

---

## Monitoring & Maintenance

### Ongoing Monitoring
[What to monitor to detect if this control degrades or is bypassed]

**Alert Configuration:**
- **Trigger:** [Event that should alert]
- **Detection:** [How to detect this event]
- **Response:** [What to do when alerted]

**Example Queries:**
```sql
-- For platforms with SQL-based monitoring (e.g., Salesforce SOQL, Snowflake)
SELECT Id, LoginTime, SourceIp, Status
FROM LoginHistory
WHERE Application = '[Integration Name]'
  AND Status = 'Failed'
  AND SourceIp NOT IN ([Allowlisted IPs])
ORDER BY LoginTime DESC
LIMIT 100
```

### Maintenance Schedule
- **Quarterly:** [Review task, e.g., "Verify integration vendor hasn't changed egress IPs"]
- **Annually:** [Deeper review task]
- **On vendor notification:** [What to do when vendor announces infrastructure changes]

**Maintenance Checklist:**
```markdown
## Quarterly IP Allowlist Review

- [ ] Contact [Integration Vendor] CSM to confirm current egress IPs
- [ ] Compare confirmed IPs against configured allowlist
- [ ] Update allowlist if vendor IPs have changed
- [ ] Test integration after any changes
- [ ] Document review date and findings in [tracking location]
```

---

## Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2 Trust Services** | CC6.6 | The entity implements logical access security measures to protect against threats from sources outside its system boundaries |
| **NIST 800-53 Rev 5** | AC-3 | Access Enforcement |
| **NIST 800-53 Rev 5** | SC-7 | Boundary Protection |
| **CIS Controls v8** | 13.3 | Deploy a Network-Based Intrusion Detection Solution |
| **ISO 27001:2022** | A.5.14 | Information security in project management |
| **PCI DSS v4.0** | 1.3.1 | Inbound traffic to the CDE is restricted |

**Audit Evidence:**
[What documentation/screenshots to collect for auditors]

---

## Related Patterns

**Complementary Controls** (implement together for defense-in-depth):
- [Link to related defensive pattern 1]
- [Link to related defensive pattern 2]

**Alternative Controls** (if this one isn't feasible):
- [Alternative approach with tradeoffs]

**Next Steps After Implementation:**
- [What to harden next for similar threat coverage]

---

## Platform-Specific Notes

### For [Platform Version X.Y]
[Version-specific considerations, if applicable]

### Known Limitations
- [Limitation 1]: [Description and workaround]
- [Limitation 2]: [Description and workaround]

### Feature Availability by Edition
| Edition | Supported | Notes |
|---------|-----------|-------|
| [Free/Community] | ❌ | [Why not available] |
| [Basic/Starter] | ⚠️ | [Partial support details] |
| [Professional] | ✅ | [Full support] |
| [Enterprise] | ✅ | [Enhanced features] |

---

## References

**Official Documentation:**
- [Link to vendor's official documentation]
- [Link to relevant API reference]

**Community Resources:**
- [Link to relevant blog posts, if vetted]
- [Link to security researcher analysis]

**Supply Chain Incident Reports:**
- [Link to incident post-mortem if this control relates to a specific attack]

**Discussion:**
- GitHub Discussion: [Link to discussion thread for this recommendation]

---

## Changelog

| Date | Version | Change | Author |
|------|---------|--------|--------|
| YYYY-MM-DD | 1.0 | Initial recommendation | [@username] |
| YYYY-MM-DD | 1.1 | Added Terraform example | [@username] |

---

## Metadata (for tooling)

```yaml
---
id: [unique-identifier-lowercase-kebab-case]
title: "[Human readable title]"
platforms:
  primary: [platform-name]
  secondary: [integration-name]
profile_level: [L1|L2|L3]
attack_relevance:
  - incident: "salesloft-drift-2025"
    mitigation_type: "preventive"
  - incident: "gainsight-2025"
    mitigation_type: "detective"
control_type:
  - ip-allowlisting
  - network-boundary
priority: [high|medium|low]
effort: [low|medium|high]
impact: [low|medium|high]
automation_available: [true|false]
last_verified: "YYYY-MM-DD"
status: [active|deprecated|under-review]
contributors:
  - "@username1"
  - "@username2"
---
```

---

## Template Usage Notes

**When creating a new recommendation:**

1. Copy this template to `/content/defensive-patterns/[pattern-type]/[specific-recommendation].md`
2. Fill in ALL sections (don't leave "TODO" placeholders)
3. Provide BOTH ClickOps and Code implementations
4. Test all commands/scripts before submitting
5. Add real screenshots to `/static/images/[platform]/[recommendation-id]/`
6. Update the metadata YAML block for tooling integration
7. Link to related patterns and incident case studies
8. Submit PR with tag `new-recommendation`

**Section Priorities:**

- **Must Have:** Description, Rationale, Attack Relevance, Prerequisites, Audit Procedure, Remediation (ClickOps + Code), Compliance Mappings
- **Should Have:** Operational Impact, Validation & Testing, Monitoring, Related Patterns
- **Nice to Have:** Platform-Specific Notes, Known Limitations, Feature Availability

**Quality Checklist:**

- [ ] Tested ClickOps steps in a real environment
- [ ] Tested Code examples (CLI/API/IaC all work)
- [ ] Screenshots added for key ClickOps steps
- [ ] Links to vendor documentation verified (not broken)
- [ ] Compliance mappings accurate (verified against framework)
- [ ] Metadata YAML complete and valid
- [ ] Related patterns linked bidirectionally
- [ ] At least 2 reviewers with platform experience
