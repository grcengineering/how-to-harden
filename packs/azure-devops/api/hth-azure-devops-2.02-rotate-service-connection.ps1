# =============================================================================
# HTH Azure DevOps Control 2.2: Rotate Service Connection Credentials
# Profile: L1 | NIST: IA-5(1)
# =============================================================================

# HTH Guide Excerpt: begin cli-rotate-service-connection
# Rotate service connection credentials
# 1. Generate new credentials in target service
# 2. Update service connection
# 3. Verify pipeline functionality
# 4. Revoke old credentials

$connectionId = "connection-guid"
$projectId = "project-guid"

$body = @{
    name = "Updated Connection"
    authorization = @{
        parameters = @{
            serviceprincipalkey = "new-secret-value"
        }
    }
} | ConvertTo-Json

Invoke-RestMethod -Method Put `
    -Uri "https://dev.azure.com/$org/$projectId/_apis/serviceendpoint/endpoints/$connectionId?api-version=7.1" `
    -Headers $headers -Body $body -ContentType "application/json"
# HTH Guide Excerpt: end cli-rotate-service-connection
