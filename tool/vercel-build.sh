#!/usr/bin/env bash
set -euo pipefail

# 1. Install Flutter if not pre-installed in the Vercel Linux container
if ! command -v flutter &> /dev/null; then
  echo "Flutter not found in PATH. Checking /tmp/flutter..."
  if [ ! -d "/tmp/flutter" ]; then
    echo "Installing Flutter stable SDK..."
    FLUTTER_BRANCH="stable"
    git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_BRANCH" /tmp/flutter
  fi
  export PATH="/tmp/flutter/bin:$PATH"
fi

echo "Flutter version:"
flutter --version

# 2. Generate client-only .env.client (never embed service-role / payment secrets)
echo "Generating .env.client from public environment variables..."
cat << EOF > .env.client
NEXT_PUBLIC_APP_NAME="${NEXT_PUBLIC_APP_NAME:-MahaTicket}"
NEXT_PUBLIC_DEFAULT_CITY="${NEXT_PUBLIC_DEFAULT_CITY:-Pune}"
APP_URL="${APP_URL:-${NEXT_PUBLIC_API_BASE:-https://mahaticket.kalpkrutinfotech.com}}"
NEXT_PUBLIC_API_BASE="${NEXT_PUBLIC_API_BASE:-${APP_URL:-https://mahaticket.kalpkrutinfotech.com}}"
NEXT_PUBLIC_SUPABASE_URL="${NEXT_PUBLIC_SUPABASE_URL:-${SUPABASE_URL:-https://hnseawulngdxbvltmthe.supabase.co}}"
NEXT_PUBLIC_SUPABASE_ANON_KEY="${NEXT_PUBLIC_SUPABASE_ANON_KEY:-${SUPABASE_ANON_KEY:-}}"
RAZORPAY_KEY_ID="${RAZORPAY_KEY_ID:-${NEXT_PUBLIC_RAZORPAY_KEY_ID:-}}"
NEXT_PUBLIC_RAZORPAY_KEY_ID="${NEXT_PUBLIC_RAZORPAY_KEY_ID:-${RAZORPAY_KEY_ID:-}}"
EOF

echo "Resolving Flutter dependencies..."
flutter pub get

echo "Running Flutter static analysis..."
flutter analyze lib/

echo "Building Flutter Web release..."
flutter build web --release --base-href /

if [ -f "build/web/index.html" ]; then
  echo "Flutter Web build successful in build/web!"
else
  echo "Error: build/web/index.html was not generated"
  exit 1
fi