#!/bin/bash
# ==============================================================================
# Field Notes - Secret & Security Verification Hook
# ==============================================================================
# Scans staged git files for accidental leak of secret keys, passwords,
# .env credentials, and platform signing keys before committing to GitHub.
# ==============================================================================

set -e

FORBIDDEN_FILES=(
  ".env"
  ".env.production"
  ".env.staging"
  "key.properties"
  "local.properties"
  "google-services.json"
  "GoogleService-Info.plist"
)

EXIT_CODE=0

echo "🔍 Scanning staged files for sensitive data..."

# Check forbidden file names
for file in "${FORBIDDEN_FILES[@]}"; do
  if git diff --cached --name-only | grep -E "(^|/)${file}$" > /dev/null 2>&1; then
    echo "❌ SECURITY ALERT: '$file' is staged for commit!"
    echo "   Never commit secret environment or configuration files to public repositories."
    EXIT_CODE=1
  fi
done

# Check forbidden extensions
if git diff --cached --name-only | grep -E "\.(jks|keystore|p12|pfx|key|pem|p8)$" > /dev/null 2>&1; then
  echo "❌ SECURITY ALERT: Keystore or private key file is staged for commit!"
  EXIT_CODE=1
fi

if [ $EXIT_CODE -ne 0 ]; then
  echo ""
  echo "🚫 Commit rejected due to security risk. Please unstage sensitive files using:"
  echo "   git reset HEAD <file>"
  exit 1
fi

echo "✅ No sensitive files detected in staged changes."
exit 0
