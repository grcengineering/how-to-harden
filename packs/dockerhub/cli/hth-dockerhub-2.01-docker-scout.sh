#!/usr/bin/env bash
# HTH Docker Hub Control 2.1: Enable Docker Scout
# Profile: L1 | NIST: RA-5
# https://howtoharden.com/guides/dockerhub/#21-enable-docker-scout

# HTH Guide Excerpt: begin cli-docker-scout
# Enable Scout for repository
docker scout recommendations myimage:latest

# Check for vulnerabilities
docker scout cves myimage:latest
# HTH Guide Excerpt: end cli-docker-scout
