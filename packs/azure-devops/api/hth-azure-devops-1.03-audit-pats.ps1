# =============================================================================
# HTH Azure DevOps Control 1.3: Audit Personal Access Tokens
# Profile: L1 | NIST: IA-5
# =============================================================================

# HTH Guide Excerpt: begin cli-audit-pats
$org = "your-org"
$pat = $env:AZURE_DEVOPS_PAT

$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
}

Invoke-RestMethod -Uri "https://vssps.dev.azure.com/$org/_apis/tokens/pats?api-version=7.1-preview.1" `
    -Headers $headers | ConvertTo-Json
# HTH Guide Excerpt: end cli-audit-pats
