use hth_core::engine::http::build_http_client;
use hth_core::error::{HthError, HthResult};
use hth_core::models::HttpMethod;

use crate::auth::GitHubAuth;

/// GitHub API client handling REST calls, rate limiting, and pagination.
pub struct GitHubApiClient {
    auth: GitHubAuth,
    http: reqwest::Client,
    org: String,
}

impl GitHubApiClient {
    pub fn new(auth: GitHubAuth, org: String) -> Self {
        Self {
            auth,
            http: build_http_client(30),
            org,
        }
    }

    /// The organization being audited.
    pub fn org(&self) -> &str {
        &self.org
    }

    /// Execute a GitHub API request.
    pub async fn request(
        &self,
        method: HttpMethod,
        endpoint: &str,
        body: Option<&serde_json::Value>,
    ) -> HthResult<serde_json::Value> {
        let url = self.resolve_url(endpoint);

        let mut request = match method {
            HttpMethod::GET => self.http.get(&url),
            HttpMethod::POST => self.http.post(&url),
            HttpMethod::PUT => self.http.put(&url),
            HttpMethod::DELETE => self.http.delete(&url),
            HttpMethod::PATCH => self.http.patch(&url),
        };

        request = request
            .header("Authorization", self.auth.auth_header_value())
            .header("Accept", "application/vnd.github+json")
            .header("X-GitHub-Api-Version", "2022-11-28");

        if let Some(body) = body {
            request = request.json(body);
        }

        let response = request.send().await.map_err(|e| HthError::Http {
            method: method.to_string(),
            url: url.clone(),
            source: e,
        })?;

        // Handle rate limiting
        if response.status() == reqwest::StatusCode::FORBIDDEN
            || response.status() == reqwest::StatusCode::TOO_MANY_REQUESTS
        {
            let retry_after = response
                .headers()
                .get("retry-after")
                .and_then(|v| v.to_str().ok())
                .and_then(|v| v.parse::<u64>().ok())
                .unwrap_or(60);

            return Err(HthError::RateLimit {
                vendor: "github".to_string(),
                retry_after_secs: retry_after,
            });
        }

        // GitHub returns 404 for many "not configured" states (e.g., "Branch not
        // protected", "no analysis found"). Return these as JSON so jq checks can
        // evaluate them as failures rather than errors.
        if response.status() == reqwest::StatusCode::NOT_FOUND {
            let body = response.text().await.unwrap_or_default();
            if let Ok(json) = serde_json::from_str::<serde_json::Value>(&body) {
                return Ok(json);
            }
            return Ok(serde_json::json!({"message": "Not Found", "status": "404"}));
        }

        if !response.status().is_success() {
            let status = response.status();
            let body = response.text().await.unwrap_or_default();
            return Err(HthError::HttpStatus {
                method: method.to_string(),
                url,
                status: status.as_u16(),
                body,
            });
        }

        // Handle empty responses (204 No Content, etc.)
        if response.status() == reqwest::StatusCode::NO_CONTENT {
            return Ok(serde_json::Value::Null);
        }

        response.json().await.map_err(|e| HthError::Http {
            method: method.to_string(),
            url,
            source: e,
        })
    }

    /// Resolve an endpoint path to a full GitHub API URL.
    /// Replaces `{org}` placeholder with the configured org name.
    fn resolve_url(&self, endpoint: &str) -> String {
        let resolved = endpoint.replace("{org}", &self.org);
        format!("https://api.github.com{resolved}")
    }
}
