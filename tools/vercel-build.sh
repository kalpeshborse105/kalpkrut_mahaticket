#!/usr/bin/env bash
set -euo pipefail

# 1. Install Flutter if not pre-installed in the Vercel Linux container
if ! command -v flutter &> /dev/null; then
  echo "Flutter not found. Installing Flutter stable SDK..."
  FLUTTER_BRANCH="stable"
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_BRANCH" /tmp/flutter
  export PATH="/tmp/flutter/bin:$PATH"
fi

echo "Flutter version:"
flutter --version

echo "Resolving Flutter dependencies..."
flutter pub get

echo "Building Flutter Web release..."
flutter build web --release --base-href /

if [ -f "build/web/index.html" ]; then
  echo "Flutter Web build successful in build/web!"
else
  echo "Error: build/web/index.html was not generated"
  exit 1
fi