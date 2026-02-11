use secrecy::{ExposeSecret, SecretString};

/// GitHub authentication configuration.
pub struct GitHubAuth {
    token: SecretString,
}

impl GitHubAuth {
    /// Create auth from a Personal Access Token.
    pub fn from_token(token: SecretString) -> Self {
        Self { token }
    }

    /// Resolve authentication from environment variables.
    pub fn from_env() -> Result<Self, String> {
        let token = std::env::var("GITHUB_TOKEN")
            .or_else(|_| std::env::var("GH_TOKEN"))
            .map_err(|_| {
                "Set GITHUB_TOKEN or GH_TOKEN environment variable".to_string()
            })?;
        Ok(Self {
            token: SecretString::from(token),
        })
    }

    /// Return the Authorization header value.
    pub fn auth_header_value(&self) -> String {
        format!("Bearer {}", self.token.expose_secret())
    }
}
