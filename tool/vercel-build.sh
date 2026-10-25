#!/usr/bin/env bash
set -euo pipefail

# 1. Install Flutter if not pre-installed in the Vercel Linux container
if ! command -v flutter &> /dev/null; then
  echo "Flutter not found. Installing Flutter stable SDK..."
  FLUTTER_BRANCH="stable"
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_BRANCH" /tmp/flutter
fi

# Always ensure flutter bin is in PATH for this script session
export PATH="/tmp/flutter/bin:$PATH"

echo "Flutter version:"
flutter --version

# 2. Generate .env file dynamically from Vercel Environment Variables
echo "Generating .env from Vercel environment variables..."
cat << EOF > .env
SUPABASE_URL=${SUPABASE_URL:-}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-}
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID:-}
EOF

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