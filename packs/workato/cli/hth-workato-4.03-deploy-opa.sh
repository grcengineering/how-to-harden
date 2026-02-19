#!/usr/bin/env bash
# HTH Workato Control 4.03: Configure On-Premises Agents (OPA)
# Profile: L2 | NIST: AC-17, SC-7
# https://howtoharden.com/guides/workato/#43-configure-on-premises-agents-opa

# HTH Guide Excerpt: begin cli-docker-deploy-opa
# Pull the Workato OPA Docker image
docker pull workato/agent:latest

# Run the agent with configuration
docker run -d \
  --name workato-opa \
  --restart unless-stopped \
  -v /opt/workato/conf:/opt/workato/conf:ro \
  -v /opt/workato/data:/opt/workato/data \
  workato/agent:latest

# Verify agent is running and connected
docker logs workato-opa | grep -i "connected"
# HTH Guide Excerpt: end cli-docker-deploy-opa
