use hth_core::engine::http::build_http_client;
use hth_core::error::{HthError, HthResult};
use hth_core::models::HttpMethod;

use crate::auth::GitHubAuth;

/// Maximum number of pages to follow during pagination.
const DEFAULT_MAX_PAGES: usize = 10;

/// Maximum number of retries on rate-limit responses.
const MAX_RATE_LIMIT_RETRIES: u32 = 3;

/// GitHub API client handling REST calls, rate limiting, and pagination.
pub struct GitHubApiClient {
    auth: GitHubAuth,
    http: reqwest::Client,
    org: String,
    repo: String,
}

impl GitHubApiClient {
    pub fn new(auth: GitHubAuth, org: String) -> Self {
        Self {
            auth,
            http: build_http_client(30),
            org,
            repo: "how-to-harden".to_string(),
        }
    }

    /// Create a new client with an explicit repo name.
    pub fn with_repo(auth: GitHubAuth, org: String, repo: String) -> Self {
        Self {
            auth,
            http: build_http_client(30),
            org,
            repo,
        }
    }

    /// The organization being audited.
    pub fn org(&self) -> &str {
        &self.org
    }

    /// The repository being audited.
    pub fn repo(&self) -> &str {
        &self.repo
    }

    /// Execute a GitHub API request with rate-limit backoff and pagination.
    pub async fn request(
        &self,
        method: HttpMethod,
        endpoint: &str,
        body: Option<&serde_json::Value>,
    ) -> HthResult<serde_json::Value> {
        let url = self.resolve_url(endpoint);

        let response = self
            .send_with_retries(method, &url, body)
            .await?;

        // For GET requests that return arrays, paginate automatically.
        if method == HttpMethod::GET
            && let Some(arr) = response.value.as_array()
        {
            let mut all_items: Vec<serde_json::Value> = arr.clone();
            let mut next_url = parse_next_link(&response.link_header);
            let mut pages = 1;

            while let Some(ref nurl) = next_url {
                if pages >= DEFAULT_MAX_PAGES {
                    tracing::warn!(
                        "Pagination limit reached ({DEFAULT_MAX_PAGES} pages) for {url}"
                    );
                    break;
                }

                let next_resp = self
                    .send_with_retries(method, nurl, None)
                    .await?;

                if let Some(items) = next_resp.value.as_array() {
                    all_items.extend(items.iter().cloned());
                } else {
                    // Response is no longer an array — stop paginating.
                    break;
                }

                next_url = parse_next_link(&next_resp.link_header);
                pages += 1;
            }

            return Ok(serde_json::Value::Array(all_items));
        }

        Ok(response.value)
    }

    /// Send a single request, retrying with exponential backoff on rate limits.
    async fn send_with_retries(
        &self,
        method: HttpMethod,
        url: &str,
        body: Option<&serde_json::Value>,
    ) -> HthResult<ApiResponse> {
        let mut retries = 0u32;

        loop {
            let mut request = match method {
                HttpMethod::GET => self.http.get(url),
                HttpMethod::POST => self.http.post(url),
                HttpMethod::PUT => self.http.put(url),
                HttpMethod::DELETE => self.http.delete(url),
                HttpMethod::PATCH => self.http.patch(url),
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
                url: url.to_string(),
                source: e,
            })?;

            // Handle rate limiting with exponential backoff
            let is_rate_limited = response.status() == reqwest::StatusCode::TOO_MANY_REQUESTS;
            let remaining_zero = response
                .headers()
                .get("x-ratelimit-remaining")
                .and_then(|v| v.to_str().ok())
                .and_then(|v| v.parse::<u64>().ok())
                == Some(0);

            if is_rate_limited
                || (response.status() == reqwest::StatusCode::FORBIDDEN && remaining_zero)
            {
                if retries >= MAX_RATE_LIMIT_RETRIES {
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

                let wait_secs = if let Some(retry_after) = response
                    .headers()
                    .get("retry-after")
                    .and_then(|v| v.to_str().ok())
                    .and_then(|v| v.parse::<u64>().ok())
                {
                    retry_after
                } else {
                    // Exponential backoff: 1s, 2s, 4s, 8s
                    1u64 << retries
                };

                tracing::warn!(
                    "GitHub rate limited on {url}; retrying in {wait_secs}s (attempt {}/{})",
                    retries + 1,
                    MAX_RATE_LIMIT_RETRIES
                );
                tokio::time::sleep(std::time::Duration::from_secs(wait_secs)).await;
                retries += 1;
                continue;
            }

            // GitHub returns 404 for many "not configured" states (e.g., "Branch not
            // protected", "no analysis found"). Return these as JSON so jq checks can
            // evaluate them as failures rather than errors.
            if response.status() == reqwest::StatusCode::NOT_FOUND {
                let body = response.text().await.unwrap_or_default();
                let value = if let Ok(json) = serde_json::from_str::<serde_json::Value>(&body) {
                    json
                } else {
                    serde_json::json!({"message": "Not Found", "status": "404"})
                };
                return Ok(ApiResponse {
                    value,
                    link_header: None,
                });
            }

            if !response.status().is_success() {
                let status = response.status();
                let body = response.text().await.unwrap_or_default();
                return Err(HthError::HttpStatus {
                    method: method.to_string(),
                    url: url.to_string(),
                    status: status.as_u16(),
                    body,
                });
            }

            // Handle empty responses (204 No Content, etc.)
            if response.status() == reqwest::StatusCode::NO_CONTENT {
                return Ok(ApiResponse {
                    value: serde_json::Value::Null,
                    link_header: None,
                });
            }

            let link_header = response
                .headers()
                .get("link")
                .and_then(|v| v.to_str().ok())
                .map(|s| s.to_string());

            let value =
                response
                    .json()
                    .await
                    .map_err(|e| HthError::Http {
                        method: method.to_string(),
                        url: url.to_string(),
                        source: e,
                    })?;

            return Ok(ApiResponse { value, link_header });
        }
    }

    /// Resolve an endpoint path to a full GitHub API URL.
    /// Replaces `{org}` and `{repo}` placeholders with configured values.
    fn resolve_url(&self, endpoint: &str) -> String {
        let resolved = endpoint
            .replace("{org}", &self.org)
            .replace("{owner}", &self.org)
            .replace("{repo}", &self.repo);
        format!("https://api.github.com{resolved}")
    }
}

/// Internal response wrapper that carries the Link header for pagination.
struct ApiResponse {
    value: serde_json::Value,
    link_header: Option<String>,
}

/// Parse the `Link` header to extract the URL for `rel="next"`.
fn parse_next_link(link_header: &Option<String>) -> Option<String> {
    let header = link_header.as_deref()?;
    for part in header.split(',') {
        let part = part.trim();
        if part.contains("rel=\"next\"") {
            // Extract URL from between < and >
            let start = part.find('<')? + 1;
            let end = part.find('>')?;
            return Some(part[start..end].to_string());
        }
    }
    None
}
