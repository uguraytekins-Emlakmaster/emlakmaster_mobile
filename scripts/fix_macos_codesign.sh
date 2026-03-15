#!/bin/bash
# CodeSign "resource fork, Finder information, or similar detritus not allowed" hatası için:
# Extended attributes kaldır, clean build yap.
set -e
cd "$(dirname "$0")/.."
echo "Extended attributes temizleniyor..."
xattr -cr build 2>/dev/null || true
xattr -cr macos 2>/dev/null || true
echo "Flutter clean..."
flutter clean
echo "macOS build başlatılıyor..."
flutter run -d macos
