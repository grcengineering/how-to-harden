#!/usr/bin/env bash
# HTH Cursor Control 3.2: Rotate AI Provider API Keys Quarterly
# Profile: L2 | NIST: IA-5(1)
# https://howtoharden.com/guides/cursor/#32-rotate-ai-provider-api-keys-quarterly

# HTH Guide Excerpt: begin cli-key-rotation
# Update environment variable with new key after generating on provider dashboard
# For zsh:
sed -i '' 's|^export OPENAI_API_KEY=.*|export OPENAI_API_KEY="sk-proj-NEW-KEY-HERE"|' ~/.zshrc
source ~/.zshrc
echo "OpenAI API key rotated in ~/.zshrc"

# For bash:
# sed -i 's|^export OPENAI_API_KEY=.*|export OPENAI_API_KEY="sk-proj-NEW-KEY-HERE"|' ~/.bashrc
# source ~/.bashrc
# HTH Guide Excerpt: end cli-key-rotation
