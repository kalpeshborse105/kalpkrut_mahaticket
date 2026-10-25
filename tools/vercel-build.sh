#!/usr/bin/env bash
set -euo pipefail

echo "Checking Flutter SDK..."
flutter --version

echo "Resolving packages..."
flutter pub get

echo "Analyzing Dart code..."
flutter analyze

echo "Building Flutter Web..."
flutter build web --release --base-href /

test -f build/web/index.html
echo "Flutter Web build completed: build/web"