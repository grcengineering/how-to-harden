// Control: 3.2 Harden Stored Credentials for Managed Auth
// Profile Level: L2 (Walk)
// Frameworks: NIST 800-53 IA-5/SC-28, CIS Controls v8 3, SOC 2 CC6.1
// Guide: https://howtoharden.com/guides/kernel/
// Interface: Kernel SDK / REST API — /credentials
//   (docs: https://www.kernel.sh/docs/auth/credentials; OpenAPI: api.onkernel.com/spec.json)

// HTH Guide Excerpt: begin create-credential-deliberately
// Pre-store a credential for headless automation. Values are encrypted with
// per-organization keys and are WRITE-ONLY: they cannot be read back via the
// API after creation. One-time codes (SMS/TOTP codes) are never saved;
// totp_secret enables automatic TOTP generation for 2FA logins.
// Keep ONE credential per account — never share a credential across accounts.
await kernel.credentials.create({
  name: 'crm-agent-login',        // unique within the project
  domain: 'crm.example.com',      // target domain this credential is for
  values: {
    username: 'agent-svc@example.com',
    password: process.env.CRM_AGENT_PASSWORD, // from your secret manager
  },
  totp_secret: process.env.CRM_AGENT_TOTP_SECRET, // base32, optional
});
// HTH Guide Excerpt: end create-credential-deliberately

// HTH Guide Excerpt: begin disable-automatic-capture
// Hosted UI / programmatic login flows SAVE credentials by default.
// Where automatic capture is not an accepted, documented need for the
// account, opt out on the flow configuration:
const flow = {
  save_credentials: false,
};
// HTH Guide Excerpt: end disable-automatic-capture

// HTH Guide Excerpt: begin offboard-credential
// Decommission: deleting a credential unlinks it from associated
// connections, so they can no longer auto-authenticate.
await fetch('https://api.onkernel.com/credentials/crm-agent-login', {
  method: 'DELETE',
  headers: { Authorization: `Bearer ${process.env.KERNEL_API_KEY}` },
});
// HTH Guide Excerpt: end offboard-credential
