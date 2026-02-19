// HTH NetSuite Control 2.2: OAuth 2.0 for SuiteApps
// Profile: L2 | NIST: IA-5(13)
// https://howtoharden.com/guides/netsuite/#22-oauth-20-for-suiteapps

// HTH Guide Excerpt: begin sdk-oauth-configuration
// SuiteScript OAuth configuration
var oauth = require('N/oauth');

var tokenResponse = oauth.getToken({
    grantType: oauth.GrantType.AUTHORIZATION_CODE,
    code: authorizationCode,
    redirectUri: 'https://app.example.com/callback'
});
// HTH Guide Excerpt: end sdk-oauth-configuration
