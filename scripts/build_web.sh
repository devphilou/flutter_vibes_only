#!/usr/bin/env bash
set -euo pipefail

echo "==> Flutter doctor (summary)"
flutter --version

echo "==> Enabling web support (idempotent)"
flutter config --enable-web >/dev/null 2>&1 || true

echo "==> Fetching packages"
flutter pub get

# Optionally run tests (uncomment to enforce before deploy)
# echo "==> Running tests"
# flutter test

echo "==> Building release web bundle"
flutter build web --release --base-href=/

echo "Build complete. Output at build/web"
