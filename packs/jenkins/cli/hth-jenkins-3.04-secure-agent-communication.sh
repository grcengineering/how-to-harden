# =============================================================================
# HTH Jenkins Control 3.4: Secure Agent Communication
# Profile: L1 | Section: 3.4
# =============================================================================

# HTH Guide Excerpt: begin https-config
java -jar jenkins.war --httpsPort=8443 \
  --httpsKeyStore=/path/to/keystore.jks \
  --httpsKeyStorePassword=changeit
# HTH Guide Excerpt: end https-config
