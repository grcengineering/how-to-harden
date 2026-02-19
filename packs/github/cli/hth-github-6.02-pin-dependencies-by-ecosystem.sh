#!/usr/bin/env bash
# HTH GitHub Control 6.02: Pin Dependencies by Ecosystem
# Profile: L2 | SLSA: Build L3
# https://howtoharden.com/guides/github/#62-pin-dependencies-to-specific-versions-hash-verification

# HTH Guide Excerpt: begin cli-pin-npm
# Commit package-lock.json (contains hashes)
git add package-lock.json

# Verify integrity on install
npm ci --audit
# HTH Guide Excerpt: end cli-pin-npm

# HTH Guide Excerpt: begin cli-pin-python
# Generate requirements with hashes
pip-compile --generate-hashes requirements.in > requirements.txt

# Install with verification
pip install --require-hashes -r requirements.txt
# HTH Guide Excerpt: end cli-pin-python

# HTH Guide Excerpt: begin cli-pin-go
# go.sum contains hashes automatically
go mod verify
# HTH Guide Excerpt: end cli-pin-go

# HTH Guide Excerpt: begin cli-pin-docker
# Bad: tag can change
# FROM node:18

# Good: digest is immutable
# FROM node:18@sha256:a1b2c3d4...
# HTH Guide Excerpt: end cli-pin-docker
