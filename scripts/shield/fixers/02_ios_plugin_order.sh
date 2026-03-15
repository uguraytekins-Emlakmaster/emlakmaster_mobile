#!/usr/bin/env bash
# iOS: GeneratedPluginRegistrant.m içinde Firebase Core'u ilk sıraya alır.
set -e
# shellcheck source=../config.sh
source "$(dirname "$0")/../config.sh"
REGISTRANT="$PROJECT_ROOT/ios/Runner/GeneratedPluginRegistrant.m"
[[ ! -f "$REGISTRANT" ]] && exit 0
"$PROJECT_ROOT/scripts/fix_ios_plugin_order.sh" "$REGISTRANT" || true
exit 0
