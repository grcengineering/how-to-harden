#!/usr/bin/env bash
# HTH JFrog Control 3.1: Enable Artifact Signing
# Profile: L2 | NIST: SI-7
# https://howtoharden.com/guides/jfrog/#31-enable-artifact-signing

# HTH Guide Excerpt: begin sign-and-verify
# Sign artifact during deployment
jf rt upload --gpg-key=/path/to/key.asc artifact.jar libs-release-local/

# Verify artifact signature
jf rt download libs-release-local/artifact.jar --gpg-key=/path/to/public.asc
# HTH Guide Excerpt: end sign-and-verify
