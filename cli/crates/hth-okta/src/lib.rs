pub mod api;
pub mod auth;

use async_trait::async_trait;
use secrecy::SecretString;

use hth_core::error::{HthError, HthResult};
use hth_core::models::HttpMethod;
use hth_core::vendor::VendorProvider;

/// Okta vendor provider implementation.
pub struct OktaProvider {
    domain: String,
    token: SecretString,
    http: reqwest::Client,
}

impl OktaProvider {
    /// Create a new Okta provider from environment variables.
    pub fn from_env() -> HthResult<Self> {
        let domain = std::env::var("OKTA_DOMAIN").map_err(|_| HthError::Credential {
            vendor: "okta".to_string(),
            message: "Set OKTA_DOMAIN environment variable (e.g., yourorg.okta.com)".to_string(),
        })?;

        let token = std::env::var("OKTA_API_TOKEN").map_err(|_| HthError::Credential {
            vendor: "okta".to_string(),
            message: "Set OKTA_API_TOKEN environment variable".to_string(),
        })?;

        Ok(Self {
            domain,
            token: SecretString::from(token),
            http: hth_core::engine::http::build_http_client(30),
        })
    }

    /// Create a new Okta provider with explicit values.
    pub fn new(domain: String, token: SecretString) -> Self {
        Self {
            domain,
            token,
            http: hth_core::engine::http::build_http_client(30),
        }
    }
}

#[async_trait]
impl VendorProvider for OktaProvider {
    fn vendor_slug(&self) -> &str {
        "okta"
    }

    fn display_name(&self) -> &str {
        "Okta"
    }

    fn resolve_url(&self, endpoint: &str) -> String {
        format!("https://{}{}", self.domain, endpoint)
    }

    fn auth_headers(&self) -> Vec<(String, String)> {
        vec![("Content-Type".to_string(), "application/json".to_string())]
    }

    async fn execute_request(
        &self,
        method: HttpMethod,
        endpoint: &str,
        body: Option<&serde_json::Value>,
    ) -> HthResult<serde_json::Value> {
        use secrecy::ExposeSecret;

        let url = self.resolve_url(endpoint);

        let mut request = match method {
            HttpMethod::GET => self.http.get(&url),
            HttpMethod::POST => self.http.post(&url),
            HttpMethod::PUT => self.http.put(&url),
            HttpMethod::DELETE => self.http.delete(&url),
            HttpMethod::PATCH => self.http.patch(&url),
        };

        request = request
            .header(
                "Authorization",
                format!("SSWS {}", self.token.expose_secret()),
            )
            .header("Content-Type", "application/json");

        if let Some(body) = body {
            request = request.json(body);
        }

        let response = request.send().await.map_err(|e| HthError::Http {
            method: method.to_string(),
            url: url.clone(),
            source: e,
        })?;

        // Handle Okta rate limiting
        if response.status() == reqwest::StatusCode::TOO_MANY_REQUESTS {
            let retry_after = response
                .headers()
                .get("X-Rate-Limit-Reset")
                .and_then(|v| v.to_str().ok())
                .and_then(|v| v.parse::<u64>().ok())
                .unwrap_or(5);

            return Err(HthError::RateLimit {
                vendor: "okta".to_string(),
                retry_after_secs: retry_after,
            });
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

        response.json().await.map_err(|e| HthError::Http {
            method: method.to_string(),
            url,
            source: e,
        })
    }

    async fn validate_credentials(&self) -> HthResult<()> {
        self.execute_request(HttpMethod::GET, "/api/v1/org", None)
            .await?;
        Ok(())
    }

    fn terraform_provider_block(&self) -> String {
        r#"terraform {
  required_providers {
    okta = {
      source  = "okta/okta"
      version = "~> 4.0"
    }
  }
}

provider "okta" {
  org_name  = var.okta_org_name
  base_url  = var.okta_base_url
  api_token = var.okta_api_token
}
"#
        .to_string()
    }
}
