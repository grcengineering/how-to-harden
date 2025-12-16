# Contributing to How to Harden

Thank you for your interest in contributing to How to Harden! This document provides guidelines for contributing new guides, improvements, and fixes.

## Quick Links

- [Project README](README.md)
- [Guide Template](templates/vendor-guide-template.md)
- [Report Issues](https://github.com/grcengineering/how-to-harden/issues)

## Ways to Contribute

### 1. Report Issues or Bugs
- **Outdated information:** Open an issue with tag `content-outdated`
- **Broken links:** Open an issue with tag `broken-link`
- **Formatting issues:** Open an issue with tag `formatting`
- **Security concerns:** See [Security Reporting](#security-reporting)

### 2. Improve Existing Guides
- Fix typos, clarify instructions, update screenshots
- Add missing controls or detection queries
- Update compliance mappings
- Verify and update vendor IP addresses for integrations

### 3. Create New Guides
- Use the [vendor guide template](templates/vendor-guide-template.md)
- Follow the structure and quality checklist
- Test all commands and configurations
- Submit a pull request

## Markdown Formatting Requirements

⚠️ **CRITICAL:** Our website uses Jekyll with kramdown for Markdown rendering. Certain formatting rules MUST be followed or content will not render correctly.

### Tables

**Tables MUST have blank lines before and after them.**

✅ **Correct:**
```markdown
**Step 1: Configure Settings**

| Setting | Value |
|---------|-------|
| Option  | Value |

**Step 2: Next Action**
```

❌ **Incorrect (will break on website):**
```markdown
**Step 1: Configure Settings**
| Setting | Value |
|---------|-------|
| Option  | Value |
**Step 2: Next Action**
```

### Other Formatting Guidelines

- **Code blocks:** Always specify the language for syntax highlighting
  ```bash
  # Correct
  echo "Hello"
  ```

- **Headings:** Use consistent levels (don't skip from `##` to `####`)

- **Emphasis:** Use `**bold**` for emphasis, not `__bold__`

- **Lists:** Use consistent list markers (all `-` or all `*`, not mixed)

## Creating a New Guide

### 1. Choose a Platform

Priority platforms that need guides:
- Microsoft 365
- Google Workspace
- Slack
- AWS (integration security focus)
- Azure (integration security focus)

### 2. Use the Template

```bash
cp templates/vendor-guide-template.md docs/_guides/[vendor-name].md
```

### 3. Fill Out All Sections

See the [template usage notes](templates/vendor-guide-template.md#template-usage-notes) for detailed guidance.

### 4. Test Everything

- [ ] Test all ClickOps steps in a real environment
- [ ] Verify all CLI/API commands work
- [ ] Validate compliance mappings against official framework documents
- [ ] Check all external links
- [ ] Verify table formatting (blank lines before/after)

### 5. Submit a Pull Request

- Create a descriptive PR title: `Add [Vendor] hardening guide` or `Update [Vendor] guide: [what changed]`
- Reference any related issues
- Add yourself to the guide's changelog

## Pull Request Process

1. **Fork the repository** and create a branch from `main`
2. **Make your changes** following the guidelines above
3. **Test locally** if possible (see [Local Development](#local-development))
4. **Submit a PR** with a clear description of changes
5. **Respond to review feedback** from maintainers
6. **Celebrate!** Your contribution helps the security community

## Local Development

To test the Jekyll site locally:

```bash
# Install dependencies
cd docs
bundle install

# Run local server
bundle exec jekyll serve

# View at http://localhost:4000
```

This allows you to verify that your Markdown renders correctly before submitting a PR.

## Style Guide

### Writing Style

- **Clear and concise:** Security professionals are busy
- **Action-oriented:** Use imperative mood ("Configure X" not "You should configure X")
- **Specific:** Include exact paths, button names, and settings
- **Vendor-neutral:** Focus on security benefits, not vendor marketing

### Code Examples

- **Inline comments:** Explain what each command does
- **Working examples:** Test before submitting
- **Multiple options:** Provide ClickOps, CLI, API, and IaC where applicable
- **Error handling:** Include validation steps

### Security Focus

- **Attack-informed:** Explain what attacks the control prevents
- **Risk-based:** Prioritize by impact and likelihood
- **Real-world examples:** Reference actual incidents when relevant
- **Operational impact:** Document user experience and maintenance burden

## Compliance Mappings

When adding compliance mappings:

1. **Verify against official sources:**
   - [NIST 800-53](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
   - [CIS Controls](https://www.cisecurity.org/controls)
   - [ISO 27001](https://www.iso.org/isoiec-27001-information-security.html)

2. **Be specific:** Map to exact control IDs, not just categories

3. **Explain the relationship:** Why does this technical control satisfy the compliance requirement?

## Security Reporting

If you discover a security vulnerability in our automation scripts or recommendations that could actively harm users:

- **DO NOT** open a public GitHub issue
- **Email:** security@howtoharden.com
- **Include:** Detailed description, impact, and suggested fix

For general content corrections or improvements, use GitHub Issues.

## Recognition

All contributors are recognized in:
- Individual guide changelogs
- The project [CONTRIBUTORS.md](CONTRIBUTORS.md) file
- Annual project reports

## Questions?

- **GitHub Discussions:** General questions and ideas
- **GitHub Issues:** Bug reports and feature requests
- **Email:** contribute@howtoharden.com

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for helping make the security community stronger!** 🎯
