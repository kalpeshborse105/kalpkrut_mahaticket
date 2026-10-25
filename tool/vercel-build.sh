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

# 2. Generate .env file dynamically from Vercel Environment Variables
echo "Generating .env from environment variables..."
cat << EOF > .env
NEXT_PUBLIC_APP_NAME="${NEXT_PUBLIC_APP_NAME:-MahaTicket}"
NEXT_PUBLIC_DEFAULT_CITY="${NEXT_PUBLIC_DEFAULT_CITY:-Pune}"
NEXT_PUBLIC_SUPABASE_URL="${NEXT_PUBLIC_SUPABASE_URL:-${SUPABASE_URL:-https://hnseawulngdxbvltmthe.supabase.co}}"
NEXT_PUBLIC_SUPABASE_ANON_KEY="${NEXT_PUBLIC_SUPABASE_ANON_KEY:-${SUPABASE_ANON_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhuc2Vhd3VsbmdkeGJ2bHRtdGhlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3MDc5NjIsImV4cCI6MjEwNjI4Mzk2Mn0.Jk1k0ZPMpldURgv37Hq1OfTjSY45GBcZ21qT_74SK9o}}"
RAZORPAY_KEY_ID="${RAZORPAY_KEY_ID:-${NEXT_PUBLIC_RAZORPAY_KEY_ID:-rzp_test_Tqadzif5eTC5UB}}"
NEXT_PUBLIC_RAZORPAY_KEY_ID="${NEXT_PUBLIC_RAZORPAY_KEY_ID:-${RAZORPAY_KEY_ID:-rzp_test_Tqadzif5eTC5UB}}"
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