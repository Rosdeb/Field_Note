# Public Environment & Security Setup Guide

This document explains how the **Field Notes** project manages environment variables, secrets, and repository security for public hosting on GitHub ([https://github.com/Rosdeb/Field_Note.git](https://github.com/Rosdeb/Field_Note.git)).

---

## 1. Quick Environment Setup

When cloning this repository fresh, your local environment does not yet contain a `.env` file (since `.env` is gitignored to protect sensitive data).

### Option A: Using the Automated Setup Script (Recommended)
On macOS/Linux:
```bash
./scripts/setup_env.sh
```

On Windows (Command Prompt / PowerShell):
```cmd
scripts\setup_env.bat
```

### Option B: Manual Setup
Copy the public template:
```bash
cp .env.example .env
```

---

## 2. Configuring the Backend URL (`BASE_URL`)

Open your local `.env` file and set `BASE_URL` according to your runtime environment:

| Target Platform | Recommended `BASE_URL` | Reason / Details |
| :--- | :--- | :--- |
| **iOS Simulator / macOS** | `http://127.0.0.1:8080` | Shares localhost directly with the host machine. |
| **Android Emulator** | `http://10.0.2.2:8080` | Android emulators use `10.0.2.2` to access host loopback. |
| **Web Browser** | `http://localhost:8080` | Direct browser localhost loopback. |
| **Physical Phone / Tablet** | `http://192.168.1.X:8080` | Use your local development computer's LAN IP. |
| **Remote Staging / Production** | `https://api.yourdomain.com` | Live SSL-secured backend endpoint. |

---

## 3. Security Architecture for Public Repositories

### A. Git Ignored Sensitive Files
The root [.gitignore](file:///Users/rosdebkoch/All_Project/Field%20Notes/.gitignore) strictly prevents accidental commits of:
- **Environment variables**: `.env`, `.env.local`, `.env.production` (only `.env.example` is committed).
- **Android Signing & Local SDK**: `key.properties`, `local.properties`, `*.keystore`, `*.jks`.
- **Apple & Signing Keys**: `*.key`, `*.pem`, `*.cer`, `*.p12`, `*.p8`, `xcuserdata`.
- **Third-Party Service Credentials**: `google-services.json`, `GoogleService-Info.plist`, `sentry.properties`.

### B. Pre-commit Secret Verification
You can verify staged changes at any time before running `git commit`:
```bash
./scripts/check_secrets.sh
```

To install this as an automatic git pre-commit hook:
```bash
cp ./scripts/check_secrets.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### C. Automated GitHub Actions Scanning
Every push and pull request submitted to GitHub triggers:
- **Gitleaks Secret Scan** (`.github/workflows/secret-scan.yml`): Inspects commits for credentials, private keys, or API tokens.
- **CI Test & Analysis** (`.github/workflows/ci.yml`): Validates code formatting, static analysis, and dependencies.
- **Dependabot** (`.github/dependabot.yml`): Automatically monitors package dependencies for security advisories.

---

## 4. Production CI/CD Builds & Secret Injection

For continuous integration and production release builds, **never** store release signing keys or private production URLs in source code:
1. Store secrets in **GitHub Repository Secrets** (`Settings` > `Secrets and variables` > `Actions`).
2. Inject configuration at build time using Flutter `--dart-define` or GitHub Actions environment steps:
   ```bash
   flutter build apk --release --dart-define=BASE_URL=${{ secrets.PROD_API_URL }}
   ```
