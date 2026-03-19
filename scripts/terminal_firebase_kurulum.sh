#!/usr/bin/env bash
# Tek seferlik terminal kurulumları (bu makinede çalıştırıldıysa tekrar gerekmez).
# Yeni makine: brew install openjdk@17 firebase-cli; dart pub global activate flutterfire_cli
# PATH: export PATH="/opt/homebrew/bin:$PATH:$HOME/.pub-cache/bin"
#
# FlutterFire:
#   flutterfire configure -p emlak-master -y --platforms android,ios,macos,web \
#     --android-package-name com.example.emlakmaster_mobile \
#     --ios-bundle-id com.example.emlakmasterMobile \
#     --macos-bundle-id com.example.emlakmasterMobile --overwrite-firebase-options
#
# Debug SHA-1 (Firebase):
#   firebase apps:android:sha:create "1:572835725773:android:27252e78a15a8fda92c484" \
#     "85:1A:07:87:06:92:CD:72:DF:05:90:7F:44:86:6C:8E:22:BB:9B:FE" --project emlak-master
#
# Gradle (JAVA_HOME):
#   source scripts/env_homebrew_java.sh && cd android && ./gradlew :app:signingReport

set -euo pipefail
echo "Bu dosya yalnızca dokümantasyon; komutları kopyalayıp çalıştırın."
