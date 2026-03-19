#!/usr/bin/env bash
#
# GeneratedPluginRegistrant.m içinde FLTFirebaseCorePlugin'ı ilk sıraya alır.
# Firebase duplicate-app crash'ini önlemek için her build öncesi çalıştırılabilir (idempotent).
#
# Kullanım: scripts/fix_ios_plugin_order.sh [GeneratedPluginRegistrant.m yolu]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRANT_M="${1:-$PROJECT_ROOT/ios/Runner/GeneratedPluginRegistrant.m}"

if [[ ! -f "$REGISTRANT_M" ]]; then
  echo "fix_ios_plugin_order: Dosya bulunamadı: $REGISTRANT_M" >&2
  exit 1
fi

# flutter_contacts 2.x (Swift-only): @import flutter_contacts → ObjC'de "different definitions" modül hatası.
# Çözüm: flutter_contacts-Swift.h (Flutter varsayılan üretiminde yok; pub get sonrası tekrar uygulanır).
if grep -qF 'FlutterContactsPlugin.h>' "$REGISTRANT_M" && ! grep -q 'flutter_contacts-Swift.h' "$REGISTRANT_M"; then
  python3 -c "
import pathlib, sys
p = pathlib.Path(sys.argv[1])
t = p.read_text()
old = '''#if __has_include(<flutter_contacts/FlutterContactsPlugin.h>)
#import <flutter_contacts/FlutterContactsPlugin.h>
#else
@import flutter_contacts;
#endif'''
new = '''#if __has_include(<flutter_contacts/flutter_contacts-Swift.h>)
#import <flutter_contacts/flutter_contacts-Swift.h>
#elif __has_include(<flutter_contacts/FlutterContactsPlugin.h>)
#import <flutter_contacts/FlutterContactsPlugin.h>
#else
@import flutter_contacts.Swift;
#endif'''
if old in t:
    p.write_text(t.replace(old, new, 1))
    print('fix_ios_plugin_order: flutter_contacts Swift header import yaması.', file=sys.stderr)
" "$REGISTRANT_M" || true
fi

# registerWithRegistry bloğunda ilk [XXX register...] satırı FLTFirebaseCorePlugin mı?
# Not: macOS awk için \s yerine [ \t] kullanıyoruz
FIRST_REGISTER_LINE=$(awk '
  /^\+ \(void\)registerWithRegistry:/ { in_block=1; next }
  in_block && /^[ \t]+\[.*registerWithRegistrar:.*\];/ { print; exit }
  in_block && /^}$/ { exit }
' "$REGISTRANT_M")

if [[ -n "$FIRST_REGISTER_LINE" ]] && echo "$FIRST_REGISTER_LINE" | grep -q "FLTFirebaseCorePlugin"; then
  # Zaten doğru sırada
  exit 0
fi

# Bloğu yeniden oluştur: FLTFirebaseCorePlugin önce, diğerleri sırayla (Core tekrarsız)
TMP=$(mktemp)
awk '
  BEGIN { in_block=0; core_line=""; others="" }
  /^\+ \(void\)registerWithRegistry:/ {
    in_block=1
    print
    print ""
    next
  }
  in_block && /^[ \t]+\[.*registerWithRegistrar:.*\];/ {
    if ($0 ~ /FLTFirebaseCorePlugin/) { core_line=$0 }
    else { others = others (others ? "\n" : "") $0 }
    next
  }
  in_block && /^[ \t]+\/\// {
    # Yorum satırını atla (yeniden yazacağız)
    next
  }
  in_block && /^}$/ {
    if (core_line != "") print "  // Firebase Core önce (duplicate-app crash önlemi)"
    if (core_line != "") print core_line
    if (others != "") {
      n = split(others, a, "\n")
      for (i=1; i<=n; i++) print a[i]
    }
    print "}"
    in_block=0
    next
  }
  !in_block { print }
' "$REGISTRANT_M" > "$TMP"

mv "$TMP" "$REGISTRANT_M"
echo "fix_ios_plugin_order: FLTFirebaseCorePlugin ilk sıraya alındı."
