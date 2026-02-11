use std::time::Duration;

/// Build a preconfigured reqwest HTTP client for HTH.
pub fn build_http_client(timeout_secs: u64) -> reqwest::Client {
    reqwest::Client::builder()
        .timeout(Duration::from_secs(timeout_secs))
        .connect_timeout(Duration::from_secs(10))
        .user_agent(format!("hth/{} (https://howtoharden.com)", env!("CARGO_PKG_VERSION")))
        .https_only(true)
        .build()
        .expect("Failed to build HTTP client")
}
