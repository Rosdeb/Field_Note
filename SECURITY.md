# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

The Field Notes team takes security vulnerabilities seriously. If you discover a security issue or credential leak, please report it privately.

**Please do NOT disclose security vulnerabilities publicly through GitHub Issues or Discussions.**

### How to Report
- Submit a report privately via GitHub's **Private Vulnerability Reporting** feature on the [Field_Note repository](https://github.com/Rosdeb/Field_Note/security/advisories/new).
- Alternatively, email the maintainer directly.
- Include detailed steps to reproduce the vulnerability, including any proofs of concept, environment details, or affected components.

### What to Expect
- A confirmation of receipt within 48 hours.
- Regular status updates on the remediation process.
- Coordination on public disclosure once a patch or advisory is released.

## Security Best Practices for Contributors

1. **Never Commit Secrets**: Do not check in `.env`, private keys (`.pem`, `.key`, `.p12`), keystores (`.jks`), or `google-services.json` / `GoogleService-Info.plist`.
2. **Environment Isolation**: Always base local settings on `.env.example` and keep your personal configuration in `.env` (which is gitignored).
3. **Automated Secret Scanning**: Pre-commit hooks and Gitleaks CI workflows run on all pull requests to block secret leakage before it can be merged.
