pub mod api;
pub mod auth;

use async_trait::async_trait;
use secrecy::SecretString;

use hth_core::error::{HthError, HthResult};
use hth_core::models::HttpMethod;
use hth_core::vendor::VendorProvider;

use crate::api::GitHubApiClient;
use crate::auth::GitHubAuth;

/// GitHub vendor provider implementation.
pub struct GitHubProvider {
    client: GitHubApiClient,
}

impl GitHubProvider {
    /// Create a new GitHub provider from environment variables.
    pub fn from_env() -> HthResult<Self> {
        let auth = GitHubAuth::from_env().map_err(|e| HthError::Credential {
            vendor: "github".to_string(),
            message: e,
        })?;

        let org = std::env::var("GITHUB_ORG")
            .or_else(|_| std::env::var("GH_ORG"))
            .map_err(|_| HthError::Credential {
                vendor: "github".to_string(),
                message: "Set GITHUB_ORG or GH_ORG environment variable".to_string(),
            })?;

        Ok(Self {
            client: GitHubApiClient::new(auth, org),
        })
    }

    /// Create a new GitHub provider with explicit values.
    pub fn new(token: SecretString, org: String) -> Self {
        Self {
            client: GitHubApiClient::new(GitHubAuth::from_token(token), org),
        }
    }
}

#[async_trait]
impl VendorProvider for GitHubProvider {
    fn vendor_slug(&self) -> &str {
        "github"
    }

    fn display_name(&self) -> &str {
        "GitHub"
    }

    fn resolve_url(&self, endpoint: &str) -> String {
        let resolved = endpoint.replace("{org}", self.client.org());
        format!("https://api.github.com{resolved}")
    }

    fn auth_headers(&self) -> Vec<(String, String)> {
        vec![
            (
                "Accept".to_string(),
                "application/vnd.github+json".to_string(),
            ),
            ("X-GitHub-Api-Version".to_string(), "2022-11-28".to_string()),
        ]
    }

    async fn execute_request(
        &self,
        method: HttpMethod,
        endpoint: &str,
        body: Option<&serde_json::Value>,
    ) -> HthResult<serde_json::Value> {
        self.client.request(method, endpoint, body).await
    }

    async fn validate_credentials(&self) -> HthResult<()> {
        self.client.request(HttpMethod::GET, "/user", None).await?;
        Ok(())
    }

    fn terraform_provider_block(&self) -> String {
        r#"terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = var.github_org
  token = var.github_token
}
"#
        .to_string()
    }
}
