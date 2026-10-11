#!/bin/bash
# ==============================================================================
# Field Notes - Local Environment Setup Script
# ==============================================================================
# This script initializes the local environment file (.env) from .env.example
# if it does not already exist. It ensures developers can run the app immediately
# without committing sensitive configurations to Git.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔧 Setting up Field Notes environment..."

if [ -f "$ROOT_DIR/.env" ]; then
  echo "✅ '.env' already exists at $ROOT_DIR/.env."
  echo "   (Skipping overwrite. Modify your existing '.env' file if needed.)"
else
  if [ -f "$ROOT_DIR/.env.example" ]; then
    cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
    echo "✅ Successfully created '.env' from '.env.example'!"
    echo "   Default API BASE_URL set to: http://127.0.0.1:8080"
    echo "   To use an Android Emulator, change BASE_URL to: http://10.0.2.2:8080"
  else
    echo "❌ Error: '.env.example' template not found in $ROOT_DIR!"
    exit 1
  fi
fi

echo "🚀 Environment ready. You can now run:"
echo "   flutter pub get"
echo "   flutter run"
