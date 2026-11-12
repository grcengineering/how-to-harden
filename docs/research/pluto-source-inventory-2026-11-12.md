# Pluto source inventory: 2026-11-12

## Coverage proof

- Six sitemap children exhausted: post 83 URLs (82 articles + index), page 12, glossary 60, guides 2 (index + duplicate Cowork), FAQ 41, author 27. All 225 entry bodies fetched successfully after curl retry; raw HTML and extracted text retained in the local research cache.
- Blog archive path pages 1–12 all returned the first seven articles despite their page titles; page13 returned404. Therefore archive URL iteration alone is NOT coverage proof.
- Followed actual public site JS (`icw-ajax-post-filter.js`): read-only `do_filter_posts` requests, qty7, pages1–12 until `next=0`. All82 sitemap articles were present; no additional article outside sitemap. Four extra hrefs were author indexes, not articles.
- Plutonium Safe-use Guides enumerated all9 links; eight are already blog entries and one is the Claude Code Best Practices GitHub repo. Main /guides index has one entry (Cowork), identical to its sitemap.
- Expanded discovery with site-restricted searches for securing, hardening, best practices, guide, and named tools; searched author index; followed ClaudeSec/CopilotSec and TeamPCP references. ClaudeSec fetch403; CopilotSec redirects Plutonium. These older hubs do not establish additional currently published guide content.
- This inventory classifies sources; reconciliation and authoritative vendor verification are separate work. Do not treat old research snapshots as current controls.

## Explicit product hardening guides

| Date | Source | Scope |
|---|---|---|
| 2026-05-08 | [Securing OpenAI Codex: What You Need to Know Before Rolling It Out](https://pluto.security/blog/securing-openai-codex/) | Reconciled: [openai-reconciliation](pluto-openai-reconciliation.md) |
| 2026-07-27 | [Securing Claude Tag: A Practical Hardening Guide](https://pluto.security/blog/securing-claude-tag-a-practical-hardening-guide/) | Reconciled: [anthropic-reconciliation-2026-11](pluto-anthropic-reconciliation-2026-11.md) |
| 2026-05-26 | [Securing Copilot Studio: A Practical Hardening Guide](https://pluto.security/blog/securing-copilot-studio-a-practical-hardening-guide/) | Reconciled: [copilot-reconciliation-2026-11-12](pluto-copilot-reconciliation-2026-11-12.md) |
| 2026-04-17 | [Securing Claude Managed Agents: What You Need to Know Before Going to Production](https://pluto.security/blog/securing-claude-managed-agents/) | Reconciled: [anthropic-reconciliation-2026-11](pluto-anthropic-reconciliation-2026-11.md) |
| 2026-04-16 | [Securing Claude Cowork: What Security Teams Actually Need to Know](https://pluto.security/blog/claude-cowork-security/) | Reconciled: [anthropic-reconciliation-2026-11](pluto-anthropic-reconciliation-2026-11.md) |
| 2026-10-26 | [ChatGPT Dots Security: A Practical Hardening Guide](https://pluto.security/blog/chatgpt-dots-security-practical-guide/) | Reconciled: [openai-reconciliation](pluto-openai-reconciliation.md) |
| 2026-11-09 | [Securing Grok Bot: A Hardening Guide to X’s Personal AI Assistant](https://pluto.security/blog/securing-grok-bot/) | Reconciled: [grok-bot-reconciliation](pluto-grok-bot-reconciliation.md) |

## Additional safe-use code reference

- [Claude Code Best Practices](https://github.com/plutosecurity/Claude-Code-Best-Practices), linked by Plutonium: settings, MCP policies, behavioral instructions, OTel and secret-scanning hook. Date not asserted. Independently verify security claims; instructions are not enforceable boundaries and filesystem scopes do not imply read-only.

## Full blog disposition inventory

| Date | Article | Classification / review route |
|---|---|---|
| 2026-02-09 | [Vibe Coding Security: When AI-Driven Development Escapes Security Visibility](https://pluto.security/blog/vibe-coding-security/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-02-16 | [The Rise of Shadow AI: How AI-Built Apps Escape Security Visibility](https://pluto.security/blog/the-rise-of-shadow-ai-how-ai-built-apps-escape-security-visibility/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-02-23 | [Next-Gen Endpoint Protection vs. Modern AI Risks: What Security Teams Are Missing](https://pluto.security/blog/next-gen-endpoint-protection-vs-ai-risks/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-03-02 | [Citizen Development Security: When Business-Built Apps Bypass Security Teams](https://pluto.security/blog/citizen-development-security-teams/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-03-09 | [Cursor Security Issues: What Security Teams Can’t See During AI-Assisted Coding](https://pluto.security/blog/cursor-security-issues/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-03-30 | [Enterprise AI Security](https://pluto.security/blog/enterprise-ai-security-at-scale/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-03-23 | [AI Supply Chain Security](https://pluto.security/blog/ai-supply-chain-security-reused-models-prompts-internal-apps/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-03-16 | [AI Application Security: The Risk of Apps Built Faster Than Security Can See](https://pluto.security/blog/ai-application-security-risk-fast-development/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-05-04 | [Offensive AI Security](https://pluto.security/blog/ai-offensive-cyber-operations/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-04-13 | [AI Code Security](https://pluto.security/blog/ai-code-security-defenders/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-05-11 | [Enterprise Agent Governance](https://pluto.security/blog/enterprise-agent-governance/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-04-27 | [Agent Skills Supply Chain Risks](https://pluto.security/blog/supply-chain-risks/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-05-11 | [Building A Mythos-Ready Security Program](https://pluto.security/blog/building-mythos-security/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-07-13 | [Continuous Monitoring: Security Visibility Across AI Systems and Pipelines](https://pluto.security/blog/continuous-monitoring-security/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-02-26 | [MCPwnfluence: Critical Unauthenticated SSRF to RCE Attack Chain in the Most Widely Used Atlassian MCP Server](https://pluto.security/blog/mcpwnfluence-cve-2026-27825-critical/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-05-27 | [Claude Code Risks: Prompt Injection and Extension-Based Exploits in AI Coding Workflows](https://pluto.security/blog/claude-code-vulnerability/) | Reconciled: [anthropic-reconciliation-2026-11](pluto-anthropic-reconciliation-2026-11.md) |
| 2026-06-29 | [What Is Vibe Coding? Meaning, Origins, and Use Cases](https://pluto.security/blog/vibe-coding-meaning-origins-use-cases/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-06-29 | [Count Dooku: A Live Malicious Open VSX Campaign Hiding in Plain Sight](https://pluto.security/blog/count-dooku-a-live-malicious-open-vsx-campaign-hiding-in-plain-sight/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-07-06 | [One Request to Own Every Repo: How We Hijacked GitLab Through Its MCP Server](https://pluto.security/blog/two-critical-vulnerabilities-gitlab-mcp-account-takeover/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-05-08 | [Securing OpenAI Codex: What You Need to Know Before Rolling It Out](https://pluto.security/blog/securing-openai-codex/) | Reconciled: [openai-reconciliation](pluto-openai-reconciliation.md) |
| 2026-08-20 | [Nebula-Deck Junior: The Crypto-Stealing Little Brother](https://pluto.security/blog/nebula-deck-junior/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-06-04 | [Unauthenticated Remote Code Execution in HuggingFace Transformers via Config Injection](https://pluto.security/blog/unauthenticated-remote-code-execution-in-huggingface-transformers-via-config-injection/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-01-22 | [The Real Value of Agentless Monitoring: Continuous Visibility Without Friction](https://pluto.security/blog/real-value-of-agentless-monitoring/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-08-27 | [The Notebook Backdoor: Taking Over jupyter-mcp-server’s Live Notebook Connection](https://pluto.security/blog/notebook-backdoor-jupyter-mcp-server/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-08-12 | [PhantomBoard: A Fake Trello Extension for VS Code That Quietly Installs XWorm](https://pluto.security/blog/phantomboard-three-vs-code-extensions-one-never-rotated-ip-and-a-live-xworm-loader/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-10-30 | [Top MCP Security Risks Enterprises Need to Address](https://pluto.security/blog/top-mcp-security-risks/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-09-07 | [Enterprise AI Guardrails: How to Build Policy Enforcement That Actually Works](https://pluto.security/blog/enterprise-ai-guardrails/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-08-24 | [The MCP Debrief – What’s Actually Running on Your Endpoints](https://pluto.security/blog/the-mcp-debrief/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-08-24 | [AI Agent Authorization at the Endpoint: Why Least Privilege Breaks Down for Non-Human Identities](https://pluto.security/blog/ai-agent-authorization/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-08-17 | [Endpoint Visibility in the Agentic Era: What Your EDR Isn’t Logging](https://pluto.security/blog/endpoint-visibility-agentic-era/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-08-12 | [Nebula Deck: A Malicious VS Code Extension Built to Survive a Windows Reinstall](https://pluto.security/blog/below-deck-a-malicious-vs-code-extension-built-to-survive-a-windows-reinstall/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-07-29 | [Vicious Circle: Owning CircleCI’s MCP Server With a Filename and a DNS Record](https://pluto.security/blog/vicious-circle-owning-circlecis-mcp-server-with-a-filename-and-a-dns-record/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-07-27 | [Securing Claude Tag: A Practical Hardening Guide](https://pluto.security/blog/securing-claude-tag-a-practical-hardening-guide/) | Reconciled: [anthropic-reconciliation-2026-11](pluto-anthropic-reconciliation-2026-11.md) |
| 2026-07-22 | [The Importer Syndrome × Count Dooku 2.0 – When Your New AI IDE Imports More Than Extensions](https://pluto.security/blog/the-importer-syndrome-x-count-dooku-2-0/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-07-21 | [Two New Gartner® Reports Point to Stronger Endpoint Controls in the AI Era, with Pluto Named as a Sample Vendor.](https://pluto.security/blog/gartner-report-for-ai-endpoint-security/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-07-20 | [MCP Security in AI Integration Protocols, Package Ecosystems, and External Tool Connections](https://pluto.security/blog/mcp-security-ai-integration/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-07-16 | [Inside Claude Tag: How Anthropic’s Slack-Native Agent Actually Works](https://pluto.security/blog/inside-claude-tag-how-anthropics-slack-native-agent-actually-works/) | Reconciled: [anthropic-reconciliation-2026-11](pluto-anthropic-reconciliation-2026-11.md) |
| 2026-07-15 | [Total Recall: How Two CVEs Let Any Website Read, Rewrite, and Wipe Your AI’s Memory](https://pluto.security/blog/total-recall-how-two-cves-let-any-website-read-rewrite-and-wipe-your-ais-memory/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-07-06 | [VS Code Security Risk from Malicious Extensions and Remote Code Execution](https://pluto.security/blog/vs-code-security-risk/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-06-22 | [Is Vibe Coding Safe? What You Need to Know About Vibe Coding Security](https://pluto.security/blog/vibe-coding-safe/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-06-17 | [Introducing Plutonium](https://pluto.security/blog/introducing-plutonium/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-06-15 | [Comparing AI Agents to Cybersecurity Professionals: What the ARTEMIS Study Gets Right](https://pluto.security/blog/ai-agents-cybersecurity/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-06-08 | [AI Supply Chain Risk: What Developer Data Reveals About the Real Threats](https://pluto.security/blog/ai-supply-chain-risk/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-06-01 | [Claude Enterprise Meets the AI Security Platform: Pluto Integrates with Anthropic’s Compliance API](https://pluto.security/blog/claude-enterprise-meets-ai-security-platform/) | Reconciled: [anthropic-reconciliation-2026-11](pluto-anthropic-reconciliation-2026-11.md) |
| 2026-06-01 | [Cursor Security Issues in AI Coding Tools and Execution Flows](https://pluto.security/blog/cursor-security-ai-coding/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-05-26 | [Introducing CopilotSec: A Community Knowledge Hub for Security of The Microsoft AI Ecosystem](https://pluto.security/blog/introducing-copilotsec-a-community-knowledge-hub-for-security-of-the-microsoft-ai-ecosystem/) | Reconciled: [copilot-reconciliation-2026-11-12](pluto-copilot-reconciliation-2026-11-12.md) |
| 2026-05-26 | [Securing Copilot Studio: A Practical Hardening Guide](https://pluto.security/blog/securing-copilot-studio-a-practical-hardening-guide/) | Reconciled: [copilot-reconciliation-2026-11-12](pluto-copilot-reconciliation-2026-11-12.md) |
| 2026-05-26 | [Inside Copilot Studio: How Microsoft’s Citizen-Developer Agent Platform Actually Works](https://pluto.security/blog/inside-copilot-studio-how-microsofts-citizen-developer-agent-platform-actually-works/) | Reconciled: [copilot-reconciliation-2026-11-12](pluto-copilot-reconciliation-2026-11-12.md) |
| 2026-05-25 | [Inside Claude Office Add-ins – What Gets Sent, What Gets Bypassed, What Goes Unrecorded](https://pluto.security/blog/inside-claude-office-addins/) | Reconciled: [anthropic-reconciliation-2026-11](pluto-anthropic-reconciliation-2026-11.md) |
| 2026-05-25 | [Chrome Extension Security: How Malicious AI Extensions Are Stealing Sensitive Data](https://pluto.security/blog/chrome-extension-security/) | Reconciled: [browser/n8n control disposition](pluto-browser-n8n-reconciliation-2026-11-12.md) |
| 2026-05-18 | [Agentic AI Security: Why It Matters & Key Risks](https://pluto.security/blog/agentic-ai-security/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-04-29 | [Skills, Connectors, Plugins, Oh My: A Security Practitioner’s Map of the Claude Extension Ecosystem](https://pluto.security/blog/claude-extension-ecosystem-security-practitioner-guide/) | Reconciled: [anthropic-reconciliation-2026-11](pluto-anthropic-reconciliation-2026-11.md) |
| 2026-04-27 | [Introducing ClaudeSec: A Community Knowledge Hub for Claude Ecosystem Security](https://pluto.security/blog/introducing-claudesec/) | Reconciled: [anthropic-reconciliation-2026-11](pluto-anthropic-reconciliation-2026-11.md) |
| 2026-04-27 | [Inside Claude Managed Agents: Reverse-Engineering the Security Boundaries of Anthropic’s Hosted Agent Runtime](https://pluto.security/blog/inside-claude-managed-agents/) | Reconciled: [anthropic-reconciliation-2026-11](pluto-anthropic-reconciliation-2026-11.md) |
| 2026-04-20 | [Software Supply Chain Attack: How the AI Agent Ecosystem Became a New Battleground](https://pluto.security/blog/ai-agent-supply-chain-attacks/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-04-17 | [Securing Claude Managed Agents: What You Need to Know Before Going to Production](https://pluto.security/blog/securing-claude-managed-agents/) | Reconciled: [anthropic-reconciliation-2026-11](pluto-anthropic-reconciliation-2026-11.md) |
| 2026-04-16 | [Securing Claude Cowork: What Security Teams Actually Need to Know](https://pluto.security/blog/claude-cowork-security/) | Reconciled: [anthropic-reconciliation-2026-11](pluto-anthropic-reconciliation-2026-11.md) |
| 2026-04-15 | [MCPwn: A CVSS 9.8 One-Line MCP Bug That Hands Over Your Nginx to Anyone on the Network – Actively Exploited in the Wild](https://pluto.security/blog/mcp-bug-nginx-security-vulnerability-cvss-9-8/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-04-06 | [Browser Extension Security](https://pluto.security/blog/browser-extension-security/) | Reconciled: [browser/n8n control disposition](pluto-browser-n8n-reconciliation-2026-11-12.md) |
| 2026-04-01 | [Inside Claude Cowork: How Anthropic’s Autonomous Agent Actually Works](https://pluto.security/blog/inside-claude-cowork-how-anthropics-autonomous-agent-actually-works/) | Reconciled: [anthropic-reconciliation-2026-11](pluto-anthropic-reconciliation-2026-11.md) |
| 2026-03-31 | [Another Day, Another Supply Chain Compromise: Here’s What We Know About the Axios Incident](https://pluto.security/blog/another-day-another-supply-chain/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-03-17 | [Chrome Extension Supply Chain Attacks: How Ownership Transfers Enable Silent Permission Creep](https://pluto.security/blog/chrome-extension-supply-chain-attacks-permission-creep/) | Reconciled: [browser/n8n control disposition](pluto-browser-n8n-reconciliation-2026-11-12.md) |
| 2026-02-09 | [n8n Security Issues: Risks of Automating Internal Workflows Without Visibility](https://pluto.security/blog/n8n-security-issues/) | Reconciled: [browser/n8n control disposition](pluto-browser-n8n-reconciliation-2026-11-12.md) |
| 2026-01-24 | [Claude Code Security: Why AI-Generated Code Breaks Traditional Security Models](https://pluto.security/blog/claude-code-security-ai-generated-code/) | Reconciled: [anthropic-reconciliation-2026-11](pluto-anthropic-reconciliation-2026-11.md) |
| 2026-09-03 | [Your CI Pipeline Is a Credential Vending Machine: 7 Lessons from the TeamPCP supply-chain attacks](https://pluto.security/blog/teampcp-cicd-supply-chain-lessons/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-09-08 | [Introducing MCP Inspector: Know an MCP Server’s Risks Before You Install It](https://pluto.security/blog/mcp-inspector/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-09-15 | [Malicious Servers, Clean Scans: The Dangerous Illusion of a Clean MCP Scan](https://pluto.security/blog/malicious-mcp-servers-clean-scans/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-09-16 | [MCP Through an Attacker’s Eyes: The New Path Into Enterprise Environments](https://pluto.security/blog/mcp-servers-exploited-enterprise-risk/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-08-31 | [The Manipulated Agent: When Apify’s MCP Turns Against You](https://pluto.security/blog/apify-mcp-prompt-injection/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-09-22 | [Inside Claude Code Function Hooks: The Trust Problem Behind Claude Mods](https://pluto.security/blog/claude-code-function-hooks-security/) | Reconciled: [anthropic-reconciliation-2026-11](pluto-anthropic-reconciliation-2026-11.md) |
| 2026-09-17 | [A Security Leader’s Guide to Latio’s 2026 AI Security Market Report](https://pluto.security/blog/latio-2026-ai-security-market-report/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-09-24 | [Wide Open: Hundreds of MCPs Exposing Root Shells, Production Data, and Citizen Records One Call Away](https://pluto.security/blog/wide-open-hundreds-of-mcps-exposing-root-shells-production-data-and-citizen-records-one-call-away/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-10-01 | [SleepyDuck Wakes Again: A Cross-Platform Open VSX Campaign Targeting Solidity Developer Workstations](https://pluto.security/blog/sleepyduck-malware-open-vsx-extensions/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-10-13 | [Welcome to Planet Pluto!](https://pluto.security/blog/welcome-to-planet-pluto/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-10-20 | [Inside Personal AI Assistants: What to Check in Grok Bot, ChatGPT dots, and Meta Muse](https://pluto.security/blog/personal-ai-assistant-security/) | Reconciled: [openai-reconciliation](pluto-openai-reconciliation.md), [grok-bot-reconciliation](pluto-grok-bot-reconciliation.md) |
| 2026-10-26 | [ChatGPT Dots Security: A Practical Hardening Guide](https://pluto.security/blog/chatgpt-dots-security-practical-guide/) | Reconciled: [openai-reconciliation](pluto-openai-reconciliation.md) |
| 2026-10-29 | [How Prompt Injection Attacks Work and Why AI Agents Make Them Dangerous](https://pluto.security/blog/prompt-injection-attacks/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-10-29 | [Load/Mine: A Hugging Face Malware Campaign Returns After Takedown](https://pluto.security/blog/hugging-face-malware-campaign-load-mine/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-11-11 | [NIST AI RMF: What It Actually Means for Enterprise Security Teams](https://pluto.security/blog/nist-ai-rmf/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-11-04 | [Zero Trust for AI Agents: Why Perimeter Controls Were Not Built for This](https://pluto.security/blog/zero-trust-ai-agents/) | Reconciled: [crosscut-20261112](pluto-crosscut-20261112.md) |
| 2026-11-09 | [Securing Grok Bot: A Hardening Guide to X’s Personal AI Assistant](https://pluto.security/blog/securing-grok-bot/) | Reconciled: [grok-bot-reconciliation](pluto-grok-bot-reconciliation.md) |
| 2026-08-06 | [Inside Claude Artifacts – How Your Agent Publishes to the Web](https://pluto.security/blog/inside-claude-artifacts-how-your-agent-publishes-to-the-web/) | Reconciled: [anthropic-reconciliation-2026-11](pluto-anthropic-reconciliation-2026-11.md) |

## Other public content

All glossary and FAQ entries were fetched and their titles/headings inventoried in the cache. They are explanatory/background advice rather than product-specific implementation guides. Page sitemap contains corporate/about/legal/contact/demo/careers/webinar and MCP product page, not an additional product-hardening guide. Author indexes are discovery surfaces, not unique controls.

## Standalone research surfaces

- https://teampcp.pluto.security/ and https://teampcp.pluto.security/the-full-story/: incident chronology and practical supply-chain mitigation matrix; crosscut reviewer owns verification.
- https://plutonium.pluto.security/guides/: all9 links reconciled above. Catalog/Market Space ratings are mutable assessments, not authoritative configuration APIs. No hardening tool is published: page labels it coming soon.
