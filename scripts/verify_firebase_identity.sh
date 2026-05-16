#!/usr/bin/env bash
# Repo-only checks: bundle IDs / plist / Dart Firebase options vs production iOS.
# Does not call Firebase APIs. API key rotation and OAuth client edits are manual in Console.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
ERR=0

echo "== pubspec =="
grep '^version:' pubspec.yaml || true

echo "== lib/firebase_options.dart (iOS/macOS bundle must be production) =="
if grep -E "iosBundleId: 'com\.example" lib/firebase_options.dart 2>/dev/null; then
  echo "FAIL: com.example.* still present as iosBundleId in firebase_options.dart"
  ERR=1
fi

echo "== iOS Runner GoogleService-Info.plist BUNDLE_ID =="
if ! grep -A1 '<key>BUNDLE_ID</key>' ios/Runner/GoogleService-Info.plist | grep -q 'com.uguraytekin.emlakmastermobile'; then
  echo "FAIL: ios/Runner/GoogleService-Info.plist BUNDLE_ID"
  ERR=1
fi

echo "== macOS Runner GoogleService-Info.plist BUNDLE_ID =="
if ! grep -A1 '<key>BUNDLE_ID</key>' macos/Runner/GoogleService-Info.plist | grep -q 'com.uguraytekin.emlakmastermobile'; then
  echo "FAIL: macos/Runner/GoogleService-Info.plist BUNDLE_ID"
  ERR=1
fi

echo "== android/app/google-services.json (iOS OAuth client mirror; must not use example bundle) =="
if grep -q '"bundle_id": "com.example.emlakmasterMobile"' android/app/google-services.json; then
  echo 'FAIL: google-services.json still has bundle_id com.example.emlakmasterMobile (iOS OAuth metadata)'
  ERR=1
fi

echo "== iOS Xcode Runner PRODUCT_BUNDLE_IDENTIFIER (Release) =="
if ! grep -q 'PRODUCT_BUNDLE_IDENTIFIER = com.uguraytekin.emlakmastermobile;' ios/Runner.xcodeproj/project.pbxproj; then
  echo "FAIL: expected com.uguraytekin.emlakmastermobile in ios/Runner.xcodeproj/project.pbxproj"
  ERR=1
fi

echo "== macOS AppInfo bundle =="
if ! grep -q 'PRODUCT_BUNDLE_IDENTIFIER = com.uguraytekin.emlakmastermobile' macos/Runner/Configs/AppInfo.xcconfig; then
  echo "FAIL: macos/Runner/Configs/AppInfo.xcconfig bundle id"
  ERR=1
fi

if [[ "$ERR" -eq 0 ]]; then
  echo ""
  echo "OK: repo Firebase / bundle identity checks passed."
  echo "Manual (Console): Google Cloud iOS OAuth bundle, Firebase iOS app bundle, API key restrictions if repo is shared."
else
  echo ""
  echo "One or more checks failed (see above)."
  exit 1
fi
