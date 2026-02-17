use std::collections::HashMap;

use async_trait::async_trait;

use crate::error::HthResult;
use crate::models::HttpMethod;

/// Each vendor crate implements this trait to provide vendor-specific
/// behavior: authentication, URL resolution, rate limiting, and pagination.
#[async_trait]
pub trait VendorProvider: Send + Sync {
    /// Vendor slug matching the pack directory name (e.g., "github").
    fn vendor_slug(&self) -> &str;

    /// Display name for output (e.g., "GitHub").
    fn display_name(&self) -> &str;

    /// Resolve a relative API endpoint to a full URL.
    fn resolve_url(&self, endpoint: &str) -> String;

    /// Return HTTP headers required for authentication.
    fn auth_headers(&self) -> Vec<(String, String)>;

    /// Execute an HTTP request, handling vendor-specific concerns
    /// like rate limiting, pagination, and error response formats.
    async fn execute_request(
        &self,
        method: HttpMethod,
        endpoint: &str,
        body: Option<&serde_json::Value>,
    ) -> HthResult<serde_json::Value>;

    /// Validate that the provided credentials are working.
    async fn validate_credentials(&self) -> HthResult<()>;

    /// Return vendor-specific Terraform provider configuration block.
    fn terraform_provider_block(&self) -> String;
}

/// Registry that maps vendor slugs to their providers.
pub struct VendorRegistry {
    providers: HashMap<String, Box<dyn VendorProvider>>,
}

impl VendorRegistry {
    pub fn new() -> Self {
        Self {
            providers: HashMap::new(),
        }
    }

    /// Register a vendor provider.
    pub fn register(&mut self, provider: Box<dyn VendorProvider>) {
        let slug = provider.vendor_slug().to_string();
        self.providers.insert(slug, provider);
    }

    /// Get a provider by vendor slug.
    pub fn get(&self, vendor: &str) -> Option<&dyn VendorProvider> {
        self.providers.get(vendor).map(|p| p.as_ref())
    }

    /// List all registered vendor slugs.
    pub fn list(&self) -> Vec<&str> {
        let mut slugs: Vec<&str> = self.providers.keys().map(|s| s.as_str()).collect();
        slugs.sort();
        slugs
    }

    /// List all registered vendors as (slug, display_name) pairs.
    pub fn list_with_names(&self) -> Vec<(&str, &str)> {
        let mut vendors: Vec<(&str, &str)> = self
            .providers
            .values()
            .map(|p| (p.vendor_slug(), p.display_name()))
            .collect();
        vendors.sort_by_key(|(slug, _)| *slug);
        vendors
    }
}

impl Default for VendorRegistry {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_registry_is_empty() {
        let registry = VendorRegistry::new();
        assert!(registry.list().is_empty());
    }

    #[test]
    fn list_returns_empty_for_new_registry() {
        let registry = VendorRegistry::new();
        let vendors = registry.list();
        assert_eq!(vendors.len(), 0);
    }

    #[test]
    fn get_returns_none_for_unknown_vendor() {
        let registry = VendorRegistry::new();
        assert!(registry.get("github").is_none());
        assert!(registry.get("okta").is_none());
        assert!(registry.get("").is_none());
    }

    #[test]
    fn default_is_same_as_new() {
        let registry = VendorRegistry::default();
        assert!(registry.list().is_empty());
        assert!(registry.get("anything").is_none());
    }
}
