#!/bin/bash
# macOS'ta uygulamayı çalıştır – CodeSign "resource fork" hatası olmadan.
set -e
cd "$(dirname "$0")/.."
echo ">>> Extended attributes temizleniyor (CodeSign hatası önlemi)..."
xattr -cr build 2>/dev/null || true
xattr -cr macos 2>/dev/null || true
echo ">>> macOS build başlatılıyor..."
flutter run -d macos
